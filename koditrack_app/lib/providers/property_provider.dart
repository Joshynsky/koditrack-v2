import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';
import '../models/payment.dart';
import '../services/supabase_service.dart';

class PropertyProvider extends ChangeNotifier {
  final _client = SupabaseService.client;

  List<Property> _properties = [];
  List<Unit> _selectedPropertyUnits = [];
  List<Tenant> _selectedPropertyTenants = [];
  List<Payment> _selectedTenantPayments = [];
  bool _loading = false;
  String? _currentPropertyId;

  // Caches for instant revisits
  final Map<String, List<Unit>> _cachedUnits = {};
  final Map<String, List<Tenant>> _cachedTenants = {};

  List<Property> get properties => _properties;
  List<Unit> get selectedPropertyUnits => _selectedPropertyUnits;
  List<Tenant> get selectedPropertyTenants => _selectedPropertyTenants;
  List<Payment> get selectedTenantPayments => _selectedTenantPayments;
  bool get loading => _loading;

  void invalidateCache(String propertyId) {
    _cachedUnits.remove(propertyId);
    _cachedTenants.remove(propertyId);
  }

  void clearUnits() {
    _selectedPropertyUnits = [];
    _selectedPropertyTenants = [];
    notifyListeners();
  }

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
    String? paymentMethodId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _client.from('properties').insert({
      'name': name,
      'type': type,
      'address': address,
      'user_id': userId,
      'rent_due_day': rentDueDay,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
    });
    await fetchProperties();
  }

  Future<void> updateProperty({
    required String id,
    required String name,
    String? type,
    String? address,
    int rentDueDay = 5,
    String? paymentMethodId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');
    await _client.from('properties').update({
      'name': name,
      'type': type,
      'address': address,
      'rent_due_day': rentDueDay,
      'payment_method_id': paymentMethodId,
    }).eq('id', id).eq('user_id', userId);
    await fetchProperties();
  }

  Future<void> fetchUnits(String propertyId) async {
    if (_cachedUnits.containsKey(propertyId)) {
      _selectedPropertyUnits = List.from(_cachedUnits[propertyId]!);
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    try {
      final data = await _client.from('units').select()
          .eq('property_id', propertyId).order('unit_number');
      _selectedPropertyUnits = data.map((json) => Unit.fromJson(json)).toList();
      _cachedUnits[propertyId] = List.from(_selectedPropertyUnits);
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
    String? block,
    int? floor,
    String? unitType,
    double? defaultRent,
  }) async {
    await _client.from('units').insert({
      'property_id': propertyId,
      'unit_number': unitNumber,
      'block': block,
      'floor': floor,
      'unit_type': unitType,
      'default_rent': defaultRent,
    });
    invalidateCache(propertyId);
    await fetchUnits(propertyId);
  }

  Future<void> generateBlockUnits({
    required String propertyId,
    required int blocks,
    required int floors,
    required int unitsPerFloor,
    String? unitType,
    double? defaultRent,
  }) async {
    final units = <Map<String, dynamic>>[];
    
    for (int block = 0; block < blocks; block++) {
      final blockLetter = String.fromCharCode(65 + block);
      for (int floor = 0; floor < floors; floor++) {
        final floorLetter = String.fromCharCode(65 + floor);
        for (int unit = 1; unit <= unitsPerFloor; unit++) {
          units.add({
            'property_id': propertyId,
            'block': blockLetter,
            'unit_number': '$floorLetter$unit',
            'floor': floor + 1,
            'unit_type': unitType,
            'default_rent': defaultRent,
          });
        }
      }
    }
    
    await _client.from('units').insert(units);
    invalidateCache(propertyId);
    await fetchUnits(propertyId);
  }

  Future<void> generateCustomUnits({
    required String propertyId,
    required List<Map<String, dynamic>> floorConfigs,
  }) async {
    final units = <Map<String, dynamic>>[];
    
    for (final config in floorConfigs) {
      final block = config['block'] as String?;
      final floor = config['floor'] as int;
      final count = config['count'] as int;
      final unitType = config['unit_type'] as String?;
      final defaultRent = config['default_rent'] as double?;
      final floorLabel = config['floor_label'] as String? ?? floor.toString();
      
      for (int unit = 1; unit <= count; unit++) {
        units.add({
          'property_id': propertyId,
          'block': block,
          'unit_number': '$floorLabel$unit',
          'floor': floor,
          'unit_type': unitType,
          'default_rent': defaultRent,
        });
      }
    }
    
    await _client.from('units').insert(units);
    invalidateCache(propertyId);
    await fetchUnits(propertyId);
  }

  Future<void> fetchTenants(String propertyId) async {
    if (_cachedTenants.containsKey(propertyId)) {
      _selectedPropertyTenants = List.from(_cachedTenants[propertyId]!);
      _currentPropertyId = propertyId;
      notifyListeners();
      return;
    }

    _currentPropertyId = propertyId;
    _loading = true;
    notifyListeners();
    try {
      final data = await _client.from('tenants').select()
          .eq('property_id', propertyId).order('name');
      _selectedPropertyTenants = data.map((json) => Tenant.fromJson(json)).toList();
      _cachedTenants[propertyId] = List.from(_selectedPropertyTenants);
    } catch (e) {
      debugPrint('Error fetching tenants: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addTenant({
    required String propertyId, String? unitId,
    required String name, required String phone,
    String? email, required double baseRent,
    double serviceCharge = 0, double openingBalance = 0,
    DateTime? leaseStart, DateTime? leaseEnd,
    bool whatsappEnabled = true,
  }) async {
    await _client.from('tenants').insert({
      'property_id': propertyId, 'unit_id': unitId,
      'name': name, 'phone': phone, 'email': email,
      'base_rent': baseRent, 'service_charge': serviceCharge,
      'opening_balance': openingBalance,
      'lease_start': leaseStart?.toIso8601String(),
      'lease_end': leaseEnd?.toIso8601String(),
      'whatsapp_enabled': whatsappEnabled,
    });
    if (unitId != null) {
      await _client.from('units').update({'status': 'occupied'}).eq('id', unitId);
    }
    invalidateCache(propertyId);
    await fetchTenants(propertyId);
  }

  Future<void> fetchPayments(String tenantId) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _client.from('payments').select()
          .eq('tenant_id', tenantId).order('payment_date', ascending: false);
      _selectedTenantPayments = data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recordPayment({
    required String tenantId, required double amount,
    required DateTime paymentDate, String? paymentMethod,
    String? reference, String? notes,
  }) async {
    await _client.from('payments').insert({
      'tenant_id': tenantId, 'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference': reference, 'notes': notes,
    });
    if (_currentPropertyId != null) {
      invalidateCache(_currentPropertyId!);
      await fetchTenants(_currentPropertyId!);
    }
  }

  Future<Map<String, double>> getMonthlySummary() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();
    double expected = 0;
    double received = 0;
    try {
      final tenantsData = await _client.from('tenants')
          .select('base_rent, service_charge, unit_id')
          .not('unit_id', 'is', null);
      for (final t in tenantsData) {
        expected += double.parse((t['base_rent'] ?? 0).toString()) +
            double.parse((t['service_charge'] ?? 0).toString());
      }
      final paymentsData = await _client.from('payments')
          .select('amount')
          .gte('payment_date', startOfMonth)
          .lte('payment_date', endOfMonth);
      for (final p in paymentsData) {
        received += double.parse((p['amount'] ?? 0).toString());
      }
    } catch (e) {
      debugPrint('Error fetching monthly summary: $e');
    }
    return {'expected': expected, 'received': received};
  }

  Future<void> fetchAllPayments() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await _client
          .from('payments')
          .select('*, tenants(name)')
          .order('payment_date', ascending: false)
          .limit(50);
      _selectedTenantPayments = data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all payments: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}