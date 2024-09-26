import 'package:flutter/material.dart';
import 'package:signal_app/intro_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signal_app/main_app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final accessToken = await storage.read(key: 'accessToken');
  final bool isLoggedIn = accessToken != null;
  runApp(MyApp(isLoggedIn: accessToken != null));
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Signal App',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        fontFamily: 'Inconsolata', // Apply custom font
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Inconsolata',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      home: isLoggedIn ? MainApp(key: UniqueKey()) : const IntroPage(),
    );
  }
}
