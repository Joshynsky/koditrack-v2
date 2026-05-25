import '../services/supabase_service.dart';

class UnitGenerator {
  final _client = SupabaseService.client;

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
  }

  Future<void> addSingleUnit({
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
  }
}