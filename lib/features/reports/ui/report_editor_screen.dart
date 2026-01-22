

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../domain/models/nodes.dart';
import '../domain/models/report_doc.dart';
import '../providers/report_editor_provider.dart';
import '../services/image_services.dart';
import 'report_preview_screen.dart';
import '../ui/signature_capture.dart';

class ReportEditorScreen extends StatelessWidget {
  const ReportEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportEditorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Editor'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              await vm.save();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
            },
          ),
          IconButton(
            tooltip: 'Preview',
            icon: const Icon(Icons.preview_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportPreviewScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, vm),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: GestureDetector(
        onTap: vm.clearSelection,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              title: 'Outline',
              child: Column(
                children: [
                  if (vm.doc.roots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text('No sections yet. Tap Add → Add section.'),
                    ),
                  ...vm.doc.roots.map((s) => _sectionWidget(context, vm, s, depth: 0)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _imagesCard(context, vm),
            const SizedBox(height: 12),
            _card(
              title: 'Recommendation',
              child: TextField(
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter recommendation…'),
                onChanged: vm.updateRecommendation,
              ),
            ),
            const SizedBox(height: 12),
            _card(
              title: 'Endoscopist',
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    onChanged: (v) => vm.updateEndoscopist(name: v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Credentials', border: OutlineInputBorder()),
                    onChanged: (v) => vm.updateEndoscopist(credentials: v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            final path = await Navigator.push<String?>(
                              context,
                              MaterialPageRoute(builder: (_) => const SignatureCaptureScreen()),
                            );
                            if (path != null) vm.setSignatureFilePath(path);
                          },
                          icon: const Icon(Icons.draw_outlined),
                          label: Text(vm.doc.signature.signatureFilePath == null ? 'Add Signature' : 'Update Signature'),
                        ),
                      ),
                    ],
                  ),
                  if (vm.doc.signature.signatureFilePath != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(vm.doc.signature.signatureFilePath!), height: 100, fit: BoxFit.contain),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Add actions ----------------
  Future<void> _showAddSheet(BuildContext context, ReportEditorProvider vm) async {
    final hasSelection = vm.selectedSectionId != null;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Add…')),
            ListTile(
              leading: const Icon(Icons.view_agenda_outlined),
              title: const Text('Add section (top level)'),
              onTap: () => Navigator.pop(context, 'section'),
            ),
            if (hasSelection) ...[
              ListTile(
                leading: const Icon(Icons.subdirectory_arrow_right),
                title: const Text('Add subsection (under selected)'),
                onTap: () => Navigator.pop(context, 'subsection'),
              ),
              ListTile(
                leading: const Icon(Icons.notes_outlined),
                title: const Text('Add content (under selected)'),
                onTap: () => Navigator.pop(context, 'content'),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'section') {
      final title = await _promptText(context, 'New section');
      if (title != null && title.trim().isNotEmpty) vm.addTopLevelSection(title);
    } else if (action == 'subsection') {
      final title = await _promptText(context, 'New subsection');
      if (title != null && title.trim().isNotEmpty) vm.addSubsectionUnderSelected(title);
    } else if (action == 'content') {
      vm.addContentUnderSelected();
    }
  }

  Future<String?> _promptText(BuildContext context, String title) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Type a name…')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Add')),
        ],
      ),
    );
  }

  // ---------------- UI blocks ----------------
  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }

  Widget _imagesCard(BuildContext context, ReportEditorProvider vm) {
    return Card(
      child: ListTile(
        title: const Text('Images'),
        subtitle: Text(
          'Selected: ${vm.doc.images.length} • '
          'Mode: ${vm.doc.placementChoice == ImagePlacementChoice.inlinePage1 ? "Inline enabled (max 12)" : "Attachments only (max 8)"}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openImagesManager(context, vm),
      ),
    );
  }

  Future<void> _openImagesManager(BuildContext context, ReportEditorProvider vm) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _ImagesManager(vm: vm),
        ),
      ),
    );
  }

  Widget _sectionWidget(BuildContext context, ReportEditorProvider vm, SectionNode section, {required int depth}) {
    final indent = depth * 16.0;
    final selected = vm.selectedSectionId == section.id;
    final hasChildren = section.children.isNotEmpty;

    final style = TextStyle(
      fontWeight: section.style.bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: section.style.level == HeadingLevel.h1 ? 18 : section.style.level == HeadingLevel.h2 ? 16 : 14,
    );

    final align = switch (section.style.align) {
      TitleAlign.left => Alignment.centerLeft,
      TitleAlign.center => Alignment.center,
      TitleAlign.right => Alignment.centerRight,
    };

    return Padding(
      padding: EdgeInsets.only(left: indent, top: 8),
      child: Column(
        children: [
          Material(
            color: selected ? Colors.teal.shade500.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => vm.selectSection(section.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    if (hasChildren)
                      InkWell(
                        onTap: () => vm.toggleCollapsed(section.id),
                        child: Icon(section.collapsed ? Icons.chevron_right : Icons.expand_more),
                      )
                    else
                      const SizedBox(width: 24),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Align(alignment: align, child: Text(section.title, style: style)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: () => _showSectionEditMenu(context, vm, section),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!section.collapsed)
            ...section.children.map((child) {
              if (child is ContentNode) {
                return Padding(
                  padding: EdgeInsets.only(left: indent + 26, top: 8),
                  child: TextField(
                    minLines: 2,
                    maxLines: 6,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter text…'),
                    onChanged: (v) => vm.updateContent(child.id, v),
                  ),
                );
              }
              if (child is SectionNode) return _sectionWidget(context, vm, child, depth: depth + 1);
              return const SizedBox.shrink();
            }),
        ],
      ),
    );
  }

  Future<void> _showSectionEditMenu(BuildContext context, ReportEditorProvider vm, SectionNode section) async {
    final res = await showModalBottomSheet<_SectionEditResult>(
      context: context,
      showDragHandle: true,
      builder: (_) => _SectionEditSheet(section: section),
    );
    if (res == null) return;

    if (res.rename != null && res.rename!.trim().isNotEmpty) {
      vm.renameSection(section.id, res.rename!);
    }
    if (res.style != null) {
      vm.updateSectionStyle(section.id, res.style!);
    }
  }
}

class _SectionEditResult {
  final String? rename;
  final TitleStyle? style;
  const _SectionEditResult({this.rename, this.style});
}

class _SectionEditSheet extends StatefulWidget {
  final SectionNode section;
  const _SectionEditSheet({required this.section});

  @override
  State<_SectionEditSheet> createState() => _SectionEditSheetState();
}

class _SectionEditSheetState extends State<_SectionEditSheet> {
  late final TextEditingController _title;
  late HeadingLevel _level;
  late bool _bold;
  late TitleAlign _align;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.section.title);
    _level = widget.section.style.level;
    _bold = widget.section.style.bold;
    _align = widget.section.style.align;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Edit section')),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<HeadingLevel>(
                    value: _level,
                    decoration: const InputDecoration(labelText: 'Size'),
                    items: HeadingLevel.values
                        .map((h) => DropdownMenuItem(value: h, child: Text(h.name.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setState(() => _level = v ?? _level),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<TitleAlign>(
                    value: _align,
                    decoration: const InputDecoration(labelText: 'Align'),
                    items: TitleAlign.values
                        .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _align = v ?? _align),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              value: _bold,
              onChanged: (v) => setState(() => _bold = v),
              title: const Text('Bold title'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _SectionEditResult(
                    rename: _title.text.trim(),
                    style: widget.section.style.copyWith(level: _level, bold: _bold, align: _align),
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagesManager extends StatefulWidget {
  final ReportEditorProvider vm;
  const _ImagesManager({required this.vm});

  @override
  State<_ImagesManager> createState() => _ImagesManagerState();
}

class _ImagesManagerState extends State<_ImagesManager> {
  final _imageService = ImageService();

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(title: Text('Images')),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<ImagePlacementChoice>(
                segments: const [
                  ButtonSegment(value: ImagePlacementChoice.attachmentsOnly, label: Text('Attachments only')),
                  ButtonSegment(value: ImagePlacementChoice.inlinePage1, label: Text('Inline Page 1')),
                ],
                selected: {vm.doc.placementChoice},
                onSelectionChanged: (s) {
                  try {
                    vm.setPlacementChoice(s.first);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Max images in this mode: ${vm.doc.maxImages}'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    final files = await _imageService.pickMultiFromGallery();
                    if (files.isEmpty) return;
                    vm.addImages(files.map((f) => f.path).toList());
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  try {
                    final file = await _imageService.pickFromCamera();
                    if (file == null) return;
                    vm.addImages([file.path]);
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                },
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (vm.doc.images.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No images added yet.'),
          )
        else
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: vm.doc.images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (_, i) {
                final img = vm.doc.images[i];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(img.filePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(32, 32),
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          vm.removeImage(img.id);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
