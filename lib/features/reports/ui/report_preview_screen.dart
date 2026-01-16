import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../domain/pdf/pdf_plan.dart';
import '../providers/report_editor_provider.dart';
import '../services/pdf_renderer_service.dart';

class ReportPreviewScreen extends StatelessWidget {
  const ReportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportEditorProvider>();
    final renderer = PdfRendererService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save_outlined),
            onPressed: () async {
              await vm.save();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
            },
          )
        ],
      ),
      body: PdfPreview(
        build: (_) async {
          final plan = buildPdfPlan(vm.doc);
          final Uint8List bytes = await renderer.generatePdfBytes(doc: vm.doc, plan: plan);
          return bytes;
        },
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
      ),
    );
  }
}
