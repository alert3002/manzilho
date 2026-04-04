// Шартҳои намоиши майдонҳо — монанди AddListing.jsx

int? parseRefId(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is Map) return int.tryParse(v['id']?.toString() ?? '');
  return int.tryParse(v.toString());
}

String? propertyNameById(List<Map<String, dynamic>> propertyTypes, int? id) {
  if (id == null) return null;
  for (final p in propertyTypes) {
    if (parseRefId(p['id']) == id) return p['name']?.toString();
  }
  return null;
}

String? dealNameById(List<Map<String, dynamic>> dealTypes, int? id) {
  if (id == null) return null;
  for (final d in dealTypes) {
    if (parseRefId(d['id']) == id) return d['name']?.toString();
  }
  return null;
}

String? cityNameById(List<Map<String, dynamic>> cities, int? id) {
  if (id == null) return null;
  for (final c in cities) {
    if (parseRefId(c['id']) == id) return c['name']?.toString();
  }
  return null;
}

String _normalizeCityLabel(String raw) {
  var s = raw.trim().toLowerCase();
  s = s.replaceFirst(RegExp(r'^г\.?\s*', caseSensitive: false), '');
  s = s.replaceFirst(RegExp(r'^город\s+', caseSensitive: false), '');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.trim();
}

/// ID шаҳр аз справочник бо ҷавоби Nominatim (reverse jsonv2).
int? matchCityIdFromNominatim(Map<String, dynamic> data, List<Map<String, dynamic>> cities) {
  if (cities.isEmpty) return null;

  final cand = <String>[];
  final addr = data['address'];
  if (addr is Map) {
    final m = Map<String, dynamic>.from(addr);
    for (final k in ['city', 'town', 'village', 'municipality', 'city_district']) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) cand.add(v.trim());
    }
  }

  bool sameLabel(String a, String b) => _normalizeCityLabel(a) == _normalizeCityLabel(b);

  for (final c in cities) {
    final id = parseRefId(c['id']);
    final name = (c['name'] ?? '').toString().trim();
    if (id == null || name.isEmpty) continue;
    for (final raw in cand) {
      if (sameLabel(raw, name)) return id;
    }
  }

  for (final c in cities) {
    final id = parseRefId(c['id']);
    final name = (c['name'] ?? '').toString().trim();
    if (id == null || name.length < 3) continue;
    final nn = _normalizeCityLabel(name);
    for (final raw in cand) {
      final nr = _normalizeCityLabel(raw);
      if (nr.contains(nn) || nn.contains(nr)) return id;
    }
  }

  final dn = (data['display_name'] ?? '').toString().toLowerCase();
  if (dn.isNotEmpty) {
    final sorted = [...cities];
    sorted.sort((a, b) {
      final la = (a['name'] ?? '').toString().length;
      final lb = (b['name'] ?? '').toString().length;
      return lb.compareTo(la);
    });
    for (final c in sorted) {
      final id = parseRefId(c['id']);
      final name = (c['name'] ?? '').toString().trim();
      if (id == null || name.length < 2) continue;
      if (dn.contains(name.toLowerCase())) return id;
    }
  }

  return null;
}

bool isCommercialTypeRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  return propertyNameById(propertyTypes, propertyTypeId) == 'Помещение-офисы';
}

bool isDushanbeSelected(List<Map<String, dynamic>> cities, int? cityId) {
  return cityNameById(cities, cityId) == 'Душанбе';
}

bool isRentDealType(List<Map<String, dynamic>> dealTypes, int? dealTypeId) {
  return dealNameById(dealTypes, dealTypeId) == 'Сдаю';
}

bool isRoomsRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  final n = propertyNameById(propertyTypes, propertyTypeId);
  if (n == null) return false;
  return ['Комната', 'Квартира', 'Дом (Хавли)', 'Дача'].contains(n);
}

bool isLandAreaRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  final n = propertyNameById(propertyTypes, propertyTypeId);
  if (n == null) return false;
  return ['Дом (Хавли)', 'Дача', 'Постройки с земельным участком', 'Здание и сооружения'].contains(n);
}

bool isFloorRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  return propertyNameById(propertyTypes, propertyTypeId) == 'Квартира';
}

bool isTotalFloorsRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  final n = propertyNameById(propertyTypes, propertyTypeId);
  return n == 'Квартира' || n == 'Здание и сооружения';
}

bool isRepairRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  final n = propertyNameById(propertyTypes, propertyTypeId);
  if (n == null) return true;
  return !['Постройки с земельным участком', 'Вагончики и прочее'].contains(n);
}

bool isLandPlotType(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  return propertyNameById(propertyTypes, propertyTypeId) == 'Постройки с земельным участком';
}

bool isExtraBuildingsRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  final n = propertyNameById(propertyTypes, propertyTypeId);
  if (n == null) return false;
  return [
    'Здание и сооружения',
    'Постройки с земельным участком',
    'Помещение-офисы',
    'Помещение офисы',
    'Дом (Хавли)',
    'Дача',
  ].contains(n);
}

bool isBathroomRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  final n = propertyNameById(propertyTypes, propertyTypeId);
  if (n == null) return true;
  return !['Постройки с земельным участком', 'Вагончики и прочее', 'Здание и сооружения'].contains(n);
}

bool isElevatorRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  return propertyNameById(propertyTypes, propertyTypeId) == 'Квартира';
}

bool isInventoryRequired(List<Map<String, dynamic>> dealTypes, int? dealTypeId) {
  final n = dealNameById(dealTypes, dealTypeId);
  return n == 'Сниму' || n == 'Сдаю';
}

bool isDocumentTypeRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  final n = propertyNameById(propertyTypes, propertyTypeId);
  if (n == null) return true;
  return !['Вагончики и прочее', 'Комната'].contains(n);
}

bool isInfrastructureRequired(List<Map<String, dynamic>> propertyTypes, int? propertyTypeId) {
  return propertyNameById(propertyTypes, propertyTypeId) != 'Вагончики и прочее';
}
