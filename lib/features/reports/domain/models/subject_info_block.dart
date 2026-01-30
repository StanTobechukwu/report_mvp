import 'package:flutter/foundation.dart';

/// Internal identifiers for the two “special” fields.
/// These DO NOT change even if the user renames the titles shown in the UI.
enum SubjectIdentifierType {
  subjectName,
  subjectId,
}

@immutable
class SubjectInfoField {
  /// Stable internal id for this field (for editing/updating this exact field).
  final String fieldId;

  /// The title/label the user sees (editable for custom fields,
  /// but we will treat Name/ID differently as discussed).
  final String title;

  /// The value the user enters.
  final String value;

  const SubjectInfoField({
    required this.fieldId,
    required this.title,
    this.value = '',
  });

  SubjectInfoField copyWith({
    String? fieldId,
    String? title,
    String? value,
  }) {
    return SubjectInfoField(
      fieldId: fieldId ?? this.fieldId,
      title: title ?? this.title,
      value: value ?? this.value,
    );
  }
}

@immutable
class SubjectInfoBlock {
  /// Whether this block is enabled/used for the report.
  final bool enabled;

  /// The two default fields shown to users.
  ///
  /// IMPORTANT:
  /// - These titles can be shown as "Patient Name" / "Hospital No" etc.
  /// - But internally we still treat them as subjectName / subjectId identifiers.
  final SubjectInfoField subjectNameField;
  final SubjectInfoField subjectIdField;

  /// User-added extra fields (e.g. Age, Sex, Ward, Address).
  final List<SubjectInfoField> extraFields;

  /// Layout preference for PDF/UI rendering.
  /// (Simple default is 1 column; you can later support 2 columns.)
  final int columns; // 1 or 2

  const SubjectInfoBlock({
    this.enabled = false,
    required this.subjectNameField,
    required this.subjectIdField,
    this.extraFields = const [],
    this.columns = 1,
  });

  /// Helper: what we use for search/display fallback.
  /// Prefer subjectName if present, else subjectId, else empty.
  String get searchKey {
    final name = subjectNameField.value.trim();
    if (name.isNotEmpty) return name;
    final id = subjectIdField.value.trim();
    if (id.isNotEmpty) return id;
    return '';
  }

  SubjectInfoBlock copyWith({
    bool? enabled,
    SubjectInfoField? subjectNameField,
    SubjectInfoField? subjectIdField,
    List<SubjectInfoField>? extraFields,
    int? columns,
  }) {
    return SubjectInfoBlock(
      enabled: enabled ?? this.enabled,
      subjectNameField: subjectNameField ?? this.subjectNameField,
      subjectIdField: subjectIdField ?? this.subjectIdField,
      extraFields: extraFields ?? this.extraFields,
      columns: columns ?? this.columns,
    );
  }
}
