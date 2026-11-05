import 'package:go_router/go_router.dart';
import '../services/pdf_service.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/home_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/mandal/screens/mandal_selection_screen.dart';
import '../../features/mandal/screens/create_mandal_screen.dart';
import '../../features/mandal/screens/join_mandal_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/family/screens/families_list_screen.dart';
import '../../features/family/screens/add_edit_family_screen.dart';
import '../../features/family/screens/family_details_screen.dart';
import '../../features/family/models/family.dart';
import '../../features/collection/screens/collections_list_screen.dart';
import '../../features/collection/screens/add_collection_screen.dart';
import '../../features/collection/screens/receipt_preview_screen.dart';
import '../../features/deposit/screens/deposit_requests_screen.dart';
import '../../features/deposit/screens/create_deposit_screen.dart';
import '../../features/expense/screens/expenses_list_screen.dart';
import '../../features/expense/screens/add_expense_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/vargani_config/screens/vargani_config_screen.dart';
import '../../features/mandal/screens/mandal_payment_settings_screen.dart';
import '../../features/support/screens/report_issue_screen.dart';
import '../../features/support/screens/my_tickets_screen.dart';
import '../../features/support/screens/super_admin_tickets_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/mandal-selection',
      builder: (context, state) => const MandalSelectionScreen(),
    ),
    GoRoute(
      path: '/create-mandal',
      builder: (context, state) => const CreateMandalScreen(),
    ),
    GoRoute(
      path: '/join-mandal',
      builder: (context, state) => const JoinMandalScreen(),
    ),
    GoRoute(
      path: '/families',
      builder: (context, state) => const FamiliesListScreen(),
    ),
    GoRoute(
      path: '/add-family',
      builder: (context, state) => const AddEditFamilyScreen(),
    ),
    GoRoute(
      path: '/family-details/:id',
      builder: (context, state) {
        final familyId = state.pathParameters['id'] ?? '';
        final family = state.extra as Family?;
        return FamilyDetailsScreen(familyId: familyId, initialFamily: family);
      },
    ),
    GoRoute(
      path: '/collections',
      builder: (context, state) => const CollectionsListScreen(),
    ),
    GoRoute(
      path: '/add-collection',
      builder: (context, state) {
        final family = state.extra as Family?;
        return AddCollectionScreen(initialFamily: family);
      },
    ),
    GoRoute(
      path: '/receipt-preview',
      builder: (context, state) {
        final receipt = state.extra as PdfReceiptData;
        return ReceiptPreviewScreen(receiptData: receipt);
      },
    ),
    GoRoute(
      path: '/deposits',
      builder: (context, state) => const DepositRequestsScreen(),
    ),
    GoRoute(
      path: '/create-deposit',
      builder: (context, state) => const CreateDepositScreen(),
    ),
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const ExpensesListScreen(),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/vargani-config',
      builder: (context, state) => const VarganiConfigScreen(),
    ),
    GoRoute(
      path: '/mandal-payment-settings',
      builder: (context, state) => const MandalPaymentSettingsScreen(),
    ),
    GoRoute(
      path: '/report-issue',
      builder: (context, state) => const ReportIssueScreen(),
    ),
    GoRoute(
      path: '/my-tickets',
      builder: (context, state) => const MyTicketsScreen(),
    ),
    GoRoute(
      path: '/super-admin-tickets',
      builder: (context, state) => const SuperAdminTicketsScreen(),
    ),
  ],
);
