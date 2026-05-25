class UserProfile {
  final String id;
  final String? fullName;
  final String? phone;
  final bool onboardingCompleted;
  final int defaultRentDueDay;
  final bool defaultWhatsappEnabled;
  final Map<String, dynamic> settings;

  UserProfile({
    required this.id,
    this.fullName,
    this.phone,
    this.onboardingCompleted = false,
    this.defaultRentDueDay = 5,
    this.defaultWhatsappEnabled = true,
    this.settings = const {},
  });

  bool get dashboardAutoRefresh =>
      settings['dashboard_auto_refresh'] as bool? ?? true;

  int get overdueGraceDays => settings['overdue_grace_days'] as int? ?? 0;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      defaultRentDueDay: json['default_rent_due_day'] as int? ?? 5,
      defaultWhatsappEnabled: json['default_whatsapp_enabled'] as bool? ?? true,
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'phone': phone,
      'onboarding_completed': onboardingCompleted,
      'default_rent_due_day': defaultRentDueDay,
      'default_whatsapp_enabled': defaultWhatsappEnabled,
      'settings': settings,
    };
  }
}
