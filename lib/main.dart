import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  await NotificationService.instance.init();
  final prefs = PreferencesService.instance;
  await prefs.init();
  runApp(SalaryTaxApp(prefs: prefs));
}

class SalaryTaxApp extends StatefulWidget {
  const SalaryTaxApp({super.key, required this.prefs});
  final PreferencesService prefs;
  @override State<SalaryTaxApp> createState() => _SalaryTaxAppState();
}
class _SalaryTaxAppState extends State<SalaryTaxApp> {
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false, title: 'Salary Tax & Expense Manager',
    themeMode: widget.prefs.darkMode ? ThemeMode.dark : ThemeMode.light,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1a56db)), useMaterial3: true, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
    darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1a56db), brightness: Brightness.dark), useMaterial3: true, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder())),
    home: HomeScreen(prefs: widget.prefs, onThemeChanged: () => setState(() {})),
  );
}
