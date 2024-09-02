import 'package:flutter/material.dart';
import 'package:signal_app/intro_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signal_app/main_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final accessToken = await storage.read(key: 'accessToken');
  final bool isLoggedIn = accessToken != null;
  runApp(MyApp(isLoggedIn: accessToken != null));
}

//Use this to test the web view

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: WebViewAuth(),
//     );
//   }
// }

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signal App',
      theme: ThemeData(
        // brightness: Brightness.dark, // Sets the black theme color
        primarySwatch: Colors.grey, // Custom swatch with a neutral color
      ),
      home: isLoggedIn ? MainApp(key: UniqueKey()) : const IntroPage(),
    );
  }
}
