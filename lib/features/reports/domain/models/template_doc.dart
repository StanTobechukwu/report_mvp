import 'package:flutter/foundation.dart';
import 'nodes.dart';

@immutable
class TemplateDoc {
  final String templateId;
  final DateTime updatedAt;
  final String name;
  final List<SectionNode> roots;

  const TemplateDoc({
    required this.templateId,
    required this.updatedAt,
    required this.name,
    required this.roots,
  });

  TemplateDoc copyWith({
    DateTime? updatedAt,
    String? name,
    List<SectionNode>? roots,
  }) {
    return TemplateDoc(
      templateId: templateId,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      roots: roots ?? this.roots,
    );
  }
}
