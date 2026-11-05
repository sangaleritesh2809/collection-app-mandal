/// Comprehensive, user-friendly Marathi validators for all form inputs
class AppValidators {
  /// Required text field validation
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName आवश्यक आहे.';
    }
    return null;
  }

  /// Name validation (e.g., family name, person name, mandal name)
  static String? name(String? value, String fieldName, {int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName आवश्यक आहे.';
    }
    final trimmed = value.trim();
    if (trimmed.length < minLength) {
      return '$fieldName किमान $minLength अक्षरांचे असावे.';
    }
    return null;
  }

  /// Indian Mobile Number validation (10 digits starting with 6, 7, 8, 9)
  static String? mobile(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'मोबाईल नंबर आवश्यक आहे.';
      return null;
    }
    final trimmed = value.trim();
    // Remove leading +91 or 0 if present
    final cleanNumber = trimmed.replaceAll(RegExp(r'^\+91|^0'), '').trim();
    
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanNumber)) {
      return 'कृपया वैध १० अंकी मोबाईल नंबर टाका (उदा. ९८७६५४३२१०).';
    }
    return null;
  }

  /// Currency / Amount validation
  static String? amount(String? value, {double min = 1, double? max, String fieldName = 'रक्कम'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName आवश्यक आहे.';
    }
    final num = double.tryParse(value.trim());
    if (num == null) {
      return 'कृपया फक्त वैध आकडा (Number) टाका.';
    }
    if (num < min) {
      return '$fieldName किमान ₹$min असावी.';
    }
    if (max != null && num > max) {
      return '$fieldName ₹$max पेक्षा जास्त असू शकत नाही.';
    }
    return null;
  }

  /// Member count validation (positive integer)
  static String? memberCount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'सदस्य संख्या आवश्यक आहे.';
    }
    final count = int.tryParse(value.trim());
    if (count == null || count < 1) {
      return 'किमान १ सदस्य असणे आवश्यक आहे.';
    }
    if (count > 50) {
      return 'कृपया वैध सदस्य संख्या टाका (कमाल ५०).';
    }
    return null;
  }

  /// UPI ID validation (e.g. name@bank, 9876543210@paytm)
  static String? upiId(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'UPI ID आवश्यक आहे.';
      return null;
    }
    final trimmed = value.trim();
    if (!trimmed.contains('@') || trimmed.startsWith('@') || trimmed.endsWith('@')) {
      return 'कृपया वैध UPI ID टाका (उदा. 9876543210@paytm किंवा shree@sbi).';
    }
    if (trimmed.length < 5) {
      return 'UPI ID किमान ५ अक्षरांचा असावा.';
    }
    return null;
  }

  /// UTR / Transaction Ref validation for Online Payment
  static String? utrNumber(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'UTR / ट्रान्झॅक्शन नंबर आवश्यक आहे.';
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length < 6) {
      return 'UTR नंबर किमान ६ अक्षरांचा/अंकांचा असावा.';
    }
    return null;
  }

  /// Email address validation
  static String? email(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'ईमेल पत्ता आवश्यक आहे.';
      return null;
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'कृपया वैध ईमेल पत्ता टाका (उदा. name@example.com).';
    }
    return null;
  }

  /// Password validation (minimum 6 chars)
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'पासवर्ड आवश्यक आहे.';
    }
    if (value.length < minLength) {
      return 'पासवर्ड किमान $minLength अक्षरांचा असावा.';
    }
    return null;
  }

  /// Confirm Password validation
  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'पासवर्ड पुन्हा टाका.';
    }
    if (value != originalPassword) {
      return 'पासवर्ड जुळत नाही (Passwords do not match).';
    }
    return null;
  }

  /// Mandal invitation code validation
  static String? inviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'आमंत्रण कोड आवश्यक आहे.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 4) {
      return 'आमंत्रण कोड किमान ४ अक्षरांचा असावा.';
    }
    return null;
  }
}

