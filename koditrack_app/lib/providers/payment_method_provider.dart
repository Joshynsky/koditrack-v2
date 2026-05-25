import 'package:flutter/material.dart';
import '../models/payment_method.dart';
import '../services/supabase_service.dart';
import '../utils/mpesa_format.dart';

class PaymentMethodProvider extends ChangeNotifier {
  final _client = SupabaseService.client;

  List<PaymentMethod> _methods = [];
  bool _loading = false;

  List<PaymentMethod> get methods => _methods;
  bool get loading => _loading;
  bool get hasMethods => _methods.isNotEmpty;

  PaymentMethod? get defaultMethod {
    try {
      return _methods.firstWhere((m) => m.isDefault && m.isActive);
    } catch (_) {
      return _methods.isEmpty ? null : _methods.first;
    }
  }

  PaymentMethod? getById(String? id) {
    if (id == null) return null;
    try {
      return _methods.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchMethods() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _loading = true;
    notifyListeners();
    try {
      final data = await _client
          .from('payment_methods')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      _methods = data.map((j) => PaymentMethod.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<PaymentMethod> addMethod({
    required String type,
    required String displayName,
    String? phoneNumber,
    String? businessNumber,
    String? accountNumber,
    String? tillNumber,
    bool setAsDefault = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final isFirst = _methods.isEmpty;
    final row = {
      'user_id': userId,
      'type': type,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'business_number': businessNumber,
      'account_number': accountNumber,
      'till_number': tillNumber,
      'is_default': setAsDefault || isFirst,
    };

    final data = await _client.from('payment_methods').insert(row).select().single();
    await fetchMethods();
    return PaymentMethod.fromJson(data);
  }

  Future<void> updateMethod({
    required String id,
    required String displayName,
    String? phoneNumber,
    String? businessNumber,
    String? accountNumber,
    String? tillNumber,
    bool? isDefault,
  }) async {
    await _client.from('payment_methods').update({
      'display_name': displayName,
      'phone_number': phoneNumber,
      'business_number': businessNumber,
      'account_number': accountNumber,
      'till_number': tillNumber,
      if (isDefault != null) 'is_default': isDefault,
    }).eq('id', id);
    await fetchMethods();
  }

  Future<void> setDefault(String id) async {
    await _client
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', id);
    await fetchMethods();
  }

  Future<void> deleteMethod(String id) async {
    await _client.from('payment_methods').update({'is_active': false}).eq('id', id);
    await fetchMethods();
  }

  /// Validates fields for a given type. Returns error message or null.
  static String? validate({
    required String type,
    required String displayName,
    String? phoneRaw,
    String? businessNumber,
    String? tillNumber,
  }) {
    if (displayName.trim().isEmpty) return 'Display name is required';

    switch (type) {
      case 'send_money':
        if (MpesaFormat.normalizePhone(phoneRaw) == null) {
          return 'Enter a valid Kenyan phone number (07XX or 2547XX)';
        }
        break;
      case 'paybill':
        if (businessNumber == null || businessNumber.trim().isEmpty) {
          return 'Paybill business number is required';
        }
        break;
      case 'till':
        if (tillNumber == null || tillNumber.trim().isEmpty) {
          return 'Till number is required';
        }
        break;
    }
    return null;
  }
}
