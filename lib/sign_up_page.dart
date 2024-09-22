import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:signal_app/sign_up_otp.dart';
import 'package:signal_app/main_app.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with WidgetsBindingObserver {
  final FocusNode _displayNameFocusNode = FocusNode();
  final FocusNode _userNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _password2FocusNode = FocusNode();

  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController password2Controller = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isPasswordVisible2 = false;

  bool dropDownTapped = false;

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

  Future<void> _registerUser() async {
    if (prefs == null) {
      await _initializePrefs();
    }
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String passwordConfirmation = password2Controller.text.trim();
    final String name = displayNameController.text.trim();
    final String username = userNameController.text.trim();
    final String phoneNumber = phoneNumberController.text.trim();

    if (name.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        phoneNumber.isEmpty ||
        password.isEmpty ||
        passwordConfirmation.isEmpty) {
      _showCustomSnackBar(
        context,
        'All fields are required.',
        isError: true,
      );

      return;
    }

    final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showCustomSnackBar(
        context,
        'Please enter a valid email address.',
        isError: true,
      );

      return;
    }

    if (password.length < 6) {
      _showCustomSnackBar(
        context,
        'Password must be at least 6 characters.',
        isError: true,
      );

      return;
    }

    if (password != passwordConfirmation) {
      _showCustomSnackBar(
        context,
        'Passwords do not match.',
        isError: true,
      );

      return;
    }

    if (phoneNumber.length < 11) {
      _showCustomSnackBar(
        context,
        'Phone number must be at least 11 characters.',
        isError: true,
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://script.teendev.dev/signal/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    final Map<String, dynamic> responseData = jsonDecode(response.body);

    print('Response Data: $responseData');

    if (response.statusCode == 201) {
      // The responseData['user'] is a Map, not a String, so handle it accordingly
      final Map<String, dynamic> user = responseData['user'];
      final String accessToken = responseData['access_token'];
      final String profilePhoto = responseData['profile_photo'];

      user['profile_photo'] = profilePhoto;
      await storage.write(key: 'accessToken', value: accessToken);
      await prefs.setString(
          'user', jsonEncode(user)); // Store user as a JSON string

      // Handle successful response
      _showCustomSnackBar(
        context,
        'Sign up successful! Welcome, ${user['name']}',
        isError: false,
      );


      // Navigate to the main app or another page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainApp(key: UniqueKey()),
        ),
      );
    } else if (response.statusCode == 400) {
      setState(() {
        isLoading = false;
      });
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String error = responseData['error'];
      final List<dynamic> data = responseData['data']['email'];

      // Handle validation error
      _showCustomSnackBar(
        context,
        'Error: $error - $data',
        isError: true,
      );
    } else {
      setState(() {
        isLoading = false;
      });
      // Handle other unexpected responses
      _showCustomSnackBar(
        context,
        'An unexpected error occurred.',
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    displayNameController.dispose();
    userNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    password2Controller.dispose();
    super.dispose();
  }

  void _showCustomSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
                    ? MediaQuery
                    .of(context)
                    .size
                    .height * 1.2
                    : MediaQuery
                    .of(context)
                    .size
                    .height * 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.1),
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
                            'Sign up',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.1),
                          const Spacer(),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.05),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Name',
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
                        controller: displayNameController,
                        focusNode: _displayNameFocusNode,
                        style: const TextStyle(
                          fontSize: 16.0,
                          decoration: TextDecoration.none,
                        ),
                        decoration: InputDecoration(
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
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.02),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Username',
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
                        controller: userNameController,
                        focusNode: _userNameFocusNode,
                        style: const TextStyle(
                          fontSize: 16.0,
                          decoration: TextDecoration.none,
                        ),
                        decoration: InputDecoration(
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
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.02),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Email',
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
                        controller: emailController,
                        focusNode: _emailFocusNode,
                        style: const TextStyle(
                          fontSize: 16.0,
                          decoration: TextDecoration.none,
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
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.02),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Phone Number',
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
                      child: Row(
                        children: [
                          Container(
                            height: (55 / MediaQuery
                                .of(context)
                                .size
                                .height) *
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              border: Border.all(width: 1, color: Colors.grey),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/twemoji_flag-nigeria.png',
                                  width: 24.0,
                                  height: 24.0,
                                ),
                                SizedBox(
                                    width: MediaQuery
                                        .of(context)
                                        .size
                                        .width *
                                        0.01),
                                const Text(
                                  '+234',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(
                                    width: MediaQuery
                                        .of(context)
                                        .size
                                        .width *
                                        0.02),
                                if (dropDownTapped == false)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        dropDownTapped = true;
                                      });
                                    },
                                    child: Image.asset(
                                      'images/material-symbols_arrow-drop-down.png',
                                      width: 24.0,
                                      height: 24.0,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        dropDownTapped = false;
                                      });
                                    },
                                    child: Image.asset(
                                      'images/material-symbols_arrow-drop-down-upwards.png',
                                      width: 24.0,
                                      height: 24.0,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.02),
                          Expanded(
                            child: TextFormField(
                              controller: phoneNumberController,
                              focusNode: _phoneNumberFocusNode,
                              style: const TextStyle(
                                fontSize: 16.0,
                                decoration: TextDecoration.none,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                  ),
                                ),
                                counterText: '',
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 11,
                              cursorColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.02),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'New Password',
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
                              decoration: TextDecoration.none,
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
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            )),
                        cursorColor: Colors.black,
                        obscureText: !_isPasswordVisible,
                        obscuringCharacter: "*",
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.02),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Retype Password',
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
                        controller: password2Controller,
                        focusNode: _password2FocusNode,
                        style: const TextStyle(
                          fontSize: 16.0,
                        ),
                        decoration: InputDecoration(
                            labelText: '*******************',
                            labelStyle: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Inter',
                              fontSize: 12.0,
                              decoration: TextDecoration.none,
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
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible2
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible2 = !_isPasswordVisible2;
                                });
                              },
                            )),
                        cursorColor: Colors.black,
                        obscureText: !_isPasswordVisible2,
                        obscuringCharacter: "*",
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.05),
                    Container(
                      width: double.infinity,
                      height: (60 / MediaQuery
                          .of(context)
                          .size
                          .height) *
                          MediaQuery
                              .of(context)
                              .size
                              .height,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLoading == false) {
                            _registerUser();
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
                          'Sign up',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    // const Center(
                    //   child: Text(
                    //     '- Or -',
                    //     style: TextStyle(
                    //       fontFamily: 'Inter',
                    //       fontSize: 13.0,
                    //       fontWeight: FontWeight.bold,
                    //       color: Colors.grey,
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: [
                    //       Image.asset(
                    //         'images/flat-color-icons_google.png',
                    //       ),
                    //       SizedBox(
                    //           width: MediaQuery.of(context).size.width * 0.05),
                    //       Image.asset(
                    //         'images/logos_facebook.png',
                    //       ),
                    //       SizedBox(
                    //           width: MediaQuery.of(context).size.width * 0.05),
                    //       Image.asset(
                    //         'images/bi_apple.png',
                    //       ),
                    //     ],
                    //   ),
                    // ),
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
