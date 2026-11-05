import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/form_label.dart';
import '../models/support_ticket.dart';
import '../providers/support_provider.dart';

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportProvider.notifier).loadUserTickets());
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
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('माझ्या तक्रारी व मदत (My Tickets)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'रिफ्रेश करा',
            onPressed: () => ref.read(supportProvider.notifier).loadUserTickets(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/report-issue'),
        icon: const Icon(Icons.add_comment),
        label: const Text('नवीन समस्या नोंदवा'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(supportProvider.notifier).loadUserTickets(),
          child: ResponsiveContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: supportState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : supportState.userTickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.support_agent, size: 54, color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'कोणतीही तक्रार किंवा समस्या नोंदवलेली नाही',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ॲप वापरताना काहीही अडचण आल्यास तुम्ही थेट सुपर ॲडमिनला मेसेज करू शकता.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/report-issue'),
                              icon: const Icon(Icons.add),
                              label: const Text('समस्या नोंदवा'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: supportState.userTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = supportState.userTickets[index];
                          return _buildTicketCard(ticket);
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final statusColor = _getStatusColor(ticket.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    ticket.statusMarathi,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  ticket.formattedDate,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mandal details
            Row(
              children: [
                const Icon(Icons.temple_hindu, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'मंडळ: ${ticket.mandalName} ${ticket.mandalCode != null ? "(${ticket.mandalCode})" : ""}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Subject
            Text(
              ticket.subject,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Category
            Text(
              'प्रकार: ${ticket.categoryMarathi}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 8),

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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ticket.screenshotUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text('📷 फोटो उपलब्ध नाही', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],

            // Admin Reply Section (if replied)
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
                        const Icon(Icons.verified_user, color: Colors.green, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'सुपर ॲडमिनचे उत्तर (Admin Reply):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket.adminReply!,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    if (ticket.adminReplyAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'उत्तर दिनांक: ${AppFormatters.formatDate(ticket.adminReplyAt!)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.hourglass_top, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    'सुपर ॲडमिनकडून तपासणी सुरू आहे. लवकरच उत्तर मिळेल.',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ],
              ),
            ],
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

