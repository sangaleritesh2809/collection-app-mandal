import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { marathi, english }

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.marathi) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('app_language');
      if (code == 'en') {
        state = AppLanguage.english;
      } else {
        state = AppLanguage.marathi;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', language == AppLanguage.english ? 'en' : 'mr');
    } catch (_) {}
  }

  void toggleLanguage() {
    setLanguage(state == AppLanguage.marathi ? AppLanguage.english : AppLanguage.marathi);
  }
}

class AppStrings {
  static String tr(BuildContextKey key, AppLanguage lang) {
    final isMr = lang == AppLanguage.marathi;
    switch (key) {
      // General
      case BuildContextKey.appName:
        return isMr ? 'वर्गणी कलेक्शन' : 'Vargani Collection';
      case BuildContextKey.appTagline:
        return isMr ? 'मंडळ व्यवस्थापन व वर्गणी संकलन' : 'Mandal Management & Vargani Collection';
      case BuildContextKey.welcome:
        return isMr ? 'स्वागत आहे!' : 'Welcome!';
      case BuildContextKey.login:
        return isMr ? 'लॉगिन करा' : 'Login';
      case BuildContextKey.register:
        return isMr ? 'नवीन नोंदणी करा' : 'Register';
      case BuildContextKey.logout:
        return isMr ? 'बाहेर पडा (Logout)' : 'Logout';
      case BuildContextKey.save:
        return isMr ? 'जतन करा' : 'Save';
      case BuildContextKey.cancel:
        return isMr ? 'रद्द करा' : 'Cancel';
      case BuildContextKey.confirm:
        return isMr ? 'निश्चित करा' : 'Confirm';
      case BuildContextKey.delete:
        return isMr ? 'हटवा' : 'Delete';
      case BuildContextKey.edit:
        return isMr ? 'संपादित करा' : 'Edit';
      case BuildContextKey.submit:
        return isMr ? 'सबमिट करा' : 'Submit';
      case BuildContextKey.search:
        return isMr ? 'शोधा...' : 'Search...';
      case BuildContextKey.filter:
        return isMr ? 'फिल्टर' : 'Filter';
      case BuildContextKey.loading:
        return isMr ? 'कृपया प्रतीक्षा करा...' : 'Please wait...';
      case BuildContextKey.emptyList:
        return isMr ? 'कोणतीही नोंद उपलब्ध नाही' : 'No records found';

      // Navigation & Modules
      case BuildContextKey.home:
        return isMr ? 'मुख्य पान' : 'Home';
      case BuildContextKey.dashboard:
        return isMr ? 'डॅशबोर्ड' : 'Dashboard';
      case BuildContextKey.mandal:
        return isMr ? 'मंडळ' : 'Mandal';
      case BuildContextKey.families:
        return isMr ? 'कुटुंबे' : 'Families';
      case BuildContextKey.members:
        return isMr ? 'सदस्य' : 'Members';
      case BuildContextKey.collection:
        return isMr ? 'वर्गणी' : 'Collection';
      case BuildContextKey.depositRequests:
        return isMr ? 'ठेव विनंत्या' : 'Deposit Requests';
      case BuildContextKey.expenses:
        return isMr ? 'खर्च' : 'Expenses';
      case BuildContextKey.reports:
        return isMr ? 'अहवाल' : 'Reports';
      case BuildContextKey.notifications:
        return isMr ? 'सूचना' : 'Notifications';
      case BuildContextKey.settings:
        return isMr ? 'सेटिंग्ज' : 'Settings';

      // Auth
      case BuildContextKey.fullName:
        return isMr ? 'पूर्ण नाव' : 'Full Name';
      case BuildContextKey.email:
        return isMr ? 'ईमेल पत्ता' : 'Email Address';
      case BuildContextKey.mobile:
        return isMr ? 'मोबाईल नंबर' : 'Mobile Number';
      case BuildContextKey.password:
        return isMr ? 'पासवर्ड' : 'Password';
      case BuildContextKey.confirmPassword:
        return isMr ? 'पासवर्ड पुष्टी करा' : 'Confirm Password';
      case BuildContextKey.forgotPassword:
        return isMr ? 'पासवर्ड विसरलात?' : 'Forgot Password?';

      // Financials
      case BuildContextKey.totalExpected:
        return isMr ? 'अपेक्षित वर्गणी' : 'Expected Vargani';
      case BuildContextKey.totalCollected:
        return isMr ? 'एकूण गोळा वर्गणी' : 'Total Collected';
      case BuildContextKey.totalPending:
        return isMr ? 'बाकी वर्गणी' : 'Pending Vargani';
      case BuildContextKey.totalDeposited:
        return isMr ? 'खजिनदाराकडे जमा' : 'Deposited with Treasurer';
      case BuildContextKey.totalExpenses:
        return isMr ? 'एकूण मंजूर खर्च' : 'Total Expenses';
      case BuildContextKey.availableBalance:
        return isMr ? 'शिल्लक रक्कम' : 'Available Balance';
      case BuildContextKey.awaitingDeposit:
        return isMr ? 'जमा करायची बाकी' : 'Awaiting Deposit';

      // Actions
      case BuildContextKey.createMandal:
        return isMr ? 'नवीन मंडळ तयार करा' : 'Create Mandal';
      case BuildContextKey.joinMandal:
        return isMr ? 'मंडळात सामील व्हा' : 'Join Mandal';
      case BuildContextKey.shareReceipt:
        return isMr ? 'पावती शेअर करा' : 'Share Receipt';
      case BuildContextKey.printReceipt:
        return isMr ? 'पावती प्रिंट करा' : 'Print Receipt';
      case BuildContextKey.sendWhatsapp:
        return isMr ? 'WhatsApp वर पाठवा' : 'Send via WhatsApp';
      case BuildContextKey.approve:
        return isMr ? 'मंजूर करा' : 'Approve';
      case BuildContextKey.reject:
        return isMr ? 'नाकारा' : 'Reject';
    }
  }
}

enum BuildContextKey {
  appName,
  appTagline,
  welcome,
  login,
  register,
  logout,
  save,
  cancel,
  confirm,
  delete,
  edit,
  submit,
  search,
  filter,
  loading,
  emptyList,
  home,
  dashboard,
  mandal,
  families,
  members,
  collection,
  depositRequests,
  expenses,
  reports,
  notifications,
  settings,
  fullName,
  email,
  mobile,
  password,
  confirmPassword,
  forgotPassword,
  totalExpected,
  totalCollected,
  totalPending,
  totalDeposited,
  totalExpenses,
  availableBalance,
  awaitingDeposit,
  createMandal,
  joinMandal,
  shareReceipt,
  printReceipt,
  sendWhatsapp,
  approve,
  reject,
}
