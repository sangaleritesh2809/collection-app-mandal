import '../../../core/utils/formatters.dart';

class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String? userMobile;
  final String? userEmail;
  final String? mandalId;
  final String mandalName;
  final String? mandalCode;
  final String? mandalLocation;
  final String? userRole;
  final String category;
  final String subject;
  final String description;
  final String? screenshotUrl;
  final String priority;
  final String status;
  final String? adminReply;
  final DateTime? adminReplyAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    this.userMobile,
    this.userEmail,
    this.mandalId,
    required this.mandalName,
    this.mandalCode,
    this.mandalLocation,
    this.userRole,
    required this.category,
    required this.subject,
    required this.description,
    this.screenshotUrl,
    this.priority = 'medium',
    this.status = 'open',
    this.adminReply,
    this.adminReplyAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'अनामिक वापरकर्ता',
      userMobile: json['user_mobile'] as String?,
      userEmail: json['user_email'] as String?,
      mandalId: json['mandal_id'] as String?,
      mandalName: json['mandal_name'] as String? ?? 'मंडळ स्पष्ट नाही',
      mandalCode: json['mandal_code'] as String?,
      mandalLocation: json['mandal_location'] as String?,
      userRole: json['user_role'] as String?,
      category: json['category'] as String? ?? 'technical',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      screenshotUrl: json['screenshot_url'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      adminReply: json['admin_reply'] as String?,
      adminReplyAt: json['admin_reply_at'] != null
          ? DateTime.tryParse(json['admin_reply_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_mobile': userMobile,
      'user_email': userEmail,
      'mandal_id': mandalId,
      'mandal_name': mandalName,
      'mandal_code': mandalCode,
      'mandal_location': mandalLocation,
      'user_role': userRole,
      'category': category,
      'subject': subject,
      'description': description,
      'screenshot_url': screenshotUrl,
      'priority': priority,
      'status': status,
      'admin_reply': adminReply,
      'admin_reply_at': adminReplyAt?.toIso8601String(),
    };
  }

  String get statusMarathi {
    switch (status) {
      case 'open':
        return 'प्रलंबित (Open)';
      case 'in_progress':
        return 'तपासणी सुरू (In Progress)';
      case 'resolved':
        return 'सोडवले (Resolved)';
      case 'closed':
        return 'बंद केले (Closed)';
      default:
        return status;
    }
  }

  String get categoryMarathi {
    switch (category) {
      case 'payment_qr':
        return 'पेमेंट / UPI / QR कोड समस्या';
      case 'receipt_vargani':
        return 'पावती / वर्गणी संकलन समस्या';
      case 'report_calc':
        return 'हिशेब / अहवाल त्रुटी';
      case 'feature_request':
        return 'नवीन फिचर विनंती';
      case 'technical':
        return 'तांत्रिक अडचण / बग';
      default:
        return 'इतर अडचण';
    }
  }

  String get priorityMarathi {
    switch (priority) {
      case 'urgent':
        return 'तात्काळ (Urgent)';
      case 'high':
        return 'उच्च (High)';
      case 'low':
        return 'कमी (Low)';
      default:
        return 'साधारण (Normal)';
    }
  }

  String get formattedDate => AppFormatters.formatDate(createdAt);
}

