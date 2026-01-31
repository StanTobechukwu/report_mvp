import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_info_provider.dart';

class SubjectInfoTemplateEditor extends StatefulWidget {
  const SubjectInfoTemplateEditor({super.key});

  @override
  State<SubjectInfoTemplateEditor> createState() => _SubjectInfoTemplateEditorState();
}

class _SubjectInfoTemplateEditorState extends State<SubjectInfoTemplateEditor> {
  void _renameDialog(BuildContext context, String fieldId, String currentTitle) {
    final c = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename field'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          Consumer<SubjectInfoProvider>(
            builder: (_, p, __) => FilledButton(
              onPressed: () {
                p.renameFieldTitle(fieldId, c.text.trim().isEmpty ? currentTitle : c.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          )
        ],
      ),
    ).then((_) => c.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectInfoProvider>(
      builder: (context, p, _) {
        final fields = p.fields;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Subject Info (Template)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: p.enabled,
                      onChanged: p.setEnabled,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Columns:'),
                    const SizedBox(width: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1')),
                        ButtonSegment(value: 2, label: Text('2')),
                      ],
                      selected: {p.columns},
                      onSelectionChanged: (s) => p.setColumns(s.first),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () => p.addCustomField(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add field'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fields.length,
                  onReorder: p.reorderFields,
                  itemBuilder: (_, i) {
                    final f = fields[i];
                    return ListTile(
                      key: ValueKey(f.fieldId),
                      title: Text(f.title),
                      subtitle: Text(f.isSystem ? 'System field' : 'Custom field'),
                      leading: const Icon(Icons.drag_handle),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Checkbox(
                            value: f.required,
                            onChanged: (v) => p.toggleRequired(f.fieldId, v ?? false),
                          ),
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _renameDialog(context, f.fieldId, f.title),
                          ),
                          if (!f.isSystem)
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => p.removeField(f.fieldId),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
