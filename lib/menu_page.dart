import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signal_app/bookmark_page.dart';
import 'package:signal_app/events_page.dart';
import 'package:signal_app/intro_page.dart';
import 'package:signal_app/packages_page.dart';
import 'package:signal_app/payment_method.dart';
import 'package:signal_app/sentiment_page.dart';
import 'package:signal_app/settings.dart';
import 'package:signal_app/transaction_history.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MenuPage extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;
  final String? userName;
  final String? profileImg;

  const MenuPage(
      {super.key,
      required this.onToggleDarkMode,
      required this.isDarkMode,
      this.userName,
      this.profileImg});

  @override
  // ignore: library_private_types_in_public_api
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with WidgetsBindingObserver {
  final storage = const FlutterSecureStorage();
  late SharedPreferences prefs;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _logout() async {
    final String? accessToken = await storage.read(key: 'accessToken');

    if (accessToken == null) {
      _showCustomSnackBar(
        context,
        'You are not logged in.',
        isError: true,
      );

      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://signal.payguru.com.ng/api/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showCustomSnackBar(
          context,
          'Logged out successfully!',
          isError: false,
        );

        await storage.delete(key: 'accessToken');
        await prefs.remove('user');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => IntroPage(
                onToggleDarkMode: widget.onToggleDarkMode,
                isDarkMode: widget.isDarkMode),
          ),
        );
      } else if (response.statusCode == 401) {
        final String message = responseData['message'] ?? 'Unauthorized';
        _showCustomSnackBar(
          context,
          'Error: $message',
          isError: true,
        );
      } else {
        _showCustomSnackBar(
          context,
          'An unexpected error occurred. Please try again.',
          isError: true,
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        context,
        'Failed to connect to the server. Please check your internet connection.',
        isError: true,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to log out?'),
              actions: <Widget>[
                Row(
                  children: [
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Inter'),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Dismiss the dialog
                      },
                    ),
                    const Spacer(),
                    if (isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Colors.red,
                        ),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                          });

                          _logout().then((_) {
                            // Navigator.of(context)
                            //     .pop(); // Dismiss dialog after logout
                          }).catchError((error) {
                            setState(() {
                              isLoading = false;
                            });
                          });
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Inter'),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  height: orientation == Orientation.portrait
                      ? MediaQuery.of(context).size.height * 1.5
                      : MediaQuery.of(context).size.height * 2.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
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
                                height: 50,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(children: [
                          if (widget.profileImg == null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(55),
                              child: Container(
                                width:
                                    (35 / MediaQuery.of(context).size.width) *
                                        MediaQuery.of(context).size.width,
                                height:
                                    (35 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                color: Colors.grey,
                                child: Image.asset(
                                  'images/Pexels Photo by 3Motional Studio.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else if (widget.profileImg != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(55),
                              child: Container(
                                width:
                                    (35 / MediaQuery.of(context).size.width) *
                                        MediaQuery.of(context).size.width,
                                height:
                                    (35 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                color: Colors.grey,
                                child: Image.network(
                                  widget.profileImg!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),
                          if (widget.userName != null)
                            Text(
                              widget.userName!,
                              style: const TextStyle(
                                fontFamily: 'GolosText',
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          else
                            const CircularProgressIndicator(
                                color: Colors.black),
                        ]),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentMethod(
                                    key: UniqueKey(),
                                    onToggleDarkMode: widget.onToggleDarkMode,
                                    isDarkMode: widget.isDarkMode),
                              ),
                            );
                          },
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/ic_round-add-card.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Payment Method',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // SizedBox(
                      //     height: MediaQuery.of(context).size.height * 0.05),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      //   child: InkWell(
                      //     onTap: () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //           builder: (context) =>
                      //               EventsPage(key: UniqueKey()),
                      //         ),
                      //       );
                      //     },
                      //     child: Container(
                      //       height: (50 / MediaQuery.of(context).size.height) *
                      //           MediaQuery.of(context).size.height,
                      //       padding: const EdgeInsets.all(10.0),
                      //       decoration: BoxDecoration(
                      //         color:
                      //             isDarkMode ? Colors.grey[900] : Colors.white,
                      //         borderRadius: BorderRadius.circular(5),
                      //         boxShadow: [
                      //           BoxShadow(
                      //             color: isDarkMode
                      //                 ? Colors.grey.withOpacity(0.2)
                      //                 : Colors.grey.withOpacity(0.5),
                      //             spreadRadius: 3,
                      //             blurRadius: 5,
                      //           ),
                      //         ],
                      //       ),
                      //       child: Row(
                      //         children: [
                      //           SizedBox(
                      //               width: MediaQuery.of(context).size.width *
                      //                   0.02),
                      //           Image.asset(
                      //             'images/carbon_event.png',
                      //             color:
                      //                 Theme.of(context).colorScheme.onSurface,
                      //           ),
                      //           SizedBox(
                      //               width: MediaQuery.of(context).size.width *
                      //                   0.04),
                      //           Text(
                      //             'Events',
                      //             style: TextStyle(
                      //               fontFamily: 'Inter',
                      //               fontSize: 15,
                      //               fontWeight: FontWeight.bold,
                      //               color:
                      //                   Theme.of(context).colorScheme.onSurface,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SentimentPage(key: UniqueKey()),
                              ),
                            );
                          },
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/fluent-mdl2_sentiment-analysis.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Sentiment',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PackagesPage(key: UniqueKey()),
                              ),
                            );
                          },
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/Packages-dollarsign.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Packages',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {},
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/Referrals.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Referrals',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AccountSettings(
                                    key: UniqueKey(),
                                    onToggleDarkMode: widget.onToggleDarkMode,
                                    isDarkMode: widget.isDarkMode),
                              ),
                            );
                          },
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/solar_settings-outline.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TransactionHistory(key: UniqueKey()),
                              ),
                            );
                          },
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/grommet-icons_transaction.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Transaction History',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {},
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/fluent_person-support-16-regular.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Customer Support',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    BookmarkPage(key: UniqueKey()),
                              ),
                            );
                          },
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/bookmark.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Bookmarks',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: InkWell(
                          onTap: () {
                            _showLogoutConfirmationDialog();
                          },
                          child: Container(
                            height: (50 / MediaQuery.of(context).size.height) *
                                MediaQuery.of(context).size.height,
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode
                                      ? Colors.grey.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.02),
                                Image.asset(
                                  'images/material-symbols-light_logout-sharp.png',
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.04),
                                Text(
                                  'Log out',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
