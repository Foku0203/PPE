import '../../core/utils/json.dart';

enum PpeCategory {
  head('HEAD'),
  eye('EYE'),
  hearing('HEARING'),
  respiratory('RESPIRATORY'),
  hand('HAND'),
  foot('FOOT'),
  body('BODY'),
  fall('FALL');

  const PpeCategory(this.apiValue);
  final String apiValue;

  static PpeCategory fromApi(String? value) => PpeCategory.values.firstWhere((c) => c.apiValue == value, orElse: () => PpeCategory.body);
}

class PpeTranslation {
  const PpeTranslation({required this.locale, required this.name, this.shortName = '', this.description = ''});

  final String locale;
  final String name;
  final String shortName;
  final String description;

  factory PpeTranslation.fromJson(Map<String, dynamic> json) => PpeTranslation(
        locale: asString(json['locale']),
        name: asString(json['name']),
        shortName: asString(json['short_name']),
        description: asString(json['description']),
      );

  Map<String, dynamic> toJson() => {'locale': locale, 'name': name, 'short_name': shortName, 'description': description};
}

class PpeItem {
  const PpeItem({
    required this.id,
    required this.code,
    required this.name,
    this.category = PpeCategory.body,
    this.iconKey = 'shield',
    this.imageUrl = '',
    this.unit = 'piece',
    this.sizes = const [],
    this.requiresSerial = false,
    this.isReturnable = false,
    this.quota,
    this.lifespanDays,
    this.reorderPoint = 0,
    this.active = true,
    this.description = '',
    this.translations = const {},
    this.stock = 0,
    this.reserved = 0,
    this.issued30d = 0,
    this.expiringLots = 0,
  });

  final int id;
  final String code;
  final PpeCategory category;
  final String iconKey;
  final String imageUrl;
  final String unit;
  final List<String> sizes;
  final bool requiresSerial;
  final bool isReturnable;
  final int? quota;
  final int? lifespanDays;
  final int reorderPoint;
  final bool active;
  final String name;
  final String description;
  final Map<String, PpeTranslation> translations;

  /// Available now (usable, unreserved, not expired).
  final int stock;
  final int reserved;

  /// Only filled by the inventory summary endpoint.
  final int issued30d;
  final int expiringLots;

  bool get isLowStock => stock <= reorderPoint;
  bool get isOutOfStock => stock <= 0;

  /// Name in [locale] (TH/EN/MY) falling back to the server-resolved name.
  String nameFor(String locale) => translations[locale]?.name.isNotEmpty == true ? translations[locale]!.name : name;

  String descriptionFor(String locale) =>
      translations[locale]?.description.isNotEmpty == true ? translations[locale]!.description : description;

  factory PpeItem.fromJson(Map<String, dynamic> json) {
    final translations = {
      for (final t in asMapList(json['translations']).map(PpeTranslation.fromJson)) t.locale: t,
    };
    return PpeItem(
      id: asInt(json['id']),
      code: asString(json['code']),
      category: PpeCategory.fromApi(json['category'] as String?),
      iconKey: asString(json['icon_key'], 'shield'),
      imageUrl: asString(json['image_url']),
      unit: asString(json['unit'], 'piece'),
      sizes: (json['size_options'] as List?)?.map((e) => e.toString()).toList() ??
          asString(json['sizes']).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      requiresSerial: asBool(json['requires_serial']),
      isReturnable: asBool(json['is_returnable']),
      quota: asIntOrNull(json['quota']),
      lifespanDays: asIntOrNull(json['lifespan_days']),
      reorderPoint: asInt(json['reorder_point']),
      active: json['active'] != false,
      name: asString(json['name'], asString(json['code'])),
      description: asString(json['description']),
      translations: translations,
      stock: asInt(json['stock']),
      reserved: asInt(json['reserved']),
      issued30d: asInt(json['issued_30d']),
      expiringLots: asInt(json['expiring_lots']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'category': category.apiValue,
        'icon_key': iconKey,
        'image_url': imageUrl,
        'unit': unit,
        'size_options': sizes,
        'requires_serial': requiresSerial,
        'is_returnable': isReturnable,
        'quota': quota,
        'lifespan_days': lifespanDays,
        'reorder_point': reorderPoint,
        'active': active,
        'name': name,
        'description': description,
        'translations': translations.values.map((t) => t.toJson()).toList(),
        'stock': stock,
        'reserved': reserved,
      };
}

/// Result of `GET /catalog/ppe/{id}/eligibility/`.
class Eligibility {
  const Eligibility({
    required this.allowed,
    required this.specialApprovalRequired,
    this.reason,
    this.eligibleAt,
    this.lastIssuedAt,
    this.stock = 0,
    this.quota,
  });

  final bool allowed;
  final bool specialApprovalRequired;

  /// ACTIVE_REQUEST_EXISTS | LIFESPAN_NOT_EXPIRED | QUOTA_EXCEEDED | ITEM_INACTIVE | null
  final String? reason;
  final DateTime? eligibleAt;
  final DateTime? lastIssuedAt;
  final int stock;
  final int? quota;

  bool get isBlocked => reason == 'ACTIVE_REQUEST_EXISTS' || reason == 'ITEM_INACTIVE';

  factory Eligibility.fromJson(Map<String, dynamic> json) => Eligibility(
        allowed: asBool(json['allowed']),
        specialApprovalRequired: asBool(json['special_approval_required']),
        reason: json['reason'] as String?,
        eligibleAt: asDate(json['eligible_at']),
        lastIssuedAt: asDate(json['last_issued_at']),
        stock: asInt(json['stock']),
        quota: asIntOrNull(json['quota']),
      );
}
