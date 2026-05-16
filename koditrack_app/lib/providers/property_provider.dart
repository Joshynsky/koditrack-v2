import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';
import '../services/supabase_service.dart';
import '../models/payment.dart';

class PropertyProvider extends ChangeNotifier {
  final _client = SupabaseService.client;

  List<Property> _properties = [];
  List<Unit> _selectedPropertyUnits = [];
  List<Tenant> _selectedPropertyTenants = [];
  bool _loading = false;
  String? _currentPropertyId; // ← ADD THIS LINE

  List<Property> get properties => _properties;
  List<Unit> get selectedPropertyUnits => _selectedPropertyUnits;
  List<Tenant> get selectedPropertyTenants => _selectedPropertyTenants;
  bool get loading => _loading;

  List<Payment> _selectedTenantPayments = [];
  List<Payment> get selectedTenantPayments => _selectedTenantPayments;

  // ============================================
  // PROPERTIES
  // ============================================

  Future<void> fetchProperties() async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _client
          .from('properties')
          .select()
          .order('created_at', ascending: false);

      _properties = data.map((json) => Property.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching properties: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addProperty({
    required String name,
    String? type,
    String? address,
    int rentDueDay = 5,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.from('properties').insert({
      'name': name,
      'type': type,
      'address': address,
      'user_id': userId,
      'rent_due_day': rentDueDay,
    });

    await fetchProperties();
  }

  // ============================================
  // UNITS
  // ============================================

  Future<void> fetchUnits(String propertyId) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _client
          .from('units')
          .select()
          .eq('property_id', propertyId)
          .order('unit_number');

      _selectedPropertyUnits = data.map((json) => Unit.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching units: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addUnit({
    required String propertyId,
    required String unitNumber,
    int? floor,
    String? unitType,
    double? defaultRent,
  }) async {
    await _client.from('units').insert({
      'property_id': propertyId,
      'unit_number': unitNumber,
      'floor': floor,
      'unit_type': unitType,
      'default_rent': defaultRent,
    });

    await fetchUnits(propertyId);
  }

  Future<void> generateUnits({
    required String propertyId,
    required int floors,
    required int unitsPerFloor,
    String? unitType,
    double? defaultRent,
  }) async {
    final units = <Map<String, dynamic>>[];

    // Generate unit names: A1, A2, A3... B1, B2, B3...
    for (int floor = 0; floor < floors; floor++) {
      final floorLetter = String.fromCharCode(65 + floor); // A, B, C, D...
      for (int unit = 1; unit <= unitsPerFloor; unit++) {
        units.add({
          'property_id': propertyId,
          'unit_number': '$floorLetter$unit',
          'floor': floor + 1,
          'unit_type': unitType,
          'default_rent': defaultRent,
        });
      }
    }

    // Insert all at once
    await _client.from('units').insert(units);
    await fetchUnits(propertyId);
  }

  // ============================================
  // TENANTS
  // ============================================

  Future<void> fetchTenants(String propertyId) async {
    _currentPropertyId = propertyId;
    _loading = true;
    notifyListeners();

    try {
      final data = await _client
          .from('tenants')
          .select()
          .eq('property_id', propertyId)
          .order('name');

      _selectedPropertyTenants = data
          .map((json) => Tenant.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching tenants: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addTenant({
    required String propertyId,
    String? unitId,
    required String name,
    required String phone,
    String? email,
    required double baseRent,
    double serviceCharge = 0,
    double openingBalance = 0,
    DateTime? leaseStart,
    DateTime? leaseEnd,
    bool whatsappEnabled = true,
  }) async {
    await _client.from('tenants').insert({
      'property_id': propertyId,
      'unit_id': unitId,
      'name': name,
      'phone': phone,
      'email': email,
      'base_rent': baseRent,
      'service_charge': serviceCharge,
      'opening_balance': openingBalance,
      'lease_start': leaseStart?.toIso8601String(),
      'lease_end': leaseEnd?.toIso8601String(),
      'whatsapp_enabled': whatsappEnabled,
    });

    // If unit is assigned, ark as occupied
    if (unitId != null) {
      await _client
          .from('units')
          .update({'status': 'occupied'})
          .eq('id', unitId);
    }

    await fetchTenants(propertyId);
  }

  // ============================================
  // PAYMENTS
  // ============================================

  Future<void> fetchPayments(String tenantId) async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _client
          .from('payments')
          .select()
          .eq('tenant_id', tenantId)
          .order('payment_date', ascending: false);

      _selectedTenantPayments = data
          .map((json) => Payment.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recordPayment({
    required String tenantId,
    required double amount,
    required DateTime paymentDate,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    await _client.from('payments').insert({
      'tenant_id': tenantId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
    });

    // Refresh tenants if we have a current property loaded
    if (_currentPropertyId != null) {
      await fetchTenants(_currentPropertyId!);
    }
  }

  // ============================================
  // DASHBOARD / MONEY GAUGE
  // ============================================

  Future<Map<String, double>> getMonthlySummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth =
        DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();

    double expected = 0;
    double received = 0;

    try {
      // Get all tenants for current user across all properties
      final tenantsData = await _client
          .from('tenants')
          .select('base_rent, service_charge, unit_id')
          .not('unit_id', 'is', null);

      for (final t in tenantsData) {
        expected += double.parse((t['base_rent'] ?? 0).toString()) +
            double.parse((t['service_charge'] ?? 0).toString());
      }

      // Get all payments this month
      final paymentsData = await _client
          .from('payments')
          .select('amount')
          .gte('payment_date', startOfMonth)
          .lte('payment_date', endOfMonth);

      for (final p in paymentsData) {
        received += double.parse((p['amount'] ?? 0).toString());
      }
    } catch (e) {
      debugPrint('Error fetching monthly summary: $e');
    }

    return {
      'expected': expected,
      'received': received,
    };
  }
}
