import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const _url = 'https://kkrprfwflyafxvxcvcxi.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtrcnByZndmbHlhZnh2eGN2Y3hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5ODI3ODYsImV4cCI6MjA5MjU1ODc4Nn0.RXSQmVMM4BtRdZOiU8f-6DAJ8aHHUuGIw73r5jHxo38';

  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
