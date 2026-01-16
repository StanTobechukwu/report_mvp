import 'package:flutter/foundation.dart';

import '../../../core/utils/ids.dart';
import '../../../core/utils/time.dart';
import '../data/reports_repository.dart';
import '../domain/models/nodes.dart';
import '../domain/models/report_doc.dart';

class ReportEditorProvider extends ChangeNotifier {
  final ReportsRepository repo;

  ReportDoc _doc = ReportDoc(
    reportId: newId('rpt'),
    createdAtIso: nowIso(),
    updatedAtIso: nowIso(),
  );

  String? _selectedSectionId;

  ReportEditorProvider({required this.repo});

  ReportDoc get doc => _doc;
  String? get selectedSectionId => _selectedSectionId;

  void selectSection(String? id) {
    _selectedSectionId = id;
    notifyListeners();
  }

  void clearSelection() => selectSection(null);

  // ----------- storage -----------
  Future<void> save() async {
    _doc = _doc.copyWith(updatedAtIso: nowIso());
    await repo.saveReport(_doc);
    notifyListeners();
  }

  Future<void> loadById(String reportId) async {
    final loaded = await repo.loadReport(reportId);
    _doc = loaded;
    _selectedSectionId = null;
    notifyListeners();
  }

  void newReport() {
    _doc = ReportDoc(
      reportId: newId('rpt'),
      createdAtIso: nowIso(),
      updatedAtIso: nowIso(),
    );
    _selectedSectionId = null;
    notifyListeners();
  }

  // ----------- ids -----------
  String _id(String prefix) => newId(prefix);

  // ----------- add / edit tree -----------
  void addTopLevelSection(String title) {
    final sec = SectionNode(id: _id('sec'), title: title.trim());
    _doc = _doc.copyWith(roots: [..._doc.roots, sec], updatedAtIso: nowIso());
    notifyListeners();
  }

  void addSubsectionUnderSelected(String title) {
    final target = _selectedSectionId;
    if (target == null) return;

    final child = SectionNode(id: _id('sec'), title: title.trim());
    _doc = _doc.copyWith(
      roots: _updateSectionTree(_doc.roots, target, (s) => s.copyWith(children: [...s.children, child], collapsed: false)),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void addContentUnderSelected() {
    final target = _selectedSectionId;
    if (target == null) return;

    final child = ContentNode(id: _id('txt'));
    _doc = _doc.copyWith(
      roots: _updateSectionTree(_doc.roots, target, (s) => s.copyWith(children: [...s.children, child], collapsed: false)),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void toggleCollapsed(String sectionId) {
    _doc = _doc.copyWith(
      roots: _updateSectionTree(_doc.roots, sectionId, (s) => s.copyWith(collapsed: !s.collapsed)),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void renameSection(String sectionId, String title) {
    _doc = _doc.copyWith(
      roots: _updateSectionTree(_doc.roots, sectionId, (s) => s.copyWith(title: title.trim())),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void updateSectionStyle(String sectionId, TitleStyle style) {
    _doc = _doc.copyWith(
      roots: _updateSectionTree(_doc.roots, sectionId, (s) => s.copyWith(style: style)),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void updateContent(String contentId, String text) {
    _doc = _doc.copyWith(roots: _updateContentTree(_doc.roots, contentId, text), updatedAtIso: nowIso());
    notifyListeners();
  }

  // ----------- images rules -----------
  void setPlacementChoice(ImagePlacementChoice choice) {
    if (choice == ImagePlacementChoice.attachmentsOnly && _doc.images.length > 8) {
      throw Exception('Attachments-only mode allows max 8 images. Remove some images first.');
    }
    _doc = _doc.copyWith(placementChoice: choice, updatedAtIso: nowIso());
    notifyListeners();
  }

  void addImages(List<String> filePaths) {
    final cap = _doc.maxImages;
    if (_doc.images.length + filePaths.length > cap) {
      throw Exception('Maximum of $cap images allowed for this mode.');
    }
    final newImgs = filePaths.map((p) => ImageAttachment(id: _id('img'), filePath: p)).toList();
    _doc = _doc.copyWith(images: [..._doc.images, ...newImgs], updatedAtIso: nowIso());
    notifyListeners();
  }

  void removeImage(String imageId) {
    _doc = _doc.copyWith(images: _doc.images.where((i) => i.id != imageId).toList(), updatedAtIso: nowIso());
    notifyListeners();
  }

  // ----------- recommendation + signature -----------
  void updateRecommendation(String text) {
    _doc = _doc.copyWith(recommendation: _doc.recommendation.copyWith(text: text), updatedAtIso: nowIso());
    notifyListeners();
  }

  void updateEndoscopist({String? name, String? credentials}) {
    _doc = _doc.copyWith(
      signature: _doc.signature.copyWith(name: name, credentials: credentials),
      updatedAtIso: nowIso(),
    );
    notifyListeners();
  }

  void setSignatureFilePath(String? path) {
    _doc = _doc.copyWith(signature: _doc.signature.copyWith(signatureFilePath: path), updatedAtIso: nowIso());
    notifyListeners();
  }

  // ----------- tree helpers -----------
  List<SectionNode> _updateSectionTree(List<SectionNode> roots, String targetId, SectionNode Function(SectionNode) updater) {
    return roots.map((s) => _updateSectionNode(s, targetId, updater)).toList();
  }

  SectionNode _updateSectionNode(SectionNode node, String targetId, SectionNode Function(SectionNode) updater) {
    SectionNode current = node;
    if (node.id == targetId) current = updater(node);

    final updatedChildren = current.children.map((child) {
      if (child is SectionNode) return _updateSectionNode(child, targetId, updater);
      return child;
    }).toList();

    return current.copyWith(children: updatedChildren);
  }

  List<SectionNode> _updateContentTree(List<SectionNode> roots, String contentId, String text) {
    List<Node> updateChildren(List<Node> children) {
      return children.map((n) {
        if (n is ContentNode && n.id == contentId) return n.copyWith(text: text);
        if (n is SectionNode) return n.copyWith(children: updateChildren(n.children));
        return n;
      }).toList();
    }

    return roots.map((s) => s.copyWith(children: updateChildren(s.children))).toList();
  }
}
