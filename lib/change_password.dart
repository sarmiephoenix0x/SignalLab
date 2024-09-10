import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  ChangePasswordState createState() => ChangePasswordState();
}

class ChangePasswordState extends State<ChangePassword>
    with SingleTickerProviderStateMixin {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController password2Controller = TextEditingController();

  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _password2FocusNode = FocusNode();

  bool isLoading = false;
  final storage = const FlutterSecureStorage();
  late SharedPreferences prefs;
  bool _isPasswordVisible = false;
  bool _isPasswordVisible2 = false;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> _resetPassword() async {
    final String currentPassword = currentPasswordController.text.trim();
    final String password = passwordController.text.trim();
    final String passwordConfirmation = password2Controller.text.trim();

    if (currentPassword.isEmpty ||
        password.isEmpty ||
        passwordConfirmation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current Password must be at least 6 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New Password must be at least 6 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != passwordConfirmation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://script.teendev.dev/signal/api/passowrd/reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successful.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${responseData['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: // Reset Password Tab
          SingleChildScrollView(
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
                  const Expanded(
                    flex: 10,
                    child: Text(
                      'Change Password',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 22.0,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: currentPasswordController,
                focusNode: _currentPasswordFocusNode,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
                decoration: InputDecoration(
                    labelText: 'Current Password',
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: passwordController,
                focusNode: _passwordFocusNode,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
                decoration: InputDecoration(
                    labelText: 'New Password',
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                controller: password2Controller,
                focusNode: _password2FocusNode,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
                decoration: InputDecoration(
                    labelText: 'Retype New Password',
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Container(
              width: double.infinity,
              height: (60 / MediaQuery.of(context).size.height) *
                  MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _resetPassword(),
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
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
