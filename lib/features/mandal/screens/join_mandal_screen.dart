import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/form_label.dart';
import '../providers/mandal_provider.dart';

class JoinMandalScreen extends ConsumerStatefulWidget {
  const JoinMandalScreen({super.key});

  @override
  ConsumerState<JoinMandalScreen> createState() => _JoinMandalScreenState();
}

class _JoinMandalScreenState extends ConsumerState<JoinMandalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _codeController.text.trim();

    final success = await ref.read(mandalProvider.notifier).joinMandal(code);
    if (success && mounted) {
      final mandalName = ref.read(mandalProvider).selectedMandal?.name ?? 'मंडळ';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('$mandalName मध्ये सहभाग यशस्वी झाला!'),
        ),
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
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
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
                Text(
                  lang.tr('आमंत्रण कोड टाका', 'Enter Invite Code'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.tr('मंडळाच्या अध्यक्षांनी किंवा खजिनदारांनी दिलेला ८ अंकी कोड येथे टाका', 'Enter the 8 character code provided by the mandal admin'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

                FormLabel(lang.tr('आमंत्रण कोड', 'Invite Code'), isRequired: true),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 8,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(8),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: lang.tr('आमंत्रण कोड टाका', 'Enter invite code'),
                    counterText: '',
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  validator: AppValidators.inviteCode,
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
                      : Text(lang.tr('मंडळात सामील व्हा', 'Join Mandal')),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

