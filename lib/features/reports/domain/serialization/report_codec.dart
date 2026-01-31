import '../models/nodes.dart';
import '../models/report_doc.dart';
import '../models/subject_info_value.dart';

class ReportCodec {
  /* =======================
     ReportDoc
     ======================= */

  static Map<String, dynamic> reportToJson(ReportDoc doc) => {
        'reportId': doc.reportId,
        'createdAtIso': doc.createdAtIso,
        'updatedAtIso': doc.updatedAtIso,

        // ---------- Subject Info (VALUES ONLY) ----------
        'subjectInfo': doc.subjectInfo.toJson(),

        // ---------- Layout / content ----------
        'placementChoice': doc.placementChoice.name,

        'roots': doc.roots.map(sectionToJson).toList(),

        'images': doc.images
            .map((i) => {
                  'id': i.id,
                  'filePath': i.filePath,
                })
            .toList(),

        'signature': {
          'name': doc.signature.name,
          'credentials': doc.signature.credentials,
          'signatureFilePath': doc.signature.signatureFilePath,
        },

        // NOTE:
        // - recommendation intentionally NOT written
        // - labels/layout intentionally NOT written
      };

  static ReportDoc reportFromJson(Map<String, dynamic> j) {
    // ---------- migration-safe timestamps ----------
    final createdAtIso =
        (j['createdAtIso'] as String?) ??
        (j['updatedAtIso'] as String?) ??
        DateTime.now().toIso8601String();

    final updatedAtIso =
        (j['updatedAtIso'] as String?) ??
        (j['createdAtIso'] as String?) ??
        DateTime.now().toIso8601String();

    // ---------- placement ----------
    final placementName =
        (j['placementChoice'] as String?) ??
            ImagePlacementChoice.attachmentsOnly.name;

    // ---------- subject info (values only, optional in old reports) ----------
    final subjectInfoJson = j['subjectInfo'];
    final subjectInfo = subjectInfoJson is Map<String, dynamic>
        ? SubjectInfoValues.fromJson(subjectInfoJson)
        : const SubjectInfoValues({});

    return ReportDoc(
      reportId: (j['reportId'] as String?) ?? 'unknown',
      createdAtIso: createdAtIso,
      updatedAtIso: updatedAtIso,

      subjectInfo: subjectInfo,

      placementChoice:
          ImagePlacementChoice.values.byName(placementName),

      roots: ((j['roots'] as List?) ?? const [])
          .map((e) => sectionFromJson(e as Map<String, dynamic>))
          .toList(),

      images: ((j['images'] as List?) ?? const [])
          .map((e) => ImageAttachment(
                id: (e['id'] as String?) ?? '',
                filePath: (e['filePath'] as String?) ?? '',
              ))
          .where((img) =>
              img.id.isNotEmpty && img.filePath.isNotEmpty)
          .toList(),

      signature: SignatureBlock(
        name: ((j['signature'] as Map?)?['name'] as String?) ?? '',
        credentials:
            ((j['signature'] as Map?)?['credentials'] as String?) ?? '',
        signatureFilePath:
            ((j['signature'] as Map?)?['signatureFilePath'] as String?),
      ),
    );
  }

  /* =======================
     SectionNode
     ======================= */

  static Map<String, dynamic> sectionToJson(SectionNode s) => {
        'type': 'section',
        'id': s.id,
        'title': s.title,
        'collapsed': s.collapsed,
        'style': styleToJson(s.style),
        'children': s.children.map(nodeToJson).toList(),
        'indent': s.indent,
      };

  static SectionNode sectionFromJson(Map<String, dynamic> j) => SectionNode(
        id: (j['id'] as String?) ?? '',
        title: (j['title'] as String?) ?? '',
        collapsed: (j['collapsed'] as bool?) ?? false,
        style: styleFromJson(
            (j['style'] as Map?)?.cast<String, dynamic>() ?? const {}),
        children: ((j['children'] as List?) ?? const [])
            .map((e) => nodeFromJson(e as Map<String, dynamic>))
            .toList(),
        indent: (j['indent'] as int?) ?? 0,
      );

  /* =======================
     Node
     ======================= */

  static Map<String, dynamic> nodeToJson(Node n) {
    if (n is SectionNode) return sectionToJson(n);
    if (n is ContentNode) {
      return {
        'type': 'content',
        'id': n.id,
        'text': n.text,
        'indent': n.indent,
      };
    }
    throw StateError('Unknown node type');
  }

  static Node nodeFromJson(Map<String, dynamic> j) {
    final type = (j['type'] as String?) ?? '';
    if (type == 'section') return sectionFromJson(j);
    if (type == 'content') {
      return ContentNode(
        id: (j['id'] as String?) ?? '',
        text: (j['text'] as String?) ?? '',
        indent: (j['indent'] as int?) ?? 0,
      );
    }
    throw StateError('Unknown node json type: $type');
  }

  /* =======================
     TitleStyle
     ======================= */

  static Map<String, dynamic> styleToJson(TitleStyle s) => {
        'level': s.level.name,
        'bold': s.bold,
        'align': s.align.name,
      };

  static TitleStyle styleFromJson(Map<String, dynamic> j) {
    final levelName =
        (j['level'] as String?) ?? HeadingLevel.h2.name;
    final alignName =
        (j['align'] as String?) ?? TitleAlign.left.name;

    return TitleStyle(
      level: HeadingLevel.values.byName(levelName),
      bold: (j['bold'] as bool?) ?? true,
      align: TitleAlign.values.byName(alignName),
    );
  }
}
