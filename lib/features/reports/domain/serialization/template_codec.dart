import '../models/nodes.dart';
import '../models/template_doc.dart';

class TemplateCodec {
  static Map<String, dynamic> templateToJson(TemplateDoc t) => {
        'templateId': t.templateId,
        'updatedAtIso': t.updatedAt.toIso8601String(),
        'name': t.name,
        'roots': t.roots.map(_sectionToJson).toList(),
      };

  static TemplateDoc templateFromJson(Map<String, dynamic> j) {
    return TemplateDoc(
      templateId: (j['templateId'] as String?) ?? 'unknown',
      updatedAt: DateTime.tryParse((j['updatedAtIso'] as String?) ?? '') ?? DateTime.now(),
      name: (j['name'] as String?) ?? 'Untitled Template',
      roots: ((j['roots'] as List?) ?? const [])
          .map((e) => _sectionFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ---------- SectionNode / Node ----------
  static Map<String, dynamic> _sectionToJson(SectionNode s) => {
        'type': 'section',
        'id': s.id,
        'title': s.title,
        'collapsed': s.collapsed,
        'style': _styleToJson(s.style),
        'children': s.children.map(_nodeToJson).toList(),
      };

  static SectionNode _sectionFromJson(Map<String, dynamic> j) => SectionNode(
        id: (j['id'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        collapsed: (j['collapsed'] as bool?) ?? false,
        style: _styleFromJson((j['style'] as Map?)?.cast<String, dynamic>() ?? const {}),
        children: ((j['children'] as List?) ?? const [])
            .map((e) => _nodeFromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static Map<String, dynamic> _nodeToJson(Node n) {
    if (n is SectionNode) return _sectionToJson(n);
    if (n is ContentNode) {
      return {
        'type': 'content',
        'id': n.id,
        'text': n.text,
      };
    }
    throw StateError('Unknown node type');
  }

  static Node _nodeFromJson(Map<String, dynamic> j) {
    final type = (j['type'] as String?) ?? '';
    if (type == 'section') return _sectionFromJson(j);
    if (type == 'content') {
      return ContentNode(
        id: (j['id'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
      );
    }
    throw StateError('Unknown node json type: $type');
  }

  // ---------- TitleStyle ----------
  static Map<String, dynamic> _styleToJson(TitleStyle s) => {
        'level': s.level.name,
        'bold': s.bold,
        'align': s.align.name,
      };

  static TitleStyle _styleFromJson(Map<String, dynamic> j) {
    final levelName = (j['level'] as String?) ?? HeadingLevel.h2.name;
    final alignName = (j['align'] as String?) ?? TitleAlign.left.name;

    return TitleStyle(
      level: HeadingLevel.values.byName(levelName),
      bold: (j['bold'] as bool?) ?? true,
      align: TitleAlign.values.byName(alignName),
    );
  }
}
