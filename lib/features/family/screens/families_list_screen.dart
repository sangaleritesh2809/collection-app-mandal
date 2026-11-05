import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/responsive_container.dart';
import '../providers/family_provider.dart';

class FamiliesListScreen extends ConsumerWidget {
  const FamiliesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final familyState = ref.watch(familyProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('कुटुंबे यादी (Families)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'रिफ्रेश करा',
            onPressed: () => ref.read(familyProvider.notifier).loadFamilies(),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-family'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('नवीन कुटुंब जोडा', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 760,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Search & Filter Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (val) => ref.read(familyProvider.notifier).setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'कुटुंब प्रमुख किंवा कुटुंबाचे नाव शोधा...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryPurple),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: familyState.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
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
              const SizedBox(height: 6),

              // List
              Expanded(
                child: familyState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
                    : familyState.filteredFamilies.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.family_restroom_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  AppStrings.tr(BuildContextKey.emptyList, lang),
                                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primaryPurple,
                            onRefresh: () => ref.read(familyProvider.notifier).loadFamilies(),
                            child: ListView.builder(
                              itemCount: familyState.filteredFamilies.length,
                              padding: const EdgeInsets.only(bottom: 90, top: 4, left: 16, right: 16),
                              itemBuilder: (context, index) {
                                final family = familyState.filteredFamilies[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.cardBorder),
                                    boxShadow: AppShadows.soft,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => context.push('/family-details/${family.id}', extra: family),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  gradient: AppColors.primaryGradient,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    family.familyName.isNotEmpty ? family.familyName[0] : 'फ',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
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
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'प्रमुख: ${family.familyHeadName}',
                                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                                                '👥 सदस्य: ${family.totalMembers} व्यक्ती',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                              if (family.mobileNumber != null && family.mobileNumber!.isNotEmpty)
                                                Text(
                                                  '📞 +91 ${family.mobileNumber!}',
                                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                                ),
                                            ],
                                          ),
                                          const Divider(height: 20),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _statColumn('ठरलेली वर्गणी', AppFormatters.formatCurrency(family.totalVargani)),
                                              _statColumn('जमा रक्कम', AppFormatters.formatCurrency(family.paidAmount), color: AppColors.success),
                                              _statColumn('बाकी रक्कम', AppFormatters.formatCurrency(family.pendingAmount), color: family.pendingAmount > 0 ? AppColors.error : AppColors.success),
                                            ],
                                          ),
                                          if (family.pendingAmount > 0) ...[
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: () => context.push('/add-collection', extra: family),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.royalBlue,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  elevation: 1,
                                                ),
                                                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                                label: const Text('वर्गणी जमा करा (पावती बनवा)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
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
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String type, String currentType, {Color? color}) {
    final isSelected = type == currentType;
    final chipColor = color ?? AppColors.primaryPurple;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => ref.read(familyProvider.notifier).setFilterType(type),
      selectedColor: chipColor.withOpacity(0.14),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? chipColor : AppColors.cardBorder),
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildStatusBadge(dynamic family) {
    Color bg;
    Color text;
    String label;

    if (family.isFullyPaid) {
      bg = AppColors.successLight;
      text = AppColors.success;
      label = 'पूर्ण जमा';
    } else if (family.isPartiallyPaid) {
      bg = AppColors.warningLight;
      text = const Color(0xFFB45309);
      label = 'अंशतः जमा';
    } else {
      bg = AppColors.errorLight;
      text = AppColors.error;
      label = 'शिल्लक बाकी';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: text.withOpacity(0.3)),
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
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}
