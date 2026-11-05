import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../providers/family_provider.dart';

class FamiliesListScreen extends ConsumerWidget {
  const FamiliesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.families, lang)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(familyProvider.notifier).loadFamilies(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-family'),
        icon: const Icon(Icons.person_add),
        label: const Text('नवीन कुटुंब जोडा'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (val) => ref.read(familyProvider.notifier).setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'कुटुंब प्रमुख किंवा कुटुंबाचे नाव शोधा...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: familyState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => ref.read(familyProvider.notifier).setSearchQuery(''),
                        )
                      : null,
                ),
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _filterChip(ref, 'सर्व (${familyState.families.length})', 'all', familyState.filterType),
                  const SizedBox(width: 8),
                  _filterChip(ref, 'बाकी असलेले (Unpaid)', 'unpaid', familyState.filterType, color: AppColors.error),
                  const SizedBox(width: 8),
                  _filterChip(ref, 'अंशतः भरलेले (Partial)', 'partially_paid', familyState.filterType, color: AppColors.warning),
                  const SizedBox(width: 8),
                  _filterChip(ref, 'पूर्ण भरलेले (Paid)', 'fully_paid', familyState.filterType, color: AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: familyState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : familyState.filteredFamilies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                AppStrings.tr(BuildContextKey.emptyList, lang),
                                style: const TextStyle(fontSize: 15, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(familyProvider.notifier).loadFamilies(),
                          child: ListView.builder(
                            itemCount: familyState.filteredFamilies.length,
                            padding: const EdgeInsets.only(bottom: 80, top: 4),
                            itemBuilder: (context, index) {
                              final family = familyState.filteredFamilies[index];
                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => context.push('/family-details/${family.id}', extra: family),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: AppColors.primary.withOpacity(0.12),
                                              child: Text(
                                                family.familyName.isNotEmpty ? family.familyName[0] : 'फ',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    family.familyName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'प्रमुख: ${family.familyHeadName}',
                                                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            _buildStatusBadge(family),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'सदस्य: ${family.totalMembers} व्यक्ती',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                            ),
                                            if (family.mobileNumber != null)
                                              Text(
                                                family.mobileNumber!,
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                              ),
                                          ],
                                        ),
                                        const Divider(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _statColumn('ठरलेली वर्गणी', AppFormatters.formatCurrency(family.totalVargani)),
                                            _statColumn('जमा रक्कम', AppFormatters.formatCurrency(family.paidAmount), color: AppColors.success),
                                            _statColumn('बाकी रक्कम', AppFormatters.formatCurrency(family.pendingAmount), color: family.pendingAmount > 0 ? AppColors.error : AppColors.success),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String type, String currentType, {Color? color}) {
    final isSelected = type == currentType;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(familyProvider.notifier).setFilterType(type),
      selectedColor: (color ?? AppColors.primary).withOpacity(0.18),
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppColors.primary) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildStatusBadge(dynamic family) {
    Color bg;
    Color text;
    String label;

    if (family.isFullyPaid) {
      bg = Colors.green.shade50;
      text = AppColors.success;
      label = 'पूर्ण जमा';
    } else if (family.isPartiallyPaid) {
      bg = Colors.amber.shade50;
      text = Colors.orange.shade800;
      label = 'अंशतः जमा';
    } else {
      bg = Colors.red.shade50;
      text = AppColors.error;
      label = 'शिल्लक';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _statColumn(String title, String val, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }
}

