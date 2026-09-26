/// Lenient JSON readers so a missing/renamed field never crashes a screen.
DateTime? asDate(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

int asInt(Object? value, [int fallback = 0]) => switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? fallback,
      _ => fallback,
    };

int? asIntOrNull(Object? value) => value == null ? null : asInt(value);

double asDouble(Object? value, [double fallback = 0]) => switch (value) {
      num v => v.toDouble(),
      String v => double.tryParse(v) ?? fallback,
      _ => fallback,
    };

String asString(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

bool asBool(Object? value) => value == true || value == 'true' || value == 1;

Map<String, dynamic> asMap(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> asMapList(Object? value) =>
    value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
