import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'edit_profile.dart'; // Update with your actual import
import 'package:signal_app/settings.dart'; // Update with your actual import
import 'package:signal_app/packages_page.dart'; // Update with your actual import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:signal_app/intro_page.dart';

class UserPage extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;

  const UserPage(
      {super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();
  String? profileImg;
  String? userName;
  late SharedPreferences prefs;
  bool _isRefreshing = false;
  bool isLoading = false;
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    await _details();
    userName = await getUserName();
    profileImg = await getProfileImg();
    if (mounted) {
      setState(() {});
    }
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

  Future<String?> getUserName() async {
    final String? userJson = prefs.getString('user');
    if (userJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return userMap['name'];
    } else {
      return null;
    }
  }

  Future<String?> getProfileImg() async {
    final String? userJson = prefs.getString('user');

    if (userJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return userMap['profile_photo']; // Fetch the outer profile photo
    } else {
      return null;
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Check for internet connection
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        _showNoInternetDialog(context);
        setState(() {
          _isRefreshing = false;
        });
        return;
      }

      // Set a timeout for the entire refresh operation
      await Future.any([
        Future.delayed(const Duration(seconds: 15), () {
          throw TimeoutException('The operation took too long.');
        }),
        _performDataFetch(),
      ]);
    } catch (e) {
      if (e is TimeoutException) {
        _showTimeoutDialog(context);
      } else {
        _showErrorDialog(context, e.toString());
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _performDataFetch() async {
    await _details();
    userName = await getUserName();
    profileImg = await getProfileImg();
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Internet Connection'),
          content: const Text(
            'It looks like you are not connected to the internet. Please check your connection and try again.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                _refreshData();
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showTimeoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Timed Out'),
          content: const Text(
            'The operation took too long to complete. Please try again later.',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                _refreshData();
              },
            ),
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(
            'An error occurred: $error',
            style: const TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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

  Future<void> _details() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      const url = 'https://signal.payguru.com.ng/api/details';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Access user data inside the "0" key and total_signals
        final Map<String, dynamic> user = responseData['0'];
        final int totalSignals = responseData['total_signals'];
        final String profilePhoto = responseData['profile_photo'];

        // Add total_signals to the user map before saving (optional)
        user['total_signals'] = totalSignals;

        // Update the user map with the latest profile_photo
        user['profile_photo'] = profilePhoto;

        // Save the user data in shared preferences, overwriting previous data
        await prefs.setString('user', jsonEncode(user));
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false; // Failed to load data
            errorMessage = 'Failed to load details';
          });
        }
        print('Failed to load details');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage =
              'Failed to load data. Please check your network connection.';
        });
      }
      print('Exception caught: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            color: Theme.of(context).colorScheme.onSurface,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Row(
                    children: [
                      Spacer(),
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 22.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Center(
                    child: Stack(
                      children: [
                        if (profileImg == null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(55),
                            child: Container(
                              width: (111 / MediaQuery.of(context).size.width) *
                                  MediaQuery.of(context).size.width,
                              height:
                                  (111 / MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                              color: Colors.grey,
                              child: Image.asset(
                                'images/Pexels Photo by 3Motional Studio.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else if (profileImg != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(55),
                            child: Container(
                              width: (111 / MediaQuery.of(context).size.width) *
                                  MediaQuery.of(context).size.width,
                              height:
                                  (111 / MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                              color: Colors.grey,
                              child: Image.network(
                                profileImg!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfile(
                                      key: UniqueKey(),
                                      profileImgUrl: profileImg ?? "",
                                      name: userName ?? "",
                                      onToggleDarkMode: widget.onToggleDarkMode,
                                      isDarkMode: widget.isDarkMode),
                                ),
                              );
                            },
                            child: Image.asset(
                              height: 40,
                              'images/profile_edit.png',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Center(
                    child: userName != null
                        ? Text(
                            userName!,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          )
                        : CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onSurface),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/weui_location-outlined.png',
                      ),
                      Text(
                        'Address Here',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
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
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
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
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/solar_settings-outline-black.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
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
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/Packages-dollarsign-black.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'Manage Subscription',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      height: (50 / MediaQuery.of(context).size.height) *
                          MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
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
                              width: MediaQuery.of(context).size.width * 0.02),
                          Image.asset(
                            'images/fluent_person-support-16-regular-black.png',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.04),
                          Text(
                            'Customer Support',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
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
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/material-symbols-light_logout-sharp-black.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'Log out',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
