import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class SettingsProvider extends ChangeNotifier {
  final _client = SupabaseService.client;

  UserProfile? _profile;
  bool _loading = false;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  bool get onboardingCompleted => _profile?.onboardingCompleted ?? false;

  Future<void> fetchProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _loading = true;
    notifyListeners();
    try {
      final data = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        _profile = UserProfile.fromJson(data);
      } else {
        final email = _client.auth.currentUser?.email ?? '';
        _profile = UserProfile(id: userId, fullName: email.split('@').first);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> ensureProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final existing = await _client
        .from('user_profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      final meta = _client.auth.currentUser?.userMetadata;
      await _client.from('user_profiles').insert({
        'id': userId,
        'full_name': meta?['full_name'] ?? '',
      });
    }
    await fetchProfile();
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    int? defaultRentDueDay,
    bool? defaultWhatsappEnabled,
    Map<String, dynamic>? settingsPatch,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (defaultRentDueDay != null) updates['default_rent_due_day'] = defaultRentDueDay;
    if (defaultWhatsappEnabled != null) {
      updates['default_whatsapp_enabled'] = defaultWhatsappEnabled;
    }
    if (settingsPatch != null) {
      final current = Map<String, dynamic>.from(_profile?.settings ?? {});
      current.addAll(settingsPatch);
      updates['settings'] = current;
    }

    if (updates.isEmpty) return;

    await _client.from('user_profiles').update(updates).eq('id', userId);
    await fetchProfile();
  }

  Future<void> completeOnboarding() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('user_profiles')
        .update({'onboarding_completed': true})
        .eq('id', userId);
    await fetchProfile();
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
