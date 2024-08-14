import 'package:flutter/material.dart';
import 'package:signal_app/intro_page.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signal App',
      theme: ThemeData(
        // brightness: Brightness.dark, // Sets the black theme color
        primarySwatch: Colors.grey, // Custom swatch with a neutral color
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({Key? key});

  @override
  Widget build(BuildContext context) {
    return const IntroPage();
    // return StreamBuilder<User?>(
    //   stream: FirebaseAuth.instance.authStateChanges(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return const Scaffold(
    //         body: Center(
    //           child: CircularProgressIndicator(),
    //         ),
    //       );
    //     } else if (snapshot.hasData) {
    //       return MainAppHome(key: UniqueKey());
    //     } else {
    //       return const SignUpPage();
    //     }
    //   },
    // );
  }
}
