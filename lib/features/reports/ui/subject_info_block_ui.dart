import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subject_info_provider.dart';

class SubjectInfoBlock extends StatefulWidget {
  const SubjectInfoBlock({super.key});

  @override
  State<SubjectInfoBlock> createState() => _SubjectInfoBlockState();
}

class _SubjectInfoBlockState extends State<SubjectInfoBlock> {
  final Map<String, TextEditingController> _controllers = {};
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String fieldId, String initial) {
    return _controllers.putIfAbsent(
      fieldId,
      () => TextEditingController(text: initial),
    );
  }

  void _syncControllers(SubjectInfoProvider p) {
    for (final f in p.fields) {
      final text = p.values.of(f.fieldId);
      final c = _controllerFor(f.fieldId, text);
      if (c.text != text) c.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubjectInfoProvider>(
      builder: (context, p, _) {
        _syncControllers(p);

        if (!p.enabled) return const SizedBox.shrink();

        final fieldWidgets = p.fields.map((f) {
          final controller = _controllerFor(f.fieldId, p.values.of(f.fieldId));
          final error = _errors[f.fieldId];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: f.required ? '${f.title} *' : f.title,
                errorText: error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                p.setValue(f.fieldId, v);
                if (_errors.isNotEmpty) {
                  setState(() => _errors = p.validate());
                }
              },
            ),
          );
        }).toList();

        Widget body;
        if (p.columns == 2) {
          body = LayoutBuilder(
            builder: (context, c) {
              final half = (c.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                children: fieldWidgets
                    .map((w) => SizedBox(width: half, child: w))
                    .toList(),
              );
            },
          );
        } else {
          body = Column(children: fieldWidgets);
        }

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
                        'Subject Info',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _errors = p.validate()),
                      child: const Text('Validate'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                body,
              ],
            ),
          ),
        );
      },
    );
  }
}
