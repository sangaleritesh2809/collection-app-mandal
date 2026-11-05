import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/mandal_provider.dart';

class JoinMandalScreen extends ConsumerStatefulWidget {
  const JoinMandalScreen({super.key});

  @override
  ConsumerState<JoinMandalScreen> createState() => _JoinMandalScreenState();
}

class _JoinMandalScreenState extends ConsumerState<JoinMandalScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    final success = await ref.read(mandalProvider.notifier).joinMandal(code);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('मंडळामध्ये सहभाग यशस्वी झाला!')),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final mandalState = ref.watch(mandalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(BuildContextKey.joinMandal, lang)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add, size: 48, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'आमंत्रण कोड (Invite Code) टाका',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'मंडळाच्या अध्यक्षांनी किंवा खजिनदारांनी दिलेला ६ किंवा ७ अंकी कोड येथे टाका (उदा. VG2026A)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
              ),
              const SizedBox(height: 28),

              if (mandalState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    mandalState.error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),

              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'VG2026A',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: mandalState.isLoading ? null : _handleJoin,
                child: mandalState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('मंडळात सामील व्हा (Join Mandal)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

