import 'package:flutter/foundation.dart';

/// Stable internal keys — NEVER change
class SubjectFieldKeys {
  static const String subjectName = 'subjectName';
  static const String subjectId = 'subjectId';
}

@immutable
class SubjectFieldDef {
  final String key;
  final String title;
  final bool required;
  final int order;
  final bool isSystem;

  const SubjectFieldDef({
    required this.key,
    required this.title,
    required this.required,
    required this.order,
    required this.isSystem,
  });

  // Compatibility with older code that used fieldId
  String get fieldId => key;

  SubjectFieldDef copyWith({
    String? title,
    bool? required,
    int? order,
  }) {
    return SubjectFieldDef(
      key: key,
      title: title ?? this.title,
      required: required ?? this.required,
      order: order ?? this.order,
      isSystem: isSystem,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'required': required,
        'order': order,
        'isSystem': isSystem,
      };

  factory SubjectFieldDef.fromJson(Map<String, dynamic> j) {
    return SubjectFieldDef(
      key: j['key'] as String,
      title: (j['title'] as String?) ?? '',
      required: (j['required'] as bool?) ?? false,
      order: (j['order'] as int?) ?? 0,
      isSystem: (j['isSystem'] as bool?) ?? false,
    );
  }
}

@immutable
class SubjectInfoBlockDef {
  final bool enabled;
  final int schemaVersion;

  /// ✅ NEW: persist the column layout (1 or 2)
  final int columns;

  final List<SubjectFieldDef> fields;

  const SubjectInfoBlockDef({
    required this.enabled,
    required this.schemaVersion,
    required this.columns,
    required this.fields,
  });

  factory SubjectInfoBlockDef.defaults() {
    return const SubjectInfoBlockDef(
      enabled: true,
      schemaVersion: 1,
      columns: 2,
      fields: [
        SubjectFieldDef(
          key: SubjectFieldKeys.subjectName,
          title: 'Subject Name',
          required: true,
          order: 0,
          isSystem: true,
        ),
        SubjectFieldDef(
          key: SubjectFieldKeys.subjectId,
          title: 'Subject ID',
          required: false,
          order: 1,
          isSystem: true,
        ),
      ],
    );
  }

  List<SubjectFieldDef> get orderedFields {
    final list = fields.toList()..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  SubjectInfoBlockDef copyWith({
    bool? enabled,
    int? columns,
    List<SubjectFieldDef>? fields,
  }) {
    return SubjectInfoBlockDef(
      enabled: enabled ?? this.enabled,
      schemaVersion: schemaVersion,
      columns: columns ?? this.columns,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'schemaVersion': schemaVersion,
        'columns': columns,
        'fields': fields.map((f) => f.toJson()).toList(),
      };

  factory SubjectInfoBlockDef.fromJson(Map<String, dynamic>? j) {
    if (j == null) return SubjectInfoBlockDef.defaults();

    return SubjectInfoBlockDef(
      enabled: (j['enabled'] as bool?) ?? true,
      schemaVersion: (j['schemaVersion'] as int?) ?? 1,
      columns: ((j['columns'] as int?) ?? 2) == 2 ? 2 : 1,
      fields: ((j['fields'] as List?) ?? const [])
          .map((e) => SubjectFieldDef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
