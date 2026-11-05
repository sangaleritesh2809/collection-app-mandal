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
        title: const Text('मंडळ निवडा (Select Mandal)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'रिफ्रेश करा',
            onPressed: () => ref.read(mandalProvider.notifier).loadUserMandals(),
          ),
        ],
      ),
      body: SafeArea(
        child: mandalState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple))
            : SingleChildScrollView(
                child: ResponsiveContainer(
                  maxWidth: 760,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(18),
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
                              width: 48,
                              height: 48,
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'आपली मंडळे (My Mandals)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'हिशोब व वर्गणी संकलनासाठी मंडळ निवडा:',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      if (mandalState.userMandals.isEmpty) ...[
                        const SizedBox(height: 40),
                        Center(
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
                                const Text(
                                  'तुम्ही कोणत्याही मंडळात सामील नाही आहात',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'नवीन मंडळ नोंदवा किंवा अध्यक्षांनी दिलेल्या आमंत्रण कोडने मंडळात सामील व्हा.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ] else ...[
                        ...mandalState.userMandals.map((mandal) {
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
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.check_circle, size: 13, color: AppColors.success),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'सक्रिय (Active)',
                                                        style: TextStyle(
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
                                                    const SnackBar(content: Text('आमंत्रण कोड कॉपी झाला!')),
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
                        }),
                        const SizedBox(height: 18),
                      ],

                      // Actions Grid
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
                                label: const Text('नवीन मंडळ', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                              label: const Text('मंडळात सामील व्हा', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryPurple,
                                side: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
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
