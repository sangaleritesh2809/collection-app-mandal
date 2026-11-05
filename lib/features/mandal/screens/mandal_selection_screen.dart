import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/responsive_container.dart';
import '../providers/mandal_provider.dart';

class MandalSelectionScreen extends ConsumerWidget {
  const MandalSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final mandalState = ref.watch(mandalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(lang.tr('मंडळ निवडा', 'Select Mandal')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: lang.tr('रिफ्रेश करा', 'Refresh'),
            onPressed: () => ref.read(mandalProvider.notifier).loadUserMandals(),
          ),
        ],
      ),
      body: SafeArea(
        child: mandalState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
            : ResponsiveContainer(
                maxWidth: 760,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Card (Fixed at Top)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryPurple.withOpacity(0.08),
                            AppColors.royalBlue.withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/vargani_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.temple_hindu, color: AppColors.primaryPurple),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.tr('आपली मंडळे', 'My Mandals'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang.tr('हिशोब व वर्गणी संकलनासाठी मंडळ निवडा:', 'Select a mandal for accounts & collections:'),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Action Buttons (FIXED AT TOP - Will NEVER disappear or scroll away!)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppShadows.soft,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => context.push('/create-mandal'),
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              label: Text(
                                lang.tr('नवीन मंडळ', 'New Mandal'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/join-mandal'),
                            icon: const Icon(Icons.group_add_rounded, size: 18),
                            label: Text(
                              lang.tr('मंडळात सामील व्हा', 'Join Mandal'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryPurple,
                              side: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Scrollable Mandals List
                    Expanded(
                      child: mandalState.userMandals.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.cardBorder),
                                  boxShadow: AppShadows.soft,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.domain_disabled_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.6)),
                                    const SizedBox(height: 16),
                                    Text(
                                      lang.tr('तुम्ही कोणत्याही मंडळात सामील नाही आहात', 'You have not joined any mandal yet'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lang.tr(
                                        'नवीन मंडळ नोंदवा किंवा अध्यक्षांनी दिलेल्या आमंत्रण कोडने मंडळात सामील व्हा.',
                                        'Register a new mandal or join using the invite code from your admin.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.primaryPurple,
                              onRefresh: () => ref.read(mandalProvider.notifier).loadUserMandals(),
                              child: ListView.builder(
                                itemCount: mandalState.userMandals.length,
                                padding: const EdgeInsets.only(bottom: 24),
                                itemBuilder: (context, index) {
                                  final mandal = mandalState.userMandals[index];
                                  final isSelected = mandalState.selectedMandal?.id == mandal.id;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryPurple : AppColors.cardBorder,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected ? AppShadows.card : AppShadows.soft,
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        ref.read(mandalProvider.notifier).selectMandal(mandal);
                                        context.go('/dashboard');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Mandal Avatar
                                            Container(
                                              width: 52,
                                              height: 52,
                                              decoration: BoxDecoration(
                                                gradient: isSelected ? AppColors.primaryGradient : null,
                                                color: isSelected ? null : AppColors.primaryPurple.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: Center(
                                                child: mandal.logoUrl != null && mandal.logoUrl!.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(14),
                                                        child: Image.network(mandal.logoUrl!, fit: BoxFit.cover),
                                                      )
                                                    : Icon(
                                                        Icons.temple_hindu_rounded,
                                                        color: isSelected ? Colors.white : AppColors.primaryPurple,
                                                        size: 28,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),

                                            // Mandal Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          mandal.name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 16,
                                                            color: AppColors.textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.successLight,
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(Icons.check_circle, size: 13, color: AppColors.success),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                lang.tr('सक्रिय', 'Active'),
                                                                style: const TextStyle(
                                                                  color: AppColors.success,
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '📍 ${mandal.village ?? 'गाव'}${mandal.district != null ? ', ${mandal.district}' : ''}',
                                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      // Role badge
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: _getRoleBgColor(mandal.userRole),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          mandal.userRole ?? 'सदस्य',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                            color: _getRoleTextColor(mandal.userRole),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),

                                                      // Code chip with copy
                                                      InkWell(
                                                        onTap: () {
                                                          Clipboard.setData(ClipboardData(text: mandal.invitationCode));
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text(lang.tr('आमंत्रण कोड कॉपी झाला!', 'Invite code copied!'))),
                                                          );
                                                        },
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.lightLavender,
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: AppColors.cardBorder),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(Icons.vpn_key_rounded, size: 12, color: AppColors.royalBlue),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                mandal.invitationCode,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: AppColors.royalBlue,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 4),
                                                              const Icon(Icons.copy_rounded, size: 12, color: AppColors.textSecondary),
                                                            ],
                                                          ),
                                                        ),
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

  Color _getRoleBgColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
      case 'अध्यक्ष':
        return AppColors.primaryPurple.withOpacity(0.12);
      case 'treasurer':
      case 'खजिनदार':
        return AppColors.royalBlue.withOpacity(0.12);
      case 'collector':
      case 'संकलक':
        return AppColors.success.withOpacity(0.12);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getRoleTextColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
      case 'अध्यक्ष':
        return AppColors.primaryPurple;
      case 'treasurer':
      case 'खजिनदार':
        return AppColors.royalBlue;
      case 'collector':
      case 'संकलक':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
