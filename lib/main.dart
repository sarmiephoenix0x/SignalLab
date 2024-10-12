import 'package:flutter/material.dart';
import 'package:signal_app/intro_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signal_app/main_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  const storage = FlutterSecureStorage();
  final accessToken = await storage.read(key: 'accessToken');
  final prefs = await SharedPreferences.getInstance();
  bool? isDarkMode =
      prefs.getBool('isDarkMode') ?? false;
  final bool isLoggedIn = accessToken != null;
  runApp(MyApp(isLoggedIn: accessToken != null, isDarkMode: isDarkMode));
}


ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.black,
  iconTheme: const IconThemeData(color: Colors.black),
  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: Colors.black),
    bodyMedium: const TextStyle(color: Colors.black),
    titleLarge: const TextStyle(color: Colors.black),
    labelSmall:
    TextStyle(color: Colors.grey[700]), // More visible grey for labels
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.white,
  iconTheme: const IconThemeData(color: Colors.white),
  textTheme: TextTheme(
    bodyLarge: const TextStyle(color: Colors.white),
    bodyMedium: const TextStyle(color: Colors.white),
    titleLarge: const TextStyle(color: Colors.white),
    labelSmall:
    TextStyle(color: Colors.grey[400]), // Lighter grey for dark mode labels
  ),
);

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final bool isDarkMode;

  const MyApp({Key? key, required this.isLoggedIn, required this.isDarkMode})
      : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  void toggleDarkMode(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Signal Lab',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: widget.isLoggedIn ? MainApp(key: UniqueKey(),
          onToggleDarkMode: toggleDarkMode,
          isDarkMode: _isDarkMode) : IntroPage(
          onToggleDarkMode: toggleDarkMode, isDarkMode: _isDarkMode),
    );
  }
}
