import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/mandal_provider.dart';

class MandalSelectionScreen extends ConsumerWidget {
  const MandalSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final mandalState = ref.watch(mandalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('मंडळ निवडा (Select Mandal)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(mandalProvider.notifier).loadUserMandals(),
          ),
        ],
      ),
      body: SafeArea(
        child: mandalState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'तुम्ही ज्या मंडळाचा कारभार पाहू इच्छिता, ते मंडळ निवडा:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (mandalState.userMandals.isEmpty) ...[
                      const SizedBox(height: 40),
                      const Center(
                        child: Text(
                          'तुम्ही कोणत्याही मंडळात सामील नाही आहात.',
                          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      ...mandalState.userMandals.map((mandal) {
                        final isSelected = mandalState.selectedMandal?.id == mandal.id;
                        return Card(
                          elevation: isSelected ? 3 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              ref.read(mandalProvider.notifier).selectMandal(mandal);
                              context.go('/dashboard');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    child: const Icon(Icons.temple_hindu, color: AppColors.primary, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                mandal.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'सक्रिय',
                                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${mandal.village ?? ''} ${mandal.district != null ? '• ${mandal.district}' : ''}',
                                          style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                mandal.userRole ?? 'सदस्य',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'कोड: ${mandal.invitationCode}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Create & Join buttons
                    OutlinedButton.icon(
                      onPressed: () => context.push('/create-mandal'),
                      icon: const Icon(Icons.add_home_work),
                      label: Text(AppStrings.tr(BuildContextKey.createMandal, lang)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/join-mandal'),
                      icon: const Icon(Icons.group_add),
                      label: Text(AppStrings.tr(BuildContextKey.joinMandal, lang)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

