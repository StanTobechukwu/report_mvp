import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/reports/data/reports_repository.dart';
import 'features/reports/providers/report_editor_provider.dart';
import 'features/reports/providers/reports_list_provider.dart';
import 'features/reports/ui/reports_list_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ReportsRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReportEditorProvider(repo: repo)),
        ChangeNotifierProvider(create: (_) => ReportsListProvider(repo: repo)..refresh()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Reporter MVP',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const ReportsListScreen(),
      ),
    );
  }
}
