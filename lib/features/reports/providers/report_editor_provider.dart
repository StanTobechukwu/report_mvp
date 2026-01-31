import 'package:flutter/foundation.dart';

import '../../../core/utils/ids.dart';
import '../../../core/utils/time.dart';

import '../data/reports_repository.dart';
import '../data/templates_repository.dart';

import '../domain/models/nodes.dart';
import '../domain/models/report_doc.dart';
import '../domain/models/template_doc.dart';
import '../domain/models/subject_info_def.dart';
import '../domain/models/subject_info_value.dart';

class ReportEditorProvider extends ChangeNotifier {
  final ReportsRepository repo;
  final TemplatesRepository templatesRepo;

  late ReportDoc _doc;

  /// Selected node can be a SectionNode OR ContentNode id.
  String? _selectedNodeId;

  /// Template-side subject info structure (defs), used by the report screen UI
  /// to know what fields to render. Values live in ReportDoc.subjectInfo.
  SubjectInfoBlockDef _subjectInfoDef = SubjectInfoBlockDef.defaults();

  ReportEditorProvider({
    required this.repo,
    required this.templatesRepo,
  }) {
    newReport();
  }

  // =========================
  // Getters
  // =========================

  ReportDoc get doc => _doc;
  String? get selectedNodeId => _selectedNodeId;

  SubjectInfoBlockDef get subjectInfoDef => _subjectInfoDef;
  SubjectInfoValues get subjectInfoValues => _doc.subjectInfo;

  // =========================
  // Selection
  // =========================

  void selectNode(String? id) {
    _selectedNodeId = id;
    notifyListeners();
  }

  void clearSelection() => selectNode(null);

  // =========================
  // Create / Load / Save
  // =========================

  ReportDoc _newEmptyDoc() {
    final now = nowIso();
    return ReportDoc(
      reportId: newId('rpt'),
      createdAtIso: now,
      updatedAtIso: now,
      roots: const [],
      images: const [],
      placementChoice: ImagePlacementChoice.attachmentsOnly,
      signature: const SignatureBlock(),
      subjectInfo: const SubjectInfoValues({}),
    );
  }

  void newReport() {
    _doc = _newEmptyDoc();
    _selectedNodeId = null;

    // Default structure for subject info fields (template-like defaults)
    _subjectInfoDef = SubjectInfoBlockDef.defaults();

    notifyListeners();
  }

  /// Use a template to start a report:
  /// - structure from template.roots
  /// - subject info defs from template.subjectInfo
  /// - subject info values start empty
  void newReportFromTemplate(TemplateDoc template) {
    final now = nowIso();

    _subjectInfoDef = template.subjectInfo;

    _doc = ReportDoc(
      reportId: newId('rpt'),
      createdAtIso: now,
      updatedAtIso: now,
      roots: template.roots,
      images: const [],
      placementChoice: ImagePlacementChoice.attachmentsOnly,
      signature: const SignatureBlock(),
      subjectInfo: const SubjectInfoValues({}),
    );

    _selectedNodeId = null;
    notifyListeners();
  }

  Future<void> save() async {
    _doc = _doc.copyWith(updatedAtIso: nowIso());
    await repo.saveReport(_doc);
    notifyListeners();
  }

  Future<void> loadById(String reportId) async {
    final loaded = await repo.loadReport(reportId);

    // Make sure subjectInfo never becomes null (your model already defaults it)
    _doc = loaded;

    _selectedNodeId = null;

    // Keep whatever current template defs you’re using.
    // If you want, you can also load the last-used template here later.
    notifyListeners();
  }

  /// Optional: load a template by id using templatesRepo (if your repo supports it)
  Future<void> loadTemplateAndStartReport(String templateId) async {
    final template = await templatesRepo.loadTemplate(templateId);
    newReportFromTemplate(template);
  }

  // =========================
  // Subject Info (VALUES ONLY)
  // Subject info is excluded from indent logic by design.
  // =========================

