import '../models/nodes.dart';
import '../models/report_doc.dart';

class ReportCodec {
  // ---------- ReportDoc ----------
  static Map<String, dynamic> reportToJson(ReportDoc doc) => {
        'reportId': doc.reportId,
        'createdAtIso': doc.createdAtIso,
        'updatedAtIso': doc.updatedAtIso,
        'placementChoice': doc.placementChoice.name,
        'roots': doc.roots.map(sectionToJson).toList(),
        'images': doc.images.map((i) => {'id': i.id, 'filePath': i.filePath}).toList(),
        'recommendation': {'text': doc.recommendation.text},
        'signature': {
          'name': doc.signature.name,
          'credentials': doc.signature.credentials,
          'signatureFilePath': doc.signature.signatureFilePath,
        },
      };

  static ReportDoc reportFromJson(Map<String, dynamic> j) => ReportDoc(
        reportId: j['reportId'] as String,
        createdAtIso: j['createdAtIso'] as String,
        updatedAtIso: j['updatedAtIso'] as String,
        placementChoice: ImagePlacementChoice.values.byName(j['placementChoice'] as String),
        roots: (j['roots'] as List).map((e) => sectionFromJson(e as Map<String, dynamic>)).toList(),
        images: (j['images'] as List)
            .map((e) => ImageAttachment(id: e['id'] as String, filePath: e['filePath'] as String))
            .toList(),
        recommendation: RecommendationBlock(text: (j['recommendation']['text'] as String?) ?? ''),
        signature: SignatureBlock(
          name: (j['signature']['name'] as String?) ?? '',
          credentials: (j['signature']['credentials'] as String?) ?? '',
          signatureFilePath: j['signature']['signatureFilePath'] as String?,
        ),
      );

  // ---------- SectionNode ----------
  static Map<String, dynamic> sectionToJson(SectionNode s) => {
        'type': 'section',
        'id': s.id,
        'title': s.title,
        'collapsed': s.collapsed,
        'style': styleToJson(s.style),
        'children': s.children.map(nodeToJson).toList(),
      };

  static SectionNode sectionFromJson(Map<String, dynamic> j) => SectionNode(
        id: j['id'] as String,
        title: j['title'] as String,
        collapsed: (j['collapsed'] as bool?) ?? false,
        style: styleFromJson(j['style'] as Map<String, dynamic>),
        children: (j['children'] as List).map((e) => nodeFromJson(e as Map<String, dynamic>)).toList(),
      );

  // ---------- Node ----------
  static Map<String, dynamic> nodeToJson(Node n) {
    if (n is SectionNode) return sectionToJson(n);
    if (n is ContentNode) return {
          'type': 'content',
          'id': n.id,
          'text': n.text,
        };
    throw StateError('Unknown node type');
  }

  static Node nodeFromJson(Map<String, dynamic> j) {
    final type = j['type'] as String;
    if (type == 'section') return sectionFromJson(j);
    if (type == 'content') return ContentNode(id: j['id'] as String, text: (j['text'] as String?) ?? '');
    throw StateError('Unknown node json type: $type');
  }

  // ---------- TitleStyle ----------
  static Map<String, dynamic> styleToJson(TitleStyle s) => {
        'level': s.level.name,
        'bold': s.bold,
        'align': s.align.name,
      };

  static TitleStyle styleFromJson(Map<String, dynamic> j) => TitleStyle(
        level: HeadingLevel.values.byName(j['level'] as String),
        bold: j['bold'] as bool? ?? true,
        align: TitleAlign.values.byName(j['align'] as String),
      );
}
