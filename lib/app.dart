import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartnote_flutter/providers/receipt_provider.dart';
import 'package:smartnote_flutter/screens/history_screen.dart';
import 'package:smartnote_flutter/screens/home_screen.dart';
import 'package:smartnote_flutter/screens/report_screen.dart';

class SmartNoteApp extends StatefulWidget {
  const SmartNoteApp({super.key});
  @override
  State<SmartNoteApp> createState() => _SmartNoteAppState();
}

class _SmartNoteAppState extends State<SmartNoteApp> {
  int _tabIndex = 0;

  final _tabs = const [
    HomeScreen(),
    HistoryScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReceiptProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartNote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          useMaterial3: true,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('SmartNote: Digitalisasi Nota')),
          body: _tabs[_tabIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
              NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Laporan'),
            ],
          ),
        ),
      ),
    );
  }
}
