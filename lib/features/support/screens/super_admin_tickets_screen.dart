import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/form_label.dart';
import '../models/support_ticket.dart';
import '../providers/support_provider.dart';

class SuperAdminTicketsScreen extends ConsumerStatefulWidget {
  const SuperAdminTicketsScreen({super.key});

  @override
  ConsumerState<SuperAdminTicketsScreen> createState() => _SuperAdminTicketsScreenState();
}

class _SuperAdminTicketsScreenState extends ConsumerState<SuperAdminTicketsScreen> {
  String _selectedStatusFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportProvider.notifier).loadAllTicketsForSuperAdmin());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportProvider);

    // Filter tickets
    final filteredTickets = supportState.allTickets.where((t) {
      if (_selectedStatusFilter != 'all' && t.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchMandal = t.mandalName.toLowerCase().contains(query);
        final matchUser = t.userName.toLowerCase().contains(query);
        final matchMobile = (t.userMobile ?? '').contains(query);
        final matchSubject = t.subject.toLowerCase().contains(query);
        final matchCode = (t.mandalCode ?? '').toLowerCase().contains(query);
        return matchMandal || matchUser || matchMobile || matchSubject || matchCode;
      }
      return true;
    }).toList();

    final openCount = supportState.allTickets.where((t) => t.status == 'open').length;
    final inProgressCount = supportState.allTickets.where((t) => t.status == 'in_progress').length;
    final resolvedCount = supportState.allTickets.where((t) => t.status == 'resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('सुपर ॲडमिन: सर्व मंडळांचे मेसेज व तक्रारी'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'रिफ्रेश करा',
            onPressed: () => ref.read(supportProvider.notifier).loadAllTicketsForSuperAdmin(),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 800,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'मंडळाचे नाव, कोड किंवा युजर शोधा...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'सर्व (${supportState.allTickets.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('open', 'प्रलंबित ($openCount)', Colors.red),
                    const SizedBox(width: 8),
                    _buildFilterChip('in_progress', 'तपासणी सुरू ($inProgressCount)', Colors.blue),
                    const SizedBox(width: 8),
                    _buildFilterChip('resolved', 'सोडवले ($resolvedCount)', Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tickets List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(supportProvider.notifier).loadAllTicketsForSuperAdmin(),
                  child: supportState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredTickets.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 50, color: Colors.green.shade300),
                                  const SizedBox(height: 12),
                                  const Text('कोणतीही तक्रार किंवा मेसेज सापडला नाही', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredTickets.length,
                              itemBuilder: (context, index) {
                                return _buildAdminTicketCard(filteredTickets[index]);
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, [Color? activeColor]) {
    final isSelected = _selectedStatusFilter == filterKey;
    final color = activeColor ?? AppColors.primary;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => setState(() => _selectedStatusFilter = filterKey),
    );
  }

  Widget _buildAdminTicketCard(SupportTicket ticket) {
    final statusColor = _getStatusColor(ticket.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.4), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent Mandal Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.temple_hindu, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'मंडळ: ${ticket.mandalName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                        ),
                        if (ticket.mandalLocation != null || ticket.mandalCode != null)
                          Text(
                            '${ticket.mandalLocation ?? ""} • कोड: ${ticket.mandalCode ?? "उपलब्ध नाही"}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.statusMarathi,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // User Info
            Row(
              children: [
                const Icon(Icons.person_pin, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'पाठवणारा: ${ticket.userName} (${ticket.userRole ?? "सदस्य"})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                if (ticket.userMobile != null)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: ticket.userMobile!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('मोबाईल नंबर कॉपी झाला!')),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          ticket.userMobile!,
                          style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (ticket.userEmail != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text('ईमेल: ${ticket.userEmail}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ],
            const Divider(height: 16),

            // Subject & Category
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(ticket.categoryMarathi, style: const TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ticket.priority == 'urgent' ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.priorityMarathi,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ticket.priority == 'urgent' ? Colors.red : Colors.deepOrange,
                    ),
                  ),
                ),
                const Spacer(),
                Text(ticket.formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            // Subject
            Text(
              ticket.subject,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              ticket.description,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),

            // Screenshot Preview (if any)
            if (ticket.screenshotUrl != null && ticket.screenshotUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showFullImageDialog(ticket.screenshotUrl!),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ticket.screenshotUrl!,
                        height: 70,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('जोडलेला स्क्रीनशॉट 📷', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('मोठा पाहण्यासाठी स्पर्श करा', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Current Admin Reply (if already replied)
            if (ticket.adminReply != null && ticket.adminReply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.reply, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        const Text('दिलेले उत्तर:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                        const Spacer(),
                        if (ticket.adminReplyAt != null)
                          Text(AppFormatters.formatDate(ticket.adminReplyAt!), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(ticket.adminReply!, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // Action: Reply & Update Status
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showReplyDialog(ticket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.reply, size: 18),
                label: Text(
                  ticket.adminReply != null ? 'उत्तर बदला / स्टेटस अपडेट करा' : 'मंडळाला उत्तर द्या (Reply)',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(SupportTicket ticket) {
    final replyController = TextEditingController(text: ticket.adminReply ?? '');
    String status = ticket.status == 'open' ? 'in_progress' : ticket.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.support_agent, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('मंडळाला उत्तर पाठवा', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(ticket.mandalName, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'विषय: ${ticket.subject}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'पाठवणारा: ${ticket.userName} (${ticket.userMobile ?? ""})',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 14),

                const Text('स्थिती (Status) बदला:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('🔴 प्रलंबित (Open)')),
                    DropdownMenuItem(value: 'in_progress', child: Text('🔵 तपासणी सुरू (In Progress)')),
                    DropdownMenuItem(value: 'resolved', child: Text('🟢 समस्या सुटली / सोडवले (Resolved)')),
                    DropdownMenuItem(value: 'closed', child: Text('⚪ बंद केले (Closed)')),
                  ],
                  onChanged: (val) => setModalState(() => status = val ?? status),
                ),
                const SizedBox(height: 14),

                const Text('सुपर ॲडमिनचे उत्तर (Admin Reply) *:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: replyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'उदा. नमस्कार, आपल्या समस्येचे निराकरण केले आहे. ॲप रिस्टार्ट करून पावती तपासावी.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('रद्द करा'),
            ),
            ElevatedButton(
              onPressed: () async {
                final replyText = replyController.text.trim();
                if (replyText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('कृपया उत्तर टाईप करा')),
                  );
                  return;
                }

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final success = await ref.read(supportProvider.notifier).replyToTicket(
                  ticketId: ticket.id,
                  replyText: replyText,
                  newStatus: status,
                );

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('🚩 मंडळाला उत्तर यशस्वीपणे पाठवले गेले!'),
                    ),
                  );
                }
              },
              child: const Text('उत्तर पाठवा (Send)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImageDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.contain),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('बंद करा')),
          ],
        ),
      ),
    );
  }
}

