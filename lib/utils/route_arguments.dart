import 'package:flutter/widgets.dart';

Map<String, dynamic> routeArguments(BuildContext context) {
  return stringKeyedMap(ModalRoute.of(context)?.settings.arguments) ??
      <String, dynamic>{};
}

String? routeStringArgument(BuildContext context) {
  final arguments = ModalRoute.of(context)?.settings.arguments;
  return arguments is String ? arguments : null;
}

Map<String, dynamic>? stringKeyedMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String) {
        result[key] = entry.value;
      }
    }
    return result;
  }
  return null;
}