  void updateSubjectInfo(String fieldKey, String value) {
    _doc = _doc.copyWith(
      subjectInfo: _doc.subjectInfo.copyWithValue(fieldKey, value),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  // =========================
  // Tree: Add
  // =========================

  String _id(String prefix) => newId(prefix);

  void addTopLevelSection(String title) {
    final t = title.trim();
    if (t.isEmpty) return;

    final sec = SectionNode(id: _id('sec'), title: t);

    _doc = _doc.copyWith(
      roots: [..._doc.roots, sec],
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void addSubsectionUnderSelected(String title) {
    final parentId = _selectedNodeId;
    final t = title.trim();
    if (parentId == null || t.isEmpty) return;

    final child = SectionNode(id: _id('sec'), title: t);

    _doc = _doc.copyWith(
      roots: _updateSectionTree(
        _doc.roots,
        parentId,
        (s) => s.copyWith(
          children: [...s.children, child],
          collapsed: false,
        ),
      ),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void addContentUnderSelected({String initialText = ''}) {
    final parentId = _selectedNodeId;
    if (parentId == null) return;

    final child = ContentNode(id: _id('txt'), text: initialText);

    _doc = _doc.copyWith(
      roots: _updateSectionTree(
        _doc.roots,
        parentId,
        (s) => s.copyWith(
          children: [...s.children, child],
          collapsed: false,
        ),
      ),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  // =========================
  // Tree: Edit
  // =========================

  void toggleCollapsed(String sectionId) {
    _doc = _doc.copyWith(
      roots: _updateSectionTree(
        _doc.roots,
        sectionId,
        (s) => s.copyWith(collapsed: !s.collapsed),
      ),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void renameSection(String sectionId, String title) {
    final t = title.trim();
    if (t.isEmpty) return;

    _doc = _doc.copyWith(
      roots: _updateSectionTree(
        _doc.roots,
        sectionId,
        (s) => s.copyWith(title: t),
      ),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void updateSectionStyle(String sectionId, TitleStyle style) {
    _doc = _doc.copyWith(
      roots: _updateSectionTree(
        _doc.roots,
        sectionId,
        (s) => s.copyWith(style: style),
      ),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void updateContent(String contentId, String text) {
    _doc = _doc.copyWith(
      roots: _updateContentTree(_doc.roots, contentId, text),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  // =========================
  // Indent / Outdent nodes
  // Requires: SectionNode.indent, ContentNode.indent in nodes.dart
  // =========================

  void indentNode(String nodeId) => _shiftIndent(nodeId, +1);
  void outdentNode(String nodeId) => _shiftIndent(nodeId, -1);

  void _shiftIndent(String nodeId, int delta) {
    int clampIndent(int v) => v.clamp(0, 20);

    Node transform(Node n) {
      if (n.id == nodeId) {
        if (n is SectionNode) {
          return n.copyWith(indent: clampIndent(n.indent + delta));
        }
        if (n is ContentNode) {
          return n.copyWith(indent: clampIndent(n.indent + delta));
        }
      }

      if (n is SectionNode) {
        final updatedChildren = n.children.map(transform).toList();
        return n.copyWith(children: updatedChildren);
      }

      return n;
    }

    final updatedRoots =
        _doc.roots.map((s) => transform(s) as SectionNode).toList();

    _doc = _doc.copyWith(
      roots: updatedRoots,
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  // =========================
  // Images
  // =========================

  void setPlacementChoice(ImagePlacementChoice choice) {
    if (choice == ImagePlacementChoice.attachmentsOnly && _doc.images.length > 8) {
      throw Exception(
        'Attachments-only mode allows max 8 images. Remove some images first.',
      );
    }

    _doc = _doc.copyWith(
      placementChoice: choice,
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void addImages(List<String> filePaths) {
    final clean = filePaths.where((p) => p.trim().isNotEmpty).toList();
    if (clean.isEmpty) return;

    final cap = _doc.maxImages;
    if (_doc.images.length + clean.length > cap) {
      throw Exception('Maximum of $cap images allowed for this mode.');
    }

    final newImgs =
        clean.map((p) => ImageAttachment(id: _id('img'), filePath: p)).toList();

    _doc = _doc.copyWith(
      images: [..._doc.images, ...newImgs],
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void removeImage(String imageId) {
    _doc = _doc.copyWith(
      images: _doc.images.where((i) => i.id != imageId).toList(),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  // =========================
  // Signature
  // =========================

  void updateSigner({String? name, String? credentials}) {
    _doc = _doc.copyWith(
      signature: _doc.signature.copyWith(name: name, credentials: credentials),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void setSignatureFilePath(String? path) {
    _doc = _doc.copyWith(
      signature: _doc.signature.copyWith(signatureFilePath: path),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  // =========================
  // Tree helpers
  // =========================

  List<SectionNode> _updateSectionTree(
    List<SectionNode> roots,
    String targetId,
    SectionNode Function(SectionNode) updater,
  ) {
    return roots.map((s) => _updateSectionNode(s, targetId, updater)).toList();
  }

  SectionNode _updateSectionNode(
    SectionNode node,
    String targetId,
    SectionNode Function(SectionNode) updater,
  ) {
    var current = node;

    if (node.id == targetId) {
      current = updater(node);
    }

    final updatedChildren = current.children.map((child) {
      if (child is SectionNode) return _updateSectionNode(child, targetId, updater);
      return child;
    }).toList();

    return current.copyWith(children: updatedChildren);
  }

  List<SectionNode> _updateContentTree(
    List<SectionNode> roots,
    String contentId,
    String text,
  ) {
    List<Node> walk(List<Node> children) {
      return children.map((n) {
        if (n is ContentNode && n.id == contentId) {
          return n.copyWith(text: text);
        }
        if (n is SectionNode) {
          return n.copyWith(children: walk(n.children));
        }
        return n;
      }).toList();
    }

    return roots.map((s) => s.copyWith(children: walk(s.children))).toList();
  }
}
