import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signal_app/sign_in_page.dart';

class ForgotPassword extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;
  const ForgotPassword({super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  ForgotPasswordState createState() => ForgotPasswordState();
}

class ForgotPasswordState extends State<ForgotPassword>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController password2Controller = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _tokenFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _password2FocusNode = FocusNode();

  bool isLoading = false;
  bool isLoading2 = false;
  final storage = const FlutterSecureStorage();
  late SharedPreferences prefs;
  bool _isPasswordVisible = false;
  bool _isPasswordVisible2 = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _resetPasswordRequest() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      _showCustomSnackBar(
        context,
        'Email is required.',
        isError: true,
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://script.teendev.dev/signal/api/passowrd/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      _showCustomSnackBar(
        context,
        'Reset link sent successfully.',
        isError: false,
      );
    } else {
      final responseBody = response.body;
      _showCustomSnackBar(
        context,
        'Error: $responseBody',
        isError: true,
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _resetPassword() async {
    final String email = emailController.text.trim();
    final String token = tokenController.text.trim();
    final String password = passwordController.text.trim();
    final String passwordConfirmation = password2Controller.text.trim();

    if (email.isEmpty ||
        token.isEmpty ||
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

    setState(() {
      isLoading2 = true;
    });

    final response = await http.post(
      Uri.parse('https://script.teendev.dev/signal/api/passowrd/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'token': token,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 200) {
      _showCustomSnackBar(
        context,
        'Password reset successful.',
        isError: false,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignInPage(key: UniqueKey(), onToggleDarkMode: widget.onToggleDarkMode,
              isDarkMode: widget.isDarkMode),
        ),
      );
    } else {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _showCustomSnackBar(
        context,
        'Error: ${responseData['error']}',
        isError: true,
      );
    }

    setState(() {
      isLoading2 = false;
    });
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
    return Scaffold(
      body: // Reset Password Tab
      SingleChildScrollView(
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
                      'images/tabler_arrow-back.png',height:50,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 10,
                    child: Text(
                      'Forgot Password',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 22.0,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            SizedBox(height: MediaQuery
                .of(context)
                .size
                .height * 0.05),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Email',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.onSurface,
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
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                cursorColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: MediaQuery
                .of(context)
                .size
                .height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Token',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: tokenController,
                focusNode: _tokenFocusNode,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
                decoration: InputDecoration(
                  labelText: '',
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
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                cursorColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: MediaQuery
                .of(context)
                .size
                .height * 0.02),
            Container(
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
                onPressed: isLoading ? null : _resetPasswordRequest,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white;
                      }
                      return Colors.black;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.black;
                      }
                      return Colors.white;
                    },
                  ),
                  elevation: WidgetStateProperty.all<double>(4.0),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text('Request Token'),
              ),
            ),
            SizedBox(height: MediaQuery
                .of(context)
                .size
                .height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'New Password',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.onSurface,
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
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
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
                cursorColor: Theme.of(context).colorScheme.onSurface,
                obscureText: !_isPasswordVisible,
                obscuringCharacter: "*",
              ),
            ),
            SizedBox(height: MediaQuery
                .of(context)
                .size
                .height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Retype Password',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.onSurface,
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
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface,
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
                cursorColor: Theme.of(context).colorScheme.onSurface,
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
                onPressed: isLoading2 ? null : () => _resetPassword(),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.white;
                      }
                      return Colors.black;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.black;
                      }
                      return Colors.white;
                    },
                  ),
                  elevation: WidgetStateProperty.all<double>(4.0),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                  ),
                ),
                child: isLoading2
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text('Reset Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
