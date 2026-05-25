import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/supabase_service.dart';

/// Display name for greetings (never the raw email local-part).
String resolveUserDisplayName(BuildContext context) {
  final profile = context.watch<SettingsProvider>().profile;

  final fromProfile = profile?.fullName?.trim();
  if (fromProfile != null && fromProfile.isNotEmpty) {
    return fromProfile;
  }

  final user = SupabaseService.client.auth.currentUser;
  final metaName = user?.userMetadata?['full_name'] as String?;
  if (metaName != null && metaName.trim().isNotEmpty) {
    return metaName.trim();
  }

  return 'there';
}

/// First name only for compact headers.
String resolveUserFirstName(BuildContext context) {
  final full = resolveUserDisplayName(context);
  if (full == 'there') return full;
  return full.split(RegExp(r'\s+')).first;
}
