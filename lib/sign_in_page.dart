import 'package:flutter/material.dart';
import 'package:signal_app/main_app.dart';
import 'package:signal_app/sign_up_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with WidgetsBindingObserver {
  final FocusNode _emailOrPhoneNumberFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final TextEditingController emailOrPhoneNumberController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  late SharedPreferences prefs;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _submitForm() async {
    if (prefs == null) {
      await _initializePrefs();
    }
    final String emailOrPhoneNumber = emailOrPhoneNumberController.text.trim();
    final String password = passwordController.text.trim();

    if (emailOrPhoneNumber.isEmpty || password.isEmpty) {
      // Show an error message if any field is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required.'),
        ),
      );
      return;
    }

    // Validate email format
    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(emailOrPhoneNumber)) {
      // Show an error message if email is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
        ),
      );
      return;
    }

    // Validate password length
    if (password.length < 6) {
      // Show an error message if password is too short
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Send the POST request
    final response = await http.post(
      Uri.parse('https://script.teendev.dev/signal/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': emailOrPhoneNumber,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);

    print('Response Data: $responseData');

    if (response.statusCode == 200) {
      // The responseData['user'] is a Map, not a String, so handle it accordingly
      final Map<String, dynamic> user = responseData['user'];
      final String accessToken = responseData['access_token'];

      await storage.write(key: 'accessToken', value: accessToken);
      await prefs.setString(
          'user', jsonEncode(user)); // Store user as a JSON string

      // Handle the successful response here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in successful!'),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainApp(key: UniqueKey()),
        ),
      );
    } else if (response.statusCode == 400) {
      setState(() {
        isLoading = false;
      });
      final String error = responseData['error'];
      final String data = responseData['data'];

      // Handle validation error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error - $data'),
        ),
      );
    } else if (response.statusCode == 401) {
      setState(() {
        isLoading = false;
      });
      final String error = responseData['error'];

      // Handle invalid credentials
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      // Handle other unexpected responses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                height: orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.height
                    : MediaQuery.of(context).size.height * 1.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Image.asset(
                              'images/tabler_arrow-back.png',
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.1),
                          const Spacer(),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    const Center(
                      child: Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 30.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Email / Phone Number',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextFormField(
                        controller: emailOrPhoneNumberController,
                        focusNode: _emailOrPhoneNumberFocusNode,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                        decoration: InputDecoration(
                          labelText: 'example@gmail.com',
                          labelStyle: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        cursorColor: Colors.black,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Password',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16.0,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextFormField(
                        controller: passwordController,
                        focusNode: _passwordFocusNode,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                        decoration: InputDecoration(
                          labelText: '*******************',
                          labelStyle: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        cursorColor: Colors.black,
                        obscureText: true,
                        obscuringCharacter: "*",
                      ),
                    ),
                    const Row(
                      children: [
                        Spacer(),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Forgot password?',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.grey,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 12.0,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Container(
                      width: double.infinity,
                      height: (60 / MediaQuery.of(context).size.height) *
                          MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLoading == false) {
                            _submitForm();
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white;
                              }
                              return Colors.black;
                            },
                          ),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.black;
                              }
                              return Colors.white;
                            },
                          ),
                          elevation: WidgetStateProperty.all<double>(4.0),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                          ),
                        ),
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign in',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    const Center(
                      child: Text(
                        '- Or -',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/flat-color-icons_google.png',
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.05),
                          Image.asset(
                            'images/logos_facebook.png',
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.05),
                          Image.asset(
                            'images/bi_apple.png',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    const Center(
                      child: Text(
                        "Don't have an account?",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Container(
                      width: double.infinity,
                      height: (60 / MediaQuery.of(context).size.height) *
                          MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SignUpPage(key: UniqueKey()),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.black;
                              }
                              return Colors.white;
                            },
                          ),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                            (Set<WidgetState> states) {
                              if (states.contains(WidgetState.pressed)) {
                                return Colors.white;
                              }
                              return Colors.black;
                            },
                          ),
                          elevation: WidgetStateProperty.all<double>(4.0),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            const RoundedRectangleBorder(
                              side: BorderSide(width: 1),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
