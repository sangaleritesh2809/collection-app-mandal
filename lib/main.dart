import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/services/admob_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend
  await SupabaseService.initialize();

  // Safely initialize AdMob (never blocks Supabase or crashes startup)
  try {
    await AdMobService.initialize();
  } catch (e) {
    debugPrint('AdMob initialization warning: $e');
  }

  runApp(
    const ProviderScope(
      child: VarganiCollectionApp(),
    ),
  );
}

class VarganiCollectionApp extends ConsumerWidget {
  const VarganiCollectionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'वर्गणी कलेक्शन - Vargani Collection',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      locale: language == AppLanguage.marathi
          ? const Locale('mr', 'IN')
          : const Locale('en', 'US'),
      supportedLocales: const [
        Locale('mr', 'IN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
