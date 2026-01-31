import 'package:flutter/foundation.dart';

@immutable
class SubjectInfoValues {
  final Map<String, String> values;

  const SubjectInfoValues(this.values);

  SubjectInfoValues copyWithValue(String key, String value) {
    final next = Map<String, String>.from(values);
    next[key] = value;
    return SubjectInfoValues(next);
  }

  String valueOf(String key) => values[key] ?? '';

  Map<String, dynamic> toJson() => values;

  factory SubjectInfoValues.fromJson(Map<String, dynamic>? j) {
    return SubjectInfoValues(
      (j ?? {}).map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
  }
}
