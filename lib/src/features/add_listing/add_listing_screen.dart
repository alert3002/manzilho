import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../core/post_auth_redirect.dart';
import 'add_listing_conditions.dart';

class _ExistingPhoto {
  _ExistingPhoto({required this.id, required this.url});
  final int id;
  final String url;
}

/// Фото аз галерея — байтҳо (дар Web `Image.file` нест).
class _PickedImage {
  _PickedImage({required this.bytes, required this.filename});
  final Uint8List bytes;
  final String filename;
}

/// Монанди веб: қадами 1 = навъи амалиёт, қадами 2 = формаи пурра + харита.
class AddListingScreen extends StatefulWidget {
  const AddListingScreen({super.key, this.editListingId});
  final int? editListingId;

  @override
  State<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();
  final _geoDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
    headers: {'User-Agent': 'ManzilhoMobile/1.0 (https://manzilho.tj)'},
  ));

  int _step = 1;
  bool _loading = true;
  String? _loadError;
  String? _role;
  int? _listingLimit;
  int? _listingCount;
  bool _unauthenticated = false;
  String _photoErr = '';
  String? _submitErr;
  bool _submitting = false;

  LatLng _mapPoint = const LatLng(38.5598, 68.7870);

  // Справочники
  List<Map<String, dynamic>> _dealTypes = [];
  List<Map<String, dynamic>> _propertyTypes = [];
  List<Map<String, dynamic>> _landCategories = [];
  List<Map<String, dynamic>> _commercialCategories = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _mahallas = [];
  List<Map<String, dynamic>> _roomOptions = [];
  List<Map<String, dynamic>> _floorOptions = [];
  List<Map<String, dynamic>> _totalFloorsOptions = [];
  List<Map<String, dynamic>> _tenantPreferences = [];
  List<Map<String, dynamic>> _renovations = [];
  List<Map<String, dynamic>> _conditions = [];
  List<Map<String, dynamic>> _extraBuildingsList = [];
  List<Map<String, dynamic>> _bathrooms = [];
  List<Map<String, dynamic>> _elevators = [];
  List<Map<String, dynamic>> _inventoriesList = [];
  List<Map<String, dynamic>> _documentTypes = [];
  List<Map<String, dynamic>> _wallMaterials = [];
  List<Map<String, dynamic>> _balconies = [];
  List<Map<String, dynamic>> _windowViews = [];
  List<Map<String, dynamic>> _garbageChutes = [];
  List<Map<String, dynamic>> _electricities = [];
  List<Map<String, dynamic>> _waters = [];
  List<Map<String, dynamic>> _sewages = [];
  List<Map<String, dynamic>> _heatings = [];
  List<Map<String, dynamic>> _topTariffs = [];

  // Форма
  int? _dealTypeId;
  int? _propertyTypeId;
  String? _landTypeKey;
  String? _commercialKey;
  String? _tenantPrefKey;
  int? _roomsId;
  int? _floorId;
  int? _floorsInBuildingId;
  int? _cityId;
  int? _mahallaId;
  int? _conditionId;
  int? _repairId;
  int? _bathroomId;
  int? _elevatorId;
  int? _documentTypeId;
  int? _wallMaterialId;
  int? _balconyId;
  int? _windowViewId;
  int? _garbageChuteId;
  int? _electricityId;
  int? _waterId;
  int? _sewageId;
  int? _heatingId;
  final _areaTotalCtrl = TextEditingController();
  final _areaLandCtrl = TextEditingController();
  final _constructionYearCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '38.5598');
  final _lngCtrl = TextEditingController(text: '68.7870');
  bool _priceTypeFixed = true;
  String _negotiationStatus = 'negotiable';
  bool _hasWhatsapp = false;
  bool _hasTelegram = false;
  final List<int> _extraBuildingIds = [];
  final List<int> _inventoryIds = [];
  String _tariffType = 'usual';
  int? _topTariffId;

  final List<_PickedImage> _newPicked = [];
  final List<_ExistingPhoto> _existingPhotos = [];
  final Set<int> _removedExistingIds = {};

  @override
  void dispose() {
    _areaTotalCtrl.dispose();
    _areaLandCtrl.dispose();
    _constructionYearCtrl.dispose();
    _priceCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.editListingId != null) _step = 2;
    _bootstrap();
  }

  List<Map<String, dynamic>> _mapList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).where((m) => m.isNotEmpty).toList();
  }

  List<DropdownMenuItem<int>> _itemsInt(List<Map<String, dynamic>> list, String labelKey) {
    final out = <DropdownMenuItem<int>>[];
    for (final e in list) {
      final id = parseRefId(e['id']);
      if (id == null) continue;
      out.add(DropdownMenuItem(value: id, child: Text((e[labelKey] ?? '').toString(), overflow: TextOverflow.ellipsis)));
    }
    return out;
  }

  List<DropdownMenuItem<String>> _itemsStr(List<Map<String, dynamic>> list) {
    final out = <DropdownMenuItem<String>>[];
    for (final e in list) {
      final id = e['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      out.add(DropdownMenuItem(value: id, child: Text((e['name'] ?? id).toString(), overflow: TextOverflow.ellipsis)));
    }
    return out;
  }

  void _syncMahallas() {
    _mahallas = [];
    if (_cityId == null) return;
    for (final c in _cities) {
      if (parseRefId(c['id']) == _cityId) {
        final m = c['mahallas'];
        if (m is List) {
          _mahallas = m.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).where((x) => x.isNotEmpty).toList();
        }
        break;
      }
    }
    if (!isDushanbeSelected(_cities, _cityId)) _mahallaId = null;
  }

  Future<void> _fetchCityCenter() async {
    final name = cityNameById(_cities, _cityId);
    if (name == null || name.isEmpty) return;
    try {
      final r = await _geoDio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {'format': 'jsonv2', 'q': '$name, Tajikistan'},
      );
      if (r.data is! List || (r.data as List).isEmpty) return;
      final first = (r.data as List).first;
      if (first is! Map) return;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return;
      if (!mounted) return;
      final ll = LatLng(lat, lon);
      setState(() {
        _mapPoint = ll;
        _latCtrl.text = lat.toStringAsFixed(6);
        _lngCtrl.text = lon.toStringAsFixed(6);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(ll, 13);
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final r = await _geoDio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'format': 'jsonv2', 'lat': '$lat', 'lon': '$lon'},
      );
      if (r.data is! Map || !mounted) return;
      final data = Map<String, dynamic>.from(r.data as Map);
      final displayName = data['display_name'];
      final matchedCityId = matchCityIdFromNominatim(data, _cities);
      setState(() {
        if (displayName != null) {
          _addressCtrl.text = displayName.toString();
        }
        if (matchedCityId != null) {
          _cityId = matchedCityId;
          _syncMahallas();
        }
      });
    } catch (_) {}
  }

  void _adjustMapZoom(double delta) {
    try {
      final cam = _mapController.camera;
      final minZ = cam.minZoom ?? 3.0;
      final maxZ = cam.maxZoom ?? 19.0;
      final nz = (cam.zoom + delta).clamp(minZ, maxZ);
      _mapController.move(cam.center, nz);
    } catch (_) {}
  }

  Future<void> _goToMyLocation() async {
    if (!mounted) return;
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Включите геолокацию в настройках устройства')),
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Разрешите доступ к местоположению в настройках приложения')),
          );
        }
        return;
      }
      if (perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Без доступа к геолокации нельзя определить место на карте')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _mapPoint = ll;
        _latCtrl.text = ll.latitude.toStringAsFixed(6);
        _lngCtrl.text = ll.longitude.toStringAsFixed(6);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(ll, 15);
        } catch (_) {}
      });
      _reverseGeocode(ll.latitude, ll.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось получить местоположение: $e')),
        );
      }
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _unauthenticated = false;
    });
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _unauthenticated = true;
        _loading = false;
      });
      return;
    }

    try {
      final meRes = await dio.get('/api/auth/me/');
      final me = meRes.data is Map ? Map<String, dynamic>.from(meRes.data as Map) : <String, dynamic>{};
      setState(() {
        _role = (me['role'] ?? '').toString().toLowerCase();
        _listingLimit = me['listing_limit'] is num ? (me['listing_limit'] as num).toInt() : int.tryParse(me['listing_limit']?.toString() ?? '');
        _listingCount = me['listing_count'] is num ? (me['listing_count'] as num).toInt() : int.tryParse(me['listing_count']?.toString() ?? '');
      });

      final res = await Future.wait([
        dio.get('/api/listings/deal-types/'),
        dio.get('/api/listings/property-types/'),
        dio.get('/api/listings/land-categories/'),
        dio.get('/api/listings/commercial-categories/'),
        dio.get('/api/listings/cities/'),
        dio.get('/api/listings/room-options/'),
        dio.get('/api/listings/floor-options/'),
        dio.get('/api/listings/total-floors-options/'),
        dio.get('/api/listings/tenant-preferences/'),
        dio.get('/api/listings/renovations/'),
        dio.get('/api/listings/conditions/'),
        dio.get('/api/listings/extra-buildings/'),
        dio.get('/api/listings/bathrooms/'),
        dio.get('/api/listings/elevators/'),
        dio.get('/api/listings/inventories/'),
        dio.get('/api/listings/document-types/'),
        dio.get('/api/listings/wall-materials/'),
        dio.get('/api/listings/balconies/'),
        dio.get('/api/listings/window-views/'),
        dio.get('/api/listings/garbage-chutes/'),
        dio.get('/api/listings/electricities/'),
        dio.get('/api/listings/waters/'),
        dio.get('/api/listings/sewages/'),
        dio.get('/api/listings/heatings/'),
        dio.get('/api/listings/top-tariffs/'),
      ]);

      if (!mounted) return;
      setState(() {
        _dealTypes = _mapList(res[0].data);
        _propertyTypes = _mapList(res[1].data);
        _landCategories = _mapList(res[2].data);
        _commercialCategories = _mapList(res[3].data);
        _cities = _mapList(res[4].data);
        _roomOptions = _mapList(res[5].data);
        _floorOptions = _mapList(res[6].data);
        _totalFloorsOptions = _mapList(res[7].data);
        _tenantPreferences = _mapList(res[8].data);
        _renovations = _mapList(res[9].data);
        _conditions = _mapList(res[10].data);
        _extraBuildingsList = _mapList(res[11].data);
        _bathrooms = _mapList(res[12].data);
        _elevators = _mapList(res[13].data);
        _inventoriesList = _mapList(res[14].data);
        _documentTypes = _mapList(res[15].data);
        _wallMaterials = _mapList(res[16].data);
        _balconies = _mapList(res[17].data);
        _windowViews = _mapList(res[18].data);
        _garbageChutes = _mapList(res[19].data);
        _electricities = _mapList(res[20].data);
        _waters = _mapList(res[21].data);
        _sewages = _mapList(res[22].data);
        _heatings = _mapList(res[23].data);
        _topTariffs = _mapList(res[24].data);
      });

      final eid = widget.editListingId;
      if (eid != null) {
        final detail = await dio.get('/api/listings/$eid/');
        if (!mounted) return;
        final d = detail.data is Map ? Map<String, dynamic>.from(detail.data as Map) : <String, dynamic>{};
        setState(() => _applyDetail(d));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await setAccessToken(null);
        setState(() {
          _unauthenticated = true;
          _loading = false;
        });
        return;
      }
      setState(() {
        _loadError = e.response?.data is Map ? (e.response!.data as Map)['detail']?.toString() : e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = '$e';
        _loading = false;
      });
    }

    if (mounted) setState(() => _loading = false);
    if (mounted && _cityId != null) _fetchCityCenter();
  }

  void _applyDetail(Map<String, dynamic> d) {
    int? id(dynamic v) => parseRefId(v);

    _dealTypeId = id(d['deal_type']);
    _propertyTypeId = id(d['property_type']);
    _landTypeKey = d['land_type']?.toString();
    _commercialKey = d['commercial_type']?.toString();
    _cityId = id(d['city']);
    _mahallaId = id(d['mahalla']);
    _roomsId = id(d['rooms']);
    _floorId = id(d['floor']);
    _floorsInBuildingId = id(d['floors_in_building']);
    _conditionId = id(d['condition']);
    _repairId = id(d['repair']);
    _bathroomId = id(d['bathroom']);
    _elevatorId = id(d['elevator']);
    _documentTypeId = id(d['document_type']);
    _wallMaterialId = id(d['wall_material']);
    _balconyId = id(d['balcony']);
    _windowViewId = id(d['window_view']);
    _garbageChuteId = id(d['garbage_chute']);
    _electricityId = id(d['electricity']);
    _waterId = id(d['water']);
    _sewageId = id(d['sewage']);
    _heatingId = id(d['heating']);
    _tenantPrefKey = d['tenant_preference']?.toString();
    _negotiationStatus = (d['negotiation_status'] ?? 'negotiable').toString();
    _hasWhatsapp = d['has_whatsapp'] == true;
    _hasTelegram = d['has_telegram'] == true;

    _areaTotalCtrl.text = d['area_total'] != null ? d['area_total'].toString() : '';
    _areaLandCtrl.text = d['area_land'] != null ? d['area_land'].toString() : '';
    _constructionYearCtrl.text = d['construction_year'] != null ? d['construction_year'].toString() : '';
    _priceCtrl.text = d['price'] != null ? d['price'].toString() : '';
    _addressCtrl.text = (d['address'] ?? '').toString();
    _descriptionCtrl.text = (d['description'] ?? '').toString();
    if (d['latitude'] != null) _latCtrl.text = d['latitude'].toString();
    if (d['longitude'] != null) _lngCtrl.text = d['longitude'].toString();

    _extraBuildingIds.clear();
    if (d['extra_buildings'] is List) {
      for (final x in d['extra_buildings'] as List) {
        final i = parseRefId(x is Map ? x['id'] : x);
        if (i != null) _extraBuildingIds.add(i);
      }
    }
    _inventoryIds.clear();
    if (d['inventory'] is List) {
      for (final x in d['inventory'] as List) {
        final i = parseRefId(x is Map ? x['id'] : x);
        if (i != null) _inventoryIds.add(i);
      }
    }

    _existingPhotos.clear();
    _removedExistingIds.clear();
    final imgs = d['images'];
    if (imgs is List) {
      for (final e in imgs) {
        if (e is! Map) continue;
        final pid = int.tryParse(e['id']?.toString() ?? '');
        final path = e['image']?.toString();
        if (pid != null && path != null && path.isNotEmpty) {
          _existingPhotos.add(_ExistingPhoto(id: pid, url: path));
        }
      }
    }

    if (d['latitude'] != null && d['longitude'] != null) {
      final la = double.tryParse(d['latitude'].toString());
      final lo = double.tryParse(d['longitude'].toString());
      if (la != null && lo != null) _mapPoint = LatLng(la, lo);
    }

    _topTariffId = id(d['top_tariff']);
    _tariffType = 'usual';

    _syncMahallas();
  }

  bool get _limitReached {
    final r = (_role ?? '').toLowerCase();
    if (r != 'owner' && r != 'agent' && r != 'agency') return false;
    if (_listingLimit == null || _listingCount == null || widget.editListingId != null) return false;
    return _listingCount! >= _listingLimit!;
  }

  int get _photoCount => _existingPhotos.where((p) => !_removedExistingIds.contains(p.id)).length + _newPicked.length;

  Future<void> _pickPhotos() async {
    if (_photoCount >= 10) {
      setState(() => _photoErr = 'До 10 фото');
      return;
    }
    final files = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (!mounted || files.isEmpty) return;
    final next = <_PickedImage>[..._newPicked];
    for (final f in files) {
      if (next.length + _existingPhotos.where((p) => !_removedExistingIds.contains(p.id)).length >= 10) break;
      final bytes = await f.readAsBytes();
      var name = f.name.trim();
      if (name.isEmpty) name = 'photo_${next.length + 1}.jpg';
      next.add(_PickedImage(bytes: bytes, filename: name));
    }
    if (!mounted) return;
    setState(() {
      _photoErr = '';
      _newPicked
        ..clear()
        ..addAll(next);
    });
  }

  String? _validate() {
    if (_dealTypeId == null) return 'Выберите тип сделки (шаг 1)';
    if (_propertyTypeId == null) return 'Выберите вид объекта';
    if (isLandPlotType(_propertyTypes, _propertyTypeId) && (_landTypeKey == null || _landTypeKey!.isEmpty)) {
      return 'Выберите тип участка';
    }
    if (isCommercialTypeRequired(_propertyTypes, _propertyTypeId) && (_commercialKey == null || _commercialKey!.isEmpty)) {
      return 'Выберите вид помещения';
    }
    if (isRentDealType(_dealTypes, _dealTypeId) && (_tenantPrefKey == null || _tenantPrefKey!.isEmpty)) {
      return 'Укажите, кому сдаётся';
    }
    if (isRoomsRequired(_propertyTypes, _propertyTypeId) && _roomsId == null) return 'Укажите количество комнат';
    if (isFloorRequired(_propertyTypes, _propertyTypeId) && _floorId == null) return 'Укажите этаж';
    if (isTotalFloorsRequired(_propertyTypes, _propertyTypeId) && _floorsInBuildingId == null) {
      return 'Укажите этажность дома';
    }
    if (_areaTotalCtrl.text.trim().isEmpty) return 'Укажите площадь (м²)';
    if (isLandAreaRequired(_propertyTypes, _propertyTypeId) && _areaLandCtrl.text.trim().isEmpty) {
      return 'Укажите площадь участка (соток)';
    }
    if (_constructionYearCtrl.text.trim().isEmpty) return 'Укажите год постройки';
    if (_conditionId == null) return 'Выберите состояние дома';
    if (isRepairRequired(_propertyTypes, _propertyTypeId) && _repairId == null) return 'Выберите ремонт';
    if (isBathroomRequired(_propertyTypes, _propertyTypeId) && _bathroomId == null) return 'Выберите санузел';
    if (isElevatorRequired(_propertyTypes, _propertyTypeId) && _elevatorId == null) return 'Укажите лифт';
    if (isDocumentTypeRequired(_propertyTypes, _propertyTypeId) && _documentTypeId == null) {
      return 'Выберите наличие документов';
    }
    if (_cityId == null) return 'Выберите город';
    if (isDushanbeSelected(_cities, _cityId) && _mahallaId == null) return 'Выберите махаллю';
    final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.'));
    if (lat == null || lng == null) return 'Укажите точку на карте';
    if (_descriptionCtrl.text.trim().isEmpty) return 'Введите описание';
    if (_priceTypeFixed) {
      final p = int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'\s'), ''));
      if (p == null || p < 0) return 'Укажите цену';
    }
    if (widget.editListingId == null && _photoCount == 0) return 'Добавьте хотя бы одно фото';
    if (_tariffType == 'top' && _topTariffId == null) return 'Выберите тариф ТОП';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _submitErr = err);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() {
      _submitErr = null;
      _submitting = true;
    });

    final wantTop = _tariffType == 'top' && _topTariffId != null;
    final topKeep = _topTariffId;

    try {
      final form = FormData();
      void add(String k, String v) => form.fields.add(MapEntry(k, v));
      void addIf(String k, dynamic v) {
        if (v == null) return;
        if (v is bool) {
          add(k, v ? 'true' : 'false');
          return;
        }
        final s = v.toString();
        if (s.isEmpty) return;
        add(k, s);
      }

      if (_dealTypeId != null) add('deal_type', '$_dealTypeId');
      if (_propertyTypeId != null) add('property_type', '$_propertyTypeId');
      addIf('land_type', _landTypeKey);
      addIf('commercial_type', _commercialKey);
      addIf('city', _cityId);
      addIf('mahalla', _mahallaId);
      addIf('rooms', _roomsId);
      addIf('floor', _floorId);
      addIf('floors_in_building', _floorsInBuildingId);
      addIf('area_total', _areaTotalCtrl.text.trim().replaceAll(',', '.'));
      addIf('area_land', _areaLandCtrl.text.trim().replaceAll(',', '.'));
      addIf('construction_year', _constructionYearCtrl.text.trim());
      addIf('condition', _conditionId);
      addIf('repair', _repairId);
      addIf('bathroom', _bathroomId);
      addIf('elevator', _elevatorId);
      addIf('document_type', _documentTypeId);
      addIf('wall_material', _wallMaterialId);
      addIf('balcony', _balconyId);
      addIf('window_view', _windowViewId);
      addIf('garbage_chute', _garbageChuteId);
      addIf('electricity', _electricityId);
      addIf('water', _waterId);
      addIf('sewage', _sewageId);
      addIf('heating', _heatingId);
      addIf('tenant_preference', _tenantPrefKey);
      add('negotiation_status', _negotiationStatus);
      addIf('has_whatsapp', _hasWhatsapp);
      addIf('has_telegram', _hasTelegram);
      addIf('address', _addressCtrl.text.trim());
      addIf('description', _descriptionCtrl.text.trim());
      addIf('latitude', _latCtrl.text.trim().replaceAll(',', '.'));
      addIf('longitude', _lngCtrl.text.trim().replaceAll(',', '.'));

      if (_priceTypeFixed) {
        add('price', _priceCtrl.text.replaceAll(RegExp(r'\s'), ''));
      } else {
        add('price', '0');
      }

      for (final id in _extraBuildingIds) {
        form.fields.add(MapEntry('extra_buildings', '$id'));
      }
      for (final id in _inventoryIds) {
        form.fields.add(MapEntry('inventory', '$id'));
      }

      for (final p in _newPicked) {
        form.files.add(
          MapEntry(
            'uploaded_images',
            MultipartFile.fromBytes(p.bytes, filename: p.filename),
          ),
        );
      }

      final eid = widget.editListingId;
      if (eid != null) {
        for (final rid in _removedExistingIds) {
          form.fields.add(MapEntry('remove_image_ids', '$rid'));
        }
        await dio.patch('/api/listings/$eid/update/', data: form);
        if (!mounted) return;
        if (wantTop && topKeep != null) {
          try {
            await dio.post('/api/listings/$eid/upgrade-top/', data: {'top_tariff_id': '$topKeep'});
          } on DioException catch (e2) {
            final c = e2.response?.data is Map ? (e2.response!.data as Map)['code'] : null;
            if (c == 'insufficient_balance' && mounted) {
              context.push('/balance');
              return;
            }
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Объявление сохранено')));
        context.pop();
      } else {
        final res = await dio.post('/api/listings/create/', data: form);
        final newId = res.data is Map ? int.tryParse((res.data as Map)['id']?.toString() ?? '') : null;
        if (!mounted) return;
        if (wantTop && topKeep != null && newId != null) {
          try {
            await dio.post('/api/listings/$newId/upgrade-top/', data: {'top_tariff_id': '$topKeep'});
          } on DioException catch (e2) {
            final c = e2.response?.data is Map ? (e2.response!.data as Map)['code'] : null;
            if (c == 'insufficient_balance' && mounted) {
              context.push('/balance');
              return;
            }
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Объявление создано')));
        if (newId != null) {
          context.go('/listings/$newId');
        } else {
          context.go('/profile');
        }
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        msg = data['detail']?.toString() ?? data['error']?.toString();
        for (final v in data.values) {
          if (msg != null) break;
          if (v is String) msg = v;
          if (v is List && v.isNotEmpty && v.first is String) msg = v.first as String;
        }
      }
      setState(() => _submitErr = msg ?? 'Ошибка отправки');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_submitErr!)));
    } catch (e) {
      setState(() => _submitErr = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goBack() {
    if (widget.editListingId != null) {
      context.pop();
    } else {
      setState(() => _step = 1);
    }
  }

  void _onCityChanged(int? v) {
    setState(() {
      _cityId = v;
      _mahallaId = null;
      _syncMahallas();
    });
    _fetchCityCenter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0a0a0a) : const Color(0xFFF8FAFC);
    final card = isDark ? const Color(0xFF171717) : Colors.white;
    final border = isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final text = isDark ? const Color(0xFFe5e7eb) : const Color(0xFF111827);
    final muted = isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    const brand = Color(0xFFE79A3E);

    if (_unauthenticated) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Войдите в кабинет.', style: TextStyle(color: text, fontSize: 16)),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.go(profilePathForLogin(returnTo: '/add')),
                    style: FilledButton.styleFrom(backgroundColor: brand, foregroundColor: Colors.white),
                    child: const Text('Кабинет'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_loading) return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator()));

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, foregroundColor: text, title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(padding: const EdgeInsets.all(24), child: Text(_loadError!, textAlign: TextAlign.center)),
              FilledButton(onPressed: _bootstrap, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }

    final rl = (_role ?? '').toLowerCase();
    if (rl == 'user') {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, foregroundColor: text, title: const Text('Добавить')),
        body: _noAccess(text, muted, 'У роли «Пользователь» нет доступа к добавлению объявлений.'),
      );
    }

    if (_limitReached) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(backgroundColor: bg, foregroundColor: text, title: const Text('Лимит')),
        body: _noAccess(text, muted, 'Лимит объявлений достигнут ($_listingCount/$_listingLimit).'),
      );
    }

    if (_step == 1) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _dealTypes.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: border),
                  itemBuilder: (_, i) {
                    final t = _dealTypes[i];
                    final id = parseRefId(t['id']);
                    final name = (t['name'] ?? '').toString();
                    return ListTile(
                      title: Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: text, fontWeight: FontWeight.w500)),
                      onTap: id == null ? null : () => setState(() {
                        _dealTypeId = id;
                        _step = 2;
                      }),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: IconButton(
                  iconSize: 32,
                  color: muted,
                  icon: const Icon(Icons.close),
                  onPressed: () => context.go('/'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // step 2
    InputDecoration deco(String l) => InputDecoration(
          labelText: l,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          labelStyle: TextStyle(color: muted),
        );

    Widget sec(String title, List<Widget> ch) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text)),
                ],
              ),
              const SizedBox(height: 14),
              ...ch,
            ],
          ),
        );

    Widget ddInt(String label, int? val, List<DropdownMenuItem<int>> items, ValueChanged<int?> onCh, {bool nullOk = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<int>(
          key: ValueKey<Object?>('dd-int-$label-$val-${items.length}-$nullOk'),
          initialValue: val,
          isExpanded: true,
          decoration: deco(label),
          dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
          style: TextStyle(color: text, fontSize: 14),
          items: [
            if (nullOk) DropdownMenuItem<int>(value: null, child: Text('—', style: TextStyle(color: muted))),
            ...items,
          ],
          onChanged: onCh,
        ),
      );
    }

    Widget ddStr(String label, String? val, List<DropdownMenuItem<String>> items, ValueChanged<String?> onCh, {bool nullOk = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          key: ValueKey<Object?>('dd-str-$label-$val-${items.length}-$nullOk'),
          initialValue: val,
          isExpanded: true,
          decoration: deco(label),
          dropdownColor: isDark ? const Color(0xFF262626) : Colors.white,
          style: TextStyle(color: text, fontSize: 14),
          items: [
            if (nullOk) DropdownMenuItem<String>(value: null, child: Text('—', style: TextStyle(color: muted))),
            ...items,
          ],
          onChanged: onCh,
        ),
      );
    }

    final pType = _propertyTypeId;
    final dType = _dealTypeId;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: text,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
        title: Text(widget.editListingId != null ? 'Редактирование' : 'Детали объявления'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sec('Вид объекта', [
              ddInt('Вид объектов *', pType, _itemsInt(_propertyTypes, 'name'), (v) => setState(() => _propertyTypeId = v)),
              if (isLandPlotType(_propertyTypes, pType))
                ddStr('Тип участка *', _landTypeKey, _itemsStr(_landCategories), (v) => setState(() => _landTypeKey = v)),
              if (isCommercialTypeRequired(_propertyTypes, pType))
                ddStr('Вид помещения *', _commercialKey, _itemsStr(_commercialCategories), (v) => setState(() => _commercialKey = v)),
              if (isRentDealType(_dealTypes, dType))
                ddStr('Кому сдаётся *', _tenantPrefKey, _itemsStr(_tenantPreferences), (v) => setState(() => _tenantPrefKey = v)),
              if (isRoomsRequired(_propertyTypes, pType))
                ddInt('Комнат *', _roomsId, _itemsInt(_roomOptions, 'value'), (v) => setState(() => _roomsId = v)),
              if (isFloorRequired(_propertyTypes, pType))
                ddInt('Этаж *', _floorId, _itemsInt(_floorOptions, 'value'), (v) => setState(() => _floorId = v)),
              if (isTotalFloorsRequired(_propertyTypes, pType))
                ddInt('Этажность дома *', _floorsInBuildingId, _itemsInt(_totalFloorsOptions, 'value'), (v) => setState(() => _floorsInBuildingId = v)),
              TextField(
                controller: _areaTotalCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: text),
                decoration: deco('Площадь (м²) *'),
              ),
              if (isLandAreaRequired(_propertyTypes, pType)) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _areaLandCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: text),
                  decoration: deco('Площадь участка (соток) *'),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _constructionYearCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: text),
                decoration: deco('Год постройки *'),
              ),
              const SizedBox(height: 12),
              ddInt('Состояние дома *', _conditionId, _itemsInt(_conditions, 'name'), (v) => setState(() => _conditionId = v)),
              if (isRepairRequired(_propertyTypes, pType)) ...[
                const SizedBox(height: 12),
                ddInt('Ремонт *', _repairId, _itemsInt(_renovations, 'name'), (v) => setState(() => _repairId = v)),
              ],
              if (isBathroomRequired(_propertyTypes, pType)) ...[
                const SizedBox(height: 12),
                ddInt('Санузел *', _bathroomId, _itemsInt(_bathrooms, 'name'), (v) => setState(() => _bathroomId = v)),
              ],
              if (isElevatorRequired(_propertyTypes, pType)) ...[
                const SizedBox(height: 12),
                ddInt('Лифт *', _elevatorId, _itemsInt(_elevators, 'name'), (v) => setState(() => _elevatorId = v)),
              ],
              if (isExtraBuildingsRequired(_propertyTypes, pType)) ...[
                const SizedBox(height: 8),
                Text('Доп. постройки', style: TextStyle(color: muted, fontSize: 13)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _extraBuildingsList.map((opt) {
                    final id = parseRefId(opt['id']);
                    if (id == null) return const SizedBox.shrink();
                    final sel = _extraBuildingIds.contains(id);
                    return FilterChip(
                      label: Text(opt['name']?.toString() ?? '', style: TextStyle(fontSize: 12, color: text)),
                      selected: sel,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _extraBuildingIds.add(id);
                        } else {
                          _extraBuildingIds.remove(id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
              if (isInventoryRequired(_dealTypes, dType)) ...[
                const SizedBox(height: 8),
                Text('Инвентарь', style: TextStyle(color: muted, fontSize: 13)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _inventoriesList.map((opt) {
                    final id = parseRefId(opt['id']);
                    if (id == null) return const SizedBox.shrink();
                    final sel = _inventoryIds.contains(id);
                    return FilterChip(
                      label: Text(opt['name']?.toString() ?? '', style: TextStyle(fontSize: 12, color: text)),
                      selected: sel,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _inventoryIds.add(id);
                        } else {
                          _inventoryIds.remove(id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
              if (isInfrastructureRequired(_propertyTypes, pType)) ...[
                const SizedBox(height: 12),
                ddInt('Материал стен', _wallMaterialId, _itemsInt(_wallMaterials, 'name'), (v) => setState(() => _wallMaterialId = v), nullOk: true),
                ddInt('Балкон', _balconyId, _itemsInt(_balconies, 'name'), (v) => setState(() => _balconyId = v), nullOk: true),
                ddInt('Мусоропровод', _garbageChuteId, _itemsInt(_garbageChutes, 'name'), (v) => setState(() => _garbageChuteId = v), nullOk: true),
                ddInt('Куда смотрят окна', _windowViewId, _itemsInt(_windowViews, 'name'), (v) => setState(() => _windowViewId = v), nullOk: true),
                ddInt('Электричество', _electricityId, _itemsInt(_electricities, 'name'), (v) => setState(() => _electricityId = v), nullOk: true),
                ddInt('Вода', _waterId, _itemsInt(_waters, 'name'), (v) => setState(() => _waterId = v), nullOk: true),
                ddInt('Канализация', _sewageId, _itemsInt(_sewages, 'name'), (v) => setState(() => _sewageId = v), nullOk: true),
                ddInt('Отопление', _heatingId, _itemsInt(_heatings, 'name'), (v) => setState(() => _heatingId = v), nullOk: true),
              ],
            ]),
            sec('Фото', [
              if (widget.editListingId != null && _existingPhotos.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _existingPhotos.where((p) => !_removedExistingIds.contains(p.id)).map((p) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            getImageUrl(p.url),
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                          ),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _removedExistingIds.add(p.id)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              Text('Фотографии *', style: TextStyle(color: muted, fontSize: 13)),
              if (_photoErr.isNotEmpty) Text(_photoErr, style: const TextStyle(color: Color(0xFFef4444), fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ...List.generate(_newPicked.length, (i) {
                    final p = _newPicked[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            p.bytes,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _newPicked.removeAt(i)),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              TextButton.icon(onPressed: _pickPhotos, icon: const Icon(Icons.add_photo_alternate), label: const Text('Добавить фото')),
              if (isDocumentTypeRequired(_propertyTypes, pType))
                ddInt('Наличие документов *', _documentTypeId, _itemsInt(_documentTypes, 'name'), (v) => setState(() => _documentTypeId = v)),
              const SizedBox(height: 8),
              Text('Тип цены', style: TextStyle(color: muted, fontSize: 13)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Цена указана', style: TextStyle(color: text, fontSize: 13)),
                      value: true,
                      groupValue: _priceTypeFixed,
                      onChanged: (v) => setState(() => _priceTypeFixed = v ?? true),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text('Договорная', style: TextStyle(color: text, fontSize: 13)),
                      value: false,
                      groupValue: _priceTypeFixed,
                      onChanged: (v) => setState(() => _priceTypeFixed = v ?? false),
                    ),
                  ),
                ],
              ),
              if (_priceTypeFixed) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: text),
                  decoration: deco('Цена (сомони) *'),
                ),
                const SizedBox(height: 8),
                Text('Торг?', style: TextStyle(color: muted, fontSize: 13)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text('Торг уместен', style: TextStyle(color: text, fontSize: 13)),
                        value: 'negotiable',
                        groupValue: _negotiationStatus,
                        onChanged: (v) => setState(() => _negotiationStatus = v ?? 'negotiable'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text('Без торга', style: TextStyle(color: text, fontSize: 13)),
                        value: 'fixed',
                        groupValue: _negotiationStatus,
                        onChanged: (v) => setState(() => _negotiationStatus = v ?? 'fixed'),
                      ),
                    ),
                  ],
                ),
              ],
            ]),
            sec('Расположение', [
              ddInt('Город / район *', _cityId, _itemsInt(_cities, 'name'), _onCityChanged),
              if (isDushanbeSelected(_cities, _cityId))
                ddInt('Махалла *', _mahallaId, _itemsInt(_mahallas, 'name'), (v) => setState(() => _mahallaId = v)),
              const SizedBox(height: 8),
              SizedBox(
                height: 280,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapPoint,
                          initialZoom: 13,
                          onTap: (tp, ll) {
                            setState(() {
                              _mapPoint = ll;
                              _latCtrl.text = ll.latitude.toStringAsFixed(6);
                              _lngCtrl.text = ll.longitude.toStringAsFixed(6);
                            });
                            _reverseGeocode(ll.latitude, ll.longitude);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'tj.manzilho.mobile',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _mapPoint,
                                width: 36,
                                height: 36,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 34),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: card,
                              elevation: 3,
                              shadowColor: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => _adjustMapZoom(-1),
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.remove, color: text, size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: card,
                              elevation: 3,
                              shadowColor: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: _goToMyLocation,
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.my_location, color: const Color(0xFF42A5F5), size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Material(
                              color: card,
                              elevation: 3,
                              shadowColor: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () => _adjustMapZoom(1),
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.add, color: text, size: 22),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(_latCtrl.text.isNotEmpty ? 'Местоположение выбрано' : 'Нажмите на карту', style: TextStyle(fontSize: 12, color: muted)),
              if (_addressCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Адрес: ${_addressCtrl.text}', style: TextStyle(fontSize: 12, color: muted)),
                ),
            ]),
            sec('Описание', [
              TextField(
                controller: _descriptionCtrl,
                maxLines: 5,
                style: TextStyle(color: text),
                decoration: deco('Описание *'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _hasWhatsapp = !_hasWhatsapp),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _hasWhatsapp,
                              onChanged: (v) => setState(() => _hasWhatsapp = v ?? false),
                              activeColor: brand,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Expanded(child: Text('WhatsApp', style: TextStyle(color: text, fontSize: 15))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _hasTelegram = !_hasTelegram),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _hasTelegram,
                              onChanged: (v) => setState(() => _hasTelegram = v ?? false),
                              activeColor: brand,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            Expanded(child: Text('Telegram', style: TextStyle(color: text, fontSize: 15))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            sec('Тариф', [
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _tariffType = 'usual'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _tariffType == 'usual' ? brand.withValues(alpha: isDark ? 0.28 : 0.18) : card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _tariffType == 'usual' ? brand : border,
                              width: _tariffType == 'usual' ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            'Обычно',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: text,
                              fontSize: 15,
                              fontWeight: _tariffType == 'usual' ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _tariffType = 'top'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          decoration: BoxDecoration(
                            color: _tariffType == 'top' ? brand.withValues(alpha: isDark ? 0.28 : 0.18) : card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _tariffType == 'top' ? brand : border,
                              width: _tariffType == 'top' ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            'Топ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: text,
                              fontSize: 15,
                              fontWeight: _tariffType == 'top' ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'После 10 дней объявление можно обновить в профиле.',
                style: TextStyle(fontSize: 12, color: muted, height: 1.35),
              ),
              if (_tariffType == 'top') ...[
                const SizedBox(height: 12),
                Text('Срок ТОП', style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _topTariffs.map((opt) {
                    final id = parseRefId(opt['id']);
                    if (id == null) return const SizedBox.shrink();
                    final name = (opt['name'] ?? '').toString().trim();
                    final days = opt['days']?.toString() ?? '';
                    final price = opt['price']?.toString() ?? '';
                    final sub = [if (days.isNotEmpty) '$days дн.', if (price.isNotEmpty) '$price с.'].join(' — ');
                    final label = name.isNotEmpty
                        ? (sub.isNotEmpty ? '$name ($sub)' : name)
                        : (sub.isNotEmpty ? sub : '—');
                    final sel = _topTariffId == id;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _topTariffId = id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          constraints: const BoxConstraints(minWidth: 88),
                          decoration: BoxDecoration(
                            color: sel ? brand : card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? brand : border, width: sel ? 2 : 1),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                              color: sel ? Colors.white : text,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ]),
            if (_submitErr != null) Text(_submitErr!, style: const TextStyle(color: Color(0xFFef4444))),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: brand, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52)),
              child: Text(_submitting ? '…' : (widget.editListingId != null ? 'Сохранить' : 'Опубликовать объявление')),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _noAccess(Color text, Color muted, String msg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(msg, textAlign: TextAlign.center, style: TextStyle(color: text, height: 1.45)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => launchUrl(Uri.parse('https://t.me/manzilho_tj'), mode: LaunchMode.externalApplication),
            child: const Text('Telegram'),
          ),
        ],
      ),
    );
  }
}
