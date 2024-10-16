import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signal_app/bookmark_page.dart';
import 'package:signal_app/card_details.dart';
import 'package:signal_app/events_page.dart';
import 'package:signal_app/intro_page.dart';
import 'package:signal_app/news_details.dart';
import 'package:signal_app/notification_page.dart';
import 'package:signal_app/packages_page.dart';
import 'package:signal_app/payment_method.dart';
import 'package:signal_app/sentiment_page.dart';
import 'package:signal_app/settings.dart';
import 'package:signal_app/trading_web_view.dart';
import 'package:signal_app/transaction_history.dart';
import 'package:signal_app/video_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'edit_profile.dart';
import 'dart:math'; // For Random
import 'package:google_mobile_ads/google_mobile_ads.dart'; // For ads

class MainApp extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;

  const MainApp(
      {super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  // ignore: library_private_types_in_public_api
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  DateTime? currentBackPressTime;
  int _currentBottomIndex = 0;
  TabController? homeTab;
  TabController? signalTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _dropDownKey = GlobalKey();
  ValueNotifier<bool> usdtCurrentPriceDropDownActiveTab1 =
  ValueNotifier<bool>(false);
  ValueNotifier<bool> btcCurrentPriceDropDownActiveTab1 =
  ValueNotifier<bool>(false);
  ValueNotifier<bool> usdtCurrentPriceDropDownActiveTab2 =
  ValueNotifier<bool>(false);
  ValueNotifier<bool> btcCurrentPriceDropDownActiveTab2 =
  ValueNotifier<bool>(false);
  ValueNotifier<bool> usdtCurrentPriceDropDownActiveTab3 =
  ValueNotifier<bool>(false);
  final storage = const FlutterSecureStorage();
  late SharedPreferences prefs;
  String? userName;
  String? userBalance;
  String? profileImg;
  int? totalSignal;
  late Future<List<dynamic>> _signalsFuture1;
  late Future<List<dynamic>> _signalsFuture2;
  late Future<List<dynamic>> _signalsFuture3;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool loading = false;
  bool loading2 = false;
  bool loading3 = false;
  int _eduIndex = 0;
  String? errorMessage;
  bool removeFakeSplashScreen = false;
  List<int> adIndices = []; // tracks where ads are placed
  final Random random = Random();
  BannerAd? _bannerAd; // Store the banner ad
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAds(); // Initialize ads
    generateRandomAdIndices(); // Generate random indices for ads
    _initializePrefs();
    fetchCourses();
    fetchNews();
    homeTab = TabController(length: 2, vsync: this);
    homeTab!.addListener(() {
      setState(() {
        _eduIndex = homeTab!.index;
      });
    });
    signalTab = TabController(length: 3, vsync: this);
    _signalsFuture1 = fetchSignals('crypto');
    _signalsFuture2 = fetchSignals('forex');
    _signalsFuture3 = fetchSignals('stocks');
    _scrollController.addListener(() {
      if (_scrollController.offset <= 0) {
        if (_isRefreshing) {
          // Logic to cancel refresh if needed
          setState(() {
            _isRefreshing = false;
          });
        }
      }
    });
  }


// Initialize the BannerAd only once
  void _initializeAds() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/9214589741',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('BannerAd loaded.');
          setState(() {
            _isAdLoaded = true; // Set to true when ad is loaded
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )
      ..load();
  }


  // Generate random indices for ads but ensure ads appear only after the first 5 cards
  void generateRandomAdIndices() {
    adIndices.clear(); // Clear previous indices
    int index = 5; // Start showing ads after the 5th card
    while (index < news.length) {
      index += random.nextInt(5) + 5; // Ensure minimum gap of 5 items
      if (index < news.length) {
        adIndices.add(index);
      }
    }
    setState(() {}); // Ensure the UI updates with the new indices
  }


  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    await _details();
    userName = await getUserName();
    userBalance = await getUserBalance();
    profileImg = await getProfileImg();
    totalSignal = await getTotalSignal();
    if (mounted) {
      setState(() {
        removeFakeSplashScreen = true;
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> news = [];

  Future<void> fetchCourses() async {
    if (mounted) {
      setState(() {
        loading2 = true;
        errorMessage = null; // Reset error message before fetch
      });
    }

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      final response = await http.get(
        Uri.parse('https://script.teendev.dev/signal/api/courses'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            courses =
            List<Map<String, dynamic>>.from(json.decode(response.body));
            loading2 = false;
          });
        }
        print("Courses Loaded");
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final message = json.decode(response.body)['message'];
        print('Error: $message');
        if (mounted) {
          setState(() {
            loading2 = false;
            errorMessage = message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading2 = false;
          errorMessage =
          'Failed to load data. Please check your network connection.';
        });
      }
      print('Exception: $e');
    }
  }

  Future<void> fetchNews() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null; // Reset error message before fetch
      });
    }

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      final response = await http.get(
        Uri.parse('https://script.teendev.dev/signal/api/news'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            news = List<Map<String, dynamic>>.from(json.decode(response.body));
            loading = false;
          });
        }
        print("News Loaded");
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        if (mounted) {
          setState(() {
            loading = false;
            errorMessage = json.decode(response.body)['message'];
          });
        }
        print('Error: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage =
          'Failed to load data. Please check your network connection.';
        });
      }
      print('Exception: $e');
    }
  }

  Future<List<dynamic>> fetchSignals(String type) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('https://script.teendev.dev/signal/api/signal?type=$type'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized access');
    } else if (response.statusCode == 404) {
      throw Exception('No signals available');
    } else if (response.statusCode == 422) {
      throw Exception('Validation error');
    } else {
      throw Exception('Failed to load signals');
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
        Uri.parse('https://script.teendev.dev/signal/api/logout'),
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
            builder: (context) =>
                IntroPage(
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
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onSurface,
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
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onSurface,
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

  void _showPopupMenu(BuildContext context) async {
    final RenderBox renderBox =
    _dropDownKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx,
          position.dy + renderBox.size.height,
          position.dx + renderBox.size.width,
          position.dy),
      items: [
        PopupMenuItem<String>(
          value: 'Share',
          child: Row(
            children: [
              Image.asset(
                'images/share-box-line.png',
              ),
              SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.05,
              ),
              const Text(
                'Share',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Report',
          child: Row(
            children: [
              Image.asset(
                'images/feedback-line.png',
              ),
              SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.05,
              ),
              const Text(
                'Report',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Save',
          child: Row(
            children: [
              Image.asset(
                'images/save-line.png',
              ),
              SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.05,
              ),
              const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Open',
          child: Row(
            children: [
              Image.asset(
                'images/basketball-line.png',
              ),
              SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.05,
              ),
              const Text(
                'Open in browser',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(value);
      }
    });
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'Share':
        break;
      case 'Report':
        break;
      case 'Save':
        break;
      case 'Open':
        break;
    }
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

  Future<String?> getUserBalance() async {
    final String? userJson = prefs.getString('user');
    if (userJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return userMap['balance'];
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

  Future<int?> getTotalSignal() async {
    final String? userJson = prefs.getString('user');
    if (userJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return userMap['total_signals'];
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
    if (_currentBottomIndex == 0) {
      await _details();
      userName = await getUserName();
      userBalance = await getUserBalance();
      await fetchCourses();
      await fetchNews();
    } else if (_currentBottomIndex == 1) {
      _signalsFuture1 = fetchSignals('crypto');
      _signalsFuture2 = fetchSignals('forex');
      _signalsFuture3 = fetchSignals('stocks');
      await Future.wait([_signalsFuture1, _signalsFuture2, _signalsFuture3]);
    } else if (_currentBottomIndex == 2) {
      await fetchNews();
    } else if (_currentBottomIndex == 3) {
      await fetchCourses();
    } else if (_currentBottomIndex == 4) {
      await _details();
      userName = await getUserName();
      profileImg = await getProfileImg();
    }
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
              child: Text('Retry', style: TextStyle(color: Colors.blue)),
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
          title: Text('Error'),
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
              style: TextStyle(color: Theme
                  .of(context)
                  .colorScheme
                  .onSurface),
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
        loading3 = true;
      });
    }

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      const url = 'https://script.teendev.dev/signal/api/details';
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
            loading3 = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            loading3 = false; // Failed to load data
            errorMessage = 'Failed to load details';
          });
        }
        print('Failed to load details');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading3 = false;
          errorMessage =
          'Failed to load data. Please check your network connection.';
        });
      }
      print('Exception caught: $e');
    }
  }


  @override
  void dispose() {
    super.dispose();
    _bannerAd?.dispose();
    homeTab?.dispose();
    signalTab?.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (!didPop) {
          DateTime now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime!) >
                  const Duration(seconds: 2)) {
            currentBackPressTime = now;
            _showCustomSnackBar(
              context,
              'Press back again to exit',
              isError: true,
            );
          } else {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        // appBar: AppBar(
        //   automaticallyImplyLeading: false,
        //   title: const Text(
        //     'Signal Lab',
        //     style: TextStyle(
        //       fontSize: 25,
        //       fontFamily: 'Inter',
        //       fontWeight: FontWeight.w500,
        //     ),
        //   ),
        // ),
        drawer: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
          child: SafeArea(
            child: Drawer(
              child: Container(
                color: Colors.black, // Set your desired background color here
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color:
                        Colors.black, // Set your desired header color here
                      ),
                      padding: const EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 8.0),
                      child: Row(children: [
                        if (profileImg == null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(55),
                            child: Container(
                              width: (35 / MediaQuery
                                  .of(context)
                                  .size
                                  .width) *
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width,
                              height:
                              (35 / MediaQuery
                                  .of(context)
                                  .size
                                  .height) *
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height,
                              color: Colors.grey,
                              child: Image.asset(
                                'images/Pexels Photo by 3Motional Studio.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          if (profileImg != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(55),
                              child: Container(
                                width: (35 / MediaQuery
                                    .of(context)
                                    .size
                                    .width) *
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .width,
                                height:
                                (35 / MediaQuery
                                    .of(context)
                                    .size
                                    .height) *
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .height,
                                color: Colors.grey,
                                child: Image.network(
                                  profileImg!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        SizedBox(
                            width: MediaQuery
                                .of(context)
                                .size
                                .width * 0.03),
                        if (userName != null)
                          Text(
                            userName!,
                            style: const TextStyle(
                              fontFamily: 'GolosText',
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        else
                          const CircularProgressIndicator(color: Colors.black),
                      ]),
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/ic_round-add-card.png',
                      ),
                      title: const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PaymentMethod(key: UniqueKey(),
                                    onToggleDarkMode: widget.onToggleDarkMode,
                                    isDarkMode: widget.isDarkMode),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/carbon_event.png',
                      ),
                      title: const Text(
                        'Events',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventsPage(key: UniqueKey()),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/fluent-mdl2_sentiment-analysis.png',
                      ),
                      title: const Text(
                        'Sentiment',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SentimentPage(key: UniqueKey()),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/Packages-dollarsign.png',
                      ),
                      title: const Text(
                        'Packages',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PackagesPage(key: UniqueKey()),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/Referrals.png',
                      ),
                      title: const Text(
                        'Referrals',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        // Navigate to home or any action you want
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/solar_settings-outline.png',
                        height: 25,
                      ),
                      title: const Text(
                        'Settings',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AccountSettings(
                                    key: UniqueKey(),
                                    onToggleDarkMode: widget.onToggleDarkMode,
                                    isDarkMode: widget.isDarkMode),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/grommet-icons_transaction.png',
                      ),
                      title: const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TransactionHistory(key: UniqueKey()),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/fluent_person-support-16-regular.png',
                        height: 25,
                      ),
                      title: const Text(
                        'Customer Support',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                      },
                    ),
                    ListTile(
                      leading: Image.asset(
                        'images/bookmark.png',
                        height: 25,
                      ),
                      title: const Text(
                        'Bookmarks',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookmarkPage(key: UniqueKey()),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.only(top: 16, left: 16),
                      leading: Image.asset(
                        'images/material-symbols-light_logout-sharp.png',
                        height: 25,
                      ),
                      title: const Text(
                        'Log out',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutConfirmationDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: removeFakeSplashScreen == false
            ? Container(
          color: const Color(0xFFF2F2F2), // Background color
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Scale the image based on the screen size
                    double imageSize = constraints.maxWidth *
                        0.4; // 40% of the screen width
                    return Image.asset(
                      'images/AppLogo.png',
                      width: imageSize.clamp(256.0, 1024.0),
                      // Minimum 256 and maximum 1024
                      height: imageSize.clamp(256.0, 1024.0),
                      fit: BoxFit.contain,
                    );
                  },
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  color: Colors.black,
                ), // Loading indicator
              ],
            ),
          ),
        )
            : _tabBarView(_currentBottomIndex),

        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 5,
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentBottomIndex,
              selectedItemColor: Theme
                  .of(context)
                  .colorScheme
                  .onSurface,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                if (_isRefreshing == false && removeFakeSplashScreen == true) {
                  setState(() {
                    _currentBottomIndex = index;
                  });
                }
              },
              items: [
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/ion_home.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/ion_home_active.png'),
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurface,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/mingcute_signal-fill.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/mingcute_signal-fill_active.png'),
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurface,
                  ),
                  label: 'Signal',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/iconamoon_news-thin.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/iconamoon_news-thin_active.png'),
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurface,
                  ),
                  label: 'News',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/fluent-mdl2_publish-course.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/fluent-mdl2_publish-course_active.png'),
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurface,
                  ),
                  label: 'Course',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/majesticons_user-line.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/majesticons_user-line_active.png'),
                    color: Theme
                        .of(context)
                        .colorScheme
                        .onSurface,
                  ),
                  label: 'User',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBarView(int bottomIndex) {
    return SafeArea(
      child: OrientationBuilder(
        builder: (context, orientation) {
          List<Widget> tabBarViewChildren = [];
          if (bottomIndex == 0) {
            tabBarViewChildren.add(
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshData,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height *
                                      0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        _scaffoldKey.currentState?.openDrawer();
                                      },
                                      child: Image.asset(
                                        'images/tabler_menu_button.png',
                                        height: 50,
                                      ),
                                    ),
                                    const Spacer(),
                                    Image.asset(
                                      'images/tabler_help.png',
                                      height: 50,
                                    ),
                                    Image.asset(
                                      'images/tabler_search.png',
                                      height: 50,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                NotificationPage(
                                                    key: UniqueKey()),
                                          ),
                                        );
                                      },
                                      child: Image.asset(
                                        'images/tabler_no_notification.png',
                                        height: 50,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height *
                                      0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(children: [
                                  if (profileImg == null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(55),
                                      child: Container(
                                        width: (35 /
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .width) *
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .width,
                                        height: (35 /
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .height) *
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .height,
                                        color: Colors.grey,
                                        child: Image.asset(
                                          'images/Pexels Photo by 3Motional Studio.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    if (profileImg != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(55),
                                        child: Container(
                                          width: (35 /
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width) *
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width,
                                          height: (35 /
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .height) *
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .height,
                                          color: Colors.grey,
                                          child: Image.network(
                                            profileImg!,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                  SizedBox(
                                      width: MediaQuery
                                          .of(context)
                                          .size
                                          .width *
                                          0.03),
                                  if (userName != null)
                                    Text(
                                      userName!,
                                      style: const TextStyle(
                                        fontFamily: 'GolosText',
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    CircularProgressIndicator(
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface),
                                ]),
                              ),
                              SizedBox(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height *
                                      0.05),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                                child: Container(
                                  height:
                                  (130 / MediaQuery
                                      .of(context)
                                      .size
                                      .height) *
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border:
                                    Border.all(width: 0, color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Image.asset(
                                        'images/Balance.png',
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      const VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 1.0,
                                        width: 20.0,
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Balance',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery
                                                    .of(context)
                                                    .size
                                                    .height *
                                                    0.02),
                                            if (userBalance != null)
                                              Text(
                                                "\$$userBalance",
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            else
                                              const CircularProgressIndicator(
                                                  color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.02),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                                child: Container(
                                  height:
                                  (130 / MediaQuery
                                      .of(context)
                                      .size
                                      .height) *
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border:
                                    Border.all(width: 0, color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Image.asset(
                                        'images/Package.png',
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      const VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 1.0,
                                        width: 20.0,
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Package',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery
                                                    .of(context)
                                                    .size
                                                    .height *
                                                    0.02),
                                            const Text(
                                              "N/A (validity)",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.02),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                                child: Container(
                                  height:
                                  (130 / MediaQuery
                                      .of(context)
                                      .size
                                      .height) *
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border:
                                    Border.all(width: 0, color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Image.asset(
                                        'images/Signals.png',
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      const VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 1.0,
                                        width: 20.0,
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Signals',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery
                                                    .of(context)
                                                    .size
                                                    .height *
                                                    0.02),
                                            if (totalSignal != null)
                                              Text(
                                                totalSignal!.toString(),
                                                style: const TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              )
                                            else
                                              const CircularProgressIndicator(
                                                  color: Colors.white),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height *
                                      0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  children: [
                                    Text(
                                      "Educational Content",
                                      style: TextStyle(
                                        fontFamily: 'Golos Text',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () {
                                        if (_eduIndex == 0) {
                                          setState(() {
                                            _currentBottomIndex = 2;
                                          });
                                        } else if (_eduIndex == 1) {
                                          setState(() {
                                            _currentBottomIndex = 3;
                                          });
                                        }
                                      },
                                      child: const Text(
                                        "See More",
                                        style: TextStyle(
                                          fontFamily: 'Golos Text',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height *
                                      0.03),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: TabBar(
                                  tabAlignment: TabAlignment.start,
                                  controller: homeTab,
                                  isScrollable: true,
                                  tabs: [
                                    _buildTab('News'),
                                    _buildTab('Courses'),
                                  ],
                                  labelColor:
                                  Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface,
                                  unselectedLabelColor: Colors.grey,
                                  labelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Golos Text',
                                  ),
                                  unselectedLabelStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Golos Text',
                                  ),
                                  labelPadding: EdgeInsets.zero,
                                  indicator: const BoxDecoration(),
                                  indicatorSize: TabBarIndicatorSize.label,
                                  indicatorColor: Colors.orange,
                                  indicatorPadding: const EdgeInsets.only(
                                      left: 16.0, right: 16.0),
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery
                                      .of(context)
                                      .size
                                      .height *
                                      0.03),
                              SizedBox(
                                height:
                                (400 / MediaQuery
                                    .of(context)
                                    .size
                                    .height) *
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .height,
                                child: TabBarView(
                                  controller: homeTab,
                                  children: [
                                    if (loading)
                                      Center(
                                        child: CircularProgressIndicator(
                                            color: Theme
                                                .of(context)
                                                .colorScheme
                                                .onSurface),
                                      )
                                    else
                                      if (errorMessage != null)
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                errorMessage!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed: _refreshData,
                                                child: Text(
                                                  'Retry',
                                                  style: TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: Theme
                                                        .of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        ListView.builder(
                                          itemCount: news.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 20.0,
                                                  right: 20.0,
                                                  top: 10.0),
                                              child: newsCard(news[index]),
                                            );
                                          },
                                        ),
                                    if (loading2)
                                      Center(
                                        child: CircularProgressIndicator(
                                            color: Theme
                                                .of(context)
                                                .colorScheme
                                                .onSurface),
                                      )
                                    else
                                      if (errorMessage != null)
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                errorMessage!,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  color: Colors.red,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed: _refreshData,
                                                child: Text(
                                                  'Retry',
                                                  style: TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                    color: Theme
                                                        .of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        ListView.builder(
                                          itemCount: courses.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 20.0,
                                                  right: 20.0,
                                                  top: 0.0),
                                              child: courseCard(courses[index]),
                                            );
                                          },
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // if (_isRefreshing)
                    //   Container(
                    //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    //     child: const Center(
                    //       child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            );
          } else if (bottomIndex == 1) {
            tabBarViewChildren.add(
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.05),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              Text(
                                'Signal',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.0,
                                  color:
                                  Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color:
                                    Theme
                                        .of(context)
                                        .colorScheme
                                        .onSurface,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Text(
                                  'Results',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    color:
                                    Theme
                                        .of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.03),
                        TabBar(
                          controller: signalTab,
                          tabs: [
                            _buildTab2('Crypto'),
                            _buildTab2('Forex'),
                            _buildTab2('Stocks'),
                          ],
                          labelColor: Theme
                              .of(context)
                              .colorScheme
                              .onSurface,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inconsolata',
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inconsolata',
                          ),
                          labelPadding: EdgeInsets.zero,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorColor:
                          Theme
                              .of(context)
                              .colorScheme
                              .onSurface,
                        ),
                        SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.03),
                        Expanded(
                          child: TabBarView(
                            controller: signalTab,
                            children: [
                              FutureBuilder<List<dynamic>>(
                                future: _signalsFuture1,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator(
                                            color: Theme
                                                .of(context)
                                                .colorScheme
                                                .onSurface));
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'An unexpected error occurred',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: 'Inconsolata',
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshData,
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme
                                                    .of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'No signals available',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshData,
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme
                                                    .of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  List<dynamic> signalsList = snapshot.data!;
                                  final isDarkMode = Theme
                                      .of(context)
                                      .brightness == Brightness.dark;
                                  return RefreshIndicator(
                                    onRefresh: _refreshData,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: signalsList.length +
                                          1, // +1 for the stats container
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0,
                                                right: 20.0,
                                                top: 10.0,
                                                bottom: 5),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.all(12.0),
                                              decoration: BoxDecoration(
                                                color: isDarkMode ? Colors
                                                    .grey[900] : Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isDarkMode
                                                        ? Colors.grey
                                                        .withOpacity(0.2)
                                                        : Colors.grey
                                                        .withOpacity(0.5),
                                                    spreadRadius: 3,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  buildStatRow(
                                                      'Trades last  7 days: ----',
                                                      'Win rate: ----'),
                                                  buildStatRow(
                                                      'Trades last 14 days: ----',
                                                      'Win rate: ----'),
                                                  buildStatRow(
                                                      'Trades last 30 days: ----',
                                                      'Win rate: ----'),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        final signal = signalsList[index -
                                            1]; // -1 to adjust for the stats container

                                        Map<String, dynamic> targetsMap =
                                        jsonDecode(signal['targets']);

                                        return signals(
                                          img: signal['coin_image'],
                                          name: signal['coin'],
                                          entryPrice: signal['entry_price'],
                                          stopLoss: signal['stop_loss'],
                                          currentPrice: signal['current_price'],
                                          targets: targetsMap,
                                          createdAt: signal['created_at'],
                                          insight: signal['insight'],
                                          trend: signal['trend'],
                                          pair: signal['pair'],
                                          analysisNotifier:
                                          ValueNotifier<bool>(false),
                                          currentPriceNotifier:
                                          ValueNotifier<bool>(false),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              FutureBuilder<List<dynamic>>(
                                future: _signalsFuture2,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator(
                                            color: Theme
                                                .of(context)
                                                .colorScheme
                                                .onSurface));
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'An unexpected error occurred',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontFamily: 'Inconsolata',
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshData,
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme
                                                    .of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'No signals available',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshData,
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme
                                                    .of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  List<dynamic> signalsList = snapshot.data!;
                                  final isDarkMode = Theme
                                      .of(context)
                                      .brightness == Brightness.dark;
                                  return RefreshIndicator(
                                    onRefresh: _refreshData,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: signalsList.length +
                                          1, // +1 for the stats container
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0,
                                                right: 20.0,
                                                top: 10.0,
                                                bottom: 5),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.all(12.0),
                                              decoration: BoxDecoration(
                                                color: isDarkMode ? Colors
                                                    .grey[900] : Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isDarkMode
                                                        ? Colors.grey
                                                        .withOpacity(0.2)
                                                        : Colors.grey
                                                        .withOpacity(0.5),
                                                    spreadRadius: 3,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  buildStatRow(
                                                      'Trades last 7 days: ----',
                                                      'Win rate: ----'),
                                                  buildStatRow(
                                                      'Trades last 14 days: ----',
                                                      'Win rate: ----'),
                                                  buildStatRow(
                                                      'Trades last 30 days: ----',
                                                      'Win rate: ----'),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        final signal = signalsList[index -
                                            1]; // -1 to adjust for the stats container

                                        Map<String, dynamic> targetsMap =
                                        jsonDecode(signal['targets']);

                                        return signals(
                                          img: signal['coin_image'],
                                          name: signal['coin'],
                                          entryPrice: signal['entry_price'],
                                          stopLoss: signal['stop_loss'],
                                          currentPrice: signal['current_price'],
                                          targets: targetsMap,
                                          createdAt: signal['created_at'],
                                          insight: signal['insight'],
                                          trend: signal['trend'],
                                          pair: signal['pair'],
                                          analysisNotifier:
                                          ValueNotifier<bool>(false),
                                          currentPriceNotifier:
                                          ValueNotifier<bool>(false),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              FutureBuilder<List<dynamic>>(
                                future: _signalsFuture3,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator(
                                            color: Theme
                                                .of(context)
                                                .colorScheme
                                                .onSurface));
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'An unexpected error occurred',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshData,
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme
                                                    .of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'No signals available',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              color: Colors.red,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _refreshData,
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme
                                                    .of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  List<dynamic> signalsList = snapshot.data!;
                                  final isDarkMode = Theme
                                      .of(context)
                                      .brightness == Brightness.dark;
                                  return RefreshIndicator(
                                    onRefresh: _refreshData,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      itemCount: signalsList.length +
                                          1, // +1 for the stats container
                                      itemBuilder: (context, index) {
                                        if (index == 0) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0,
                                                right: 20.0,
                                                top: 10.0,
                                                bottom: 5),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.all(12.0),
                                              decoration: BoxDecoration(
                                                color: isDarkMode ? Colors
                                                    .grey[900] : Colors.white,
                                                borderRadius:
                                                BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: isDarkMode
                                                        ? Colors.grey
                                                        .withOpacity(0.2)
                                                        : Colors.grey
                                                        .withOpacity(0.5),
                                                    spreadRadius: 3,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  buildStatRow(
                                                      'Trades last 7 days: ----',
                                                      'Win rate: ----'),
                                                  buildStatRow(
                                                      'Trades last 14 days: ----',
                                                      'Win rate: ----'),
                                                  buildStatRow(
                                                      'Trades last 30 days: ----',
                                                      'Win rate: ----'),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        final signal = signalsList[index -
                                            1]; // -1 to adjust for the stats container

                                        Map<String, dynamic> targetsMap =
                                        jsonDecode(signal['targets']);

                                        return signals(
                                          img: signal['coin_image'],
                                          name: signal['coin'],
                                          entryPrice: signal['entry_price'],
                                          stopLoss: signal['stop_loss'],
                                          currentPrice: signal['current_price'],
                                          targets: targetsMap,
                                          createdAt: signal['created_at'],
                                          insight: signal['insight'],
                                          trend: signal['trend'],
                                          pair: signal['pair'],
                                          analysisNotifier:
                                          ValueNotifier<bool>(false),
                                          currentPriceNotifier:
                                          ValueNotifier<bool>(false),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // if (_isRefreshing)
                    //   Container(
                    //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    //     child: const Center(
                    //       child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            );
          } else if (bottomIndex == 2) {
            tabBarViewChildren.add(
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.05),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'News',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.02),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshData,
                            child: loading
                                ? Center(
                              child: CircularProgressIndicator(
                                  color: Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface),
                            )
                                : errorMessage != null
                                ? Center(
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Inconsolata',
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshData,
                                    child: Text(
                                      'Retry',
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : ListView.builder(
                              controller: _scrollController,
                              itemCount: news.length + adIndices.length,
                              itemBuilder: (context, index) {
                                // Check if the current index should display an ad
                                if (adIndices.contains(index)) {
                                  // Show the BannerAd
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0, vertical: 10.0),
                                    child: Container(
                                      height: 100, // Adjust height as needed
                                      child: _isAdLoaded
                                          ? AdWidget(ad: _bannerAd!)
                                          : const SizedBox
                                          .shrink(), // Show nothing if ad isn't loaded
                                    ),
                                  );
                                }

                                // Calculate actual news index by subtracting the number of ads shown so far
                                final newsIndex = index - adIndices
                                    .where((adIndex) => adIndex < index)
                                    .length;

                                // Display the news card
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10.0),
                                  child: newsCard(news[newsIndex]),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          } else if (bottomIndex == 3) {
            tabBarViewChildren.add(
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.05),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Courses',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.02),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshData,
                            child: loading2
                                ? Center(
                              child: CircularProgressIndicator(
                                  color: Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface),
                            )
                                : errorMessage != null
                                ? Center(
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Inconsolata',
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshData,
                                    child: Text(
                                      'Retry',
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : ListView.builder(
                              controller: _scrollController,
                              itemCount: courses.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20.0,
                                      right: 20.0,
                                      top: 0.0),
                                  child: courseCard(courses[index]),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    // if (_isRefreshing)
                    //   Container(
                    //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    //     child: const Center(
                    //       child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            );
          } else if (bottomIndex == 4) {
            final isDarkMode = Theme
                .of(context)
                .brightness == Brightness.dark;
            tabBarViewChildren.add(
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshData,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onSurface,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                height:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            Row(
                              children: [
                                Spacer(),
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22.0,
                                    color:
                                    Theme
                                        .of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                            SizedBox(
                                height:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            Center(
                              child: Stack(
                                children: [
                                  if (profileImg == null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(55),
                                      child: Container(
                                        width: (111 /
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .width) *
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .width,
                                        height: (111 /
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .height) *
                                            MediaQuery
                                                .of(context)
                                                .size
                                                .height,
                                        color: Colors.grey,
                                        child: Image.asset(
                                          'images/Pexels Photo by 3Motional Studio.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    if (profileImg != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(55),
                                        child: Container(
                                          width: (111 /
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width) *
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width,
                                          height: (111 /
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .height) *
                                              MediaQuery
                                                  .of(context)
                                                  .size
                                                  .height,
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
                                            builder: (context) =>
                                                EditProfile(
                                                    key: UniqueKey(),
                                                    profileImgUrl: profileImg ??
                                                        "",
                                                    name: userName ?? "",
                                                    onToggleDarkMode:
                                                    widget.onToggleDarkMode,
                                                    isDarkMode: widget
                                                        .isDarkMode),
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
                            SizedBox(
                                height:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            Center(
                              child: userName != null
                                  ? Text(
                                userName!,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              )
                                  : CircularProgressIndicator(
                                  color: Theme
                                      .of(context)
                                      .colorScheme
                                      .onSurface),
                            ),
                            SizedBox(
                                height:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.01),
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
                                    color:
                                    Theme
                                        .of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.1),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AccountSettings(key: UniqueKey(),
                                              onToggleDarkMode: widget
                                                  .onToggleDarkMode,
                                              isDarkMode: widget.isDarkMode),
                                    ),
                                  );
                                },
                                child: Container(
                                  height:
                                  (50 / MediaQuery
                                      .of(context)
                                      .size
                                      .height) *
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[900]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode ? Colors.grey
                                            .withOpacity(0.2) : Colors.grey
                                            .withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Image.asset(
                                        'images/solar_settings-outline-black.png',
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.04),
                                      Text(
                                        'Settings',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme
                                              .of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
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
                                  height:
                                  (50 / MediaQuery
                                      .of(context)
                                      .size
                                      .height) *
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[900]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode ? Colors.grey
                                            .withOpacity(0.2) : Colors.grey
                                            .withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Image.asset(
                                        'images/Packages-dollarsign-black.png',
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.04),
                                      Text(
                                        'Manage Subscription',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme
                                              .of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: Container(
                                height: (50 / MediaQuery
                                    .of(context)
                                    .size
                                    .height) *
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .height,
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[900] : Colors
                                      .white,
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode ? Colors.grey
                                          .withOpacity(0.2) : Colors.grey
                                          .withOpacity(0.5),
                                      spreadRadius: 3,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width *
                                            0.02),
                                    Image.asset(
                                      'images/fluent_person-support-16-regular-black.png',
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    SizedBox(
                                        width: MediaQuery
                                            .of(context)
                                            .size
                                            .width *
                                            0.04),
                                    Text(
                                      'Customer Support',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0),
                              child: InkWell(
                                onTap: () {
                                  _showLogoutConfirmationDialog();
                                },
                                child: Container(
                                  height:
                                  (50 / MediaQuery
                                      .of(context)
                                      .size
                                      .height) *
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[900]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode ? Colors.grey
                                            .withOpacity(0.2) : Colors.grey
                                            .withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.02),
                                      Image.asset(
                                        'images/material-symbols-light_logout-sharp-black.png',
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      SizedBox(
                                          width: MediaQuery
                                              .of(context)
                                              .size
                                              .width *
                                              0.04),
                                      Text(
                                        'Log out',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme
                                              .of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                          ],
                        ),
                      ),
                    ),
                    // if (_isRefreshing)
                    //   Container(
                    //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    //     child: const Center(
                    //       child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: tabBarViewChildren,
            ),
          );
        },
      ),
    );
  }

  Widget buildStatRow(String leftText, String rightText) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Text(
            leftText,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme
                  .of(context)
                  .colorScheme
                  .onSurface,
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 4,
          child: Text(
            rightText,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme
                  .of(context)
                  .colorScheme
                  .onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String name) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(name),
      ),
    );
  }

  Widget _buildTab2(String name) {
    return Tab(
      child: Text(name),
    );
  }

  Widget newsCard(Map<String, dynamic> newsItem) {
    final isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 0.0),
      // Increased bottom padding for more spacing
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NewsDetails(newsId: newsItem['id'], tags: newsItem['tags']),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12), // Smoother corners
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                // Softer shadow for a clean look
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2), // Position shadow for depth
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Align content to start
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    // Slightly rounded image corners
                    child: Container(
                      width: 120, // Fixed width for consistent look
                      height: 100, // Fixed height for aspect ratio
                      color: Colors.grey[300], // Placeholder color
                      child: Image.network(
                        newsItem['images'],
                        fit: BoxFit.cover, // Cover image inside the box
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 60,
                            ), // Error handling for broken images
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Spacing between image and text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Text(
                          newsItem['created_at'],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            // Semi-bold for emphasis
                            fontSize: 12,
                            color: Colors.grey[600], // Lighter color for date
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Title
                        Text(
                          newsItem['title'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tags row
                        _buildTag(newsItem['tags']),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tags) {
    List<String> tagList = tags.split(','); // Assuming tags are comma-separated
    return Wrap(
      spacing: 8.0, // Space between tags
      children: tagList.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          // Padding around the tag
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            // Modern blue color
            borderRadius: BorderRadius.circular(30),
            // More rounded corners for a pill-like shape
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ], // Subtle shadow for depth
          ),
          child: Text(
            tag.trim(), // Display the tag text
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              color: Colors.white,
              // White text on blue background
              fontWeight: FontWeight.w600,
              // Slightly bolder font for emphasis
              letterSpacing:
              0.5, // Slight letter spacing for better readability
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget courseCard(Map<String, dynamic> course) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = constraints.maxWidth;
        bool _shouldPlay = false;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardDetails(course: course['id']),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded edges
            ),
            elevation: 6.0,
            // Slight elevation for a modern look
            shadowColor: Colors.grey.shade300,
            // Softer shadow color
            margin: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              // Rounded edges for media
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media Section (Video or Image)
                  if (course['videos'] == null)
                  // Display the image
                    SizedBox(
                      width: cardWidth,
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.25,
                      child: Image.network(
                        course['images'],
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    if (course['videos'] != null)
                    // Video section with play/pause control based on visibility
                      GestureDetector(
                        onTap: () {},
                        child: VisibilityDetector(
                          key: Key(course['id'].toString()),
                          onVisibilityChanged: (VisibilityInfo info) {
                            setState(() {
                              _shouldPlay = info.visibleFraction > 0.5;
                            });
                          },
                          child: SizedBox(
                            width: cardWidth,
                            height: MediaQuery
                                .of(context)
                                .size
                                .height * 0.25,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRect(
                                child: VideoPlayerWidget(
                                  videoUrl: course['videos'],
                                  shouldPlay: _shouldPlay,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          course['title'],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600, // Semi-bold for title
                            fontSize: 18.0,
                            color: Theme
                                .of(context)
                                .colorScheme
                                .onSurface,
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        // Subtitle or Article
                        Text(
                          course['article'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        // Author Info Row
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(55),
                              child: Container(
                                width:
                                (35 / MediaQuery
                                    .of(context)
                                    .size
                                    .width) *
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .width,
                                height:
                                (35 / MediaQuery
                                    .of(context)
                                    .size
                                    .height) *
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .height,
                                color: Colors.grey,
                                child: Image.network(
                                  course['user_profile_image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                course['username'],
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Date
                            Text(
                              course['created_at'],
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget signals({
    required String img,
    required String name,
    required String entryPrice,
    required String stopLoss,
    required String currentPrice,
    required Map<String, dynamic> targets,
    required String createdAt,
    required String? insight,
    required String? trend,
    required String? pair,
    required ValueNotifier<bool> currentPriceNotifier,
    required ValueNotifier<bool>
    analysisNotifier, // Add a new notifier for analysis dropdown
  }) {
    final isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;
    return ValueListenableBuilder<bool>(
      valueListenable: currentPriceNotifier,
      builder: (context, currentPriceExpanded, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: analysisNotifier,
          builder: (context, analysisExpanded, _) {
            return Padding(
              padding: const EdgeInsets.only(
                  left: 20.0, right: 20.0, top: 5.0, bottom: 5.0),
              child: Container(
                padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors
                          .grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Opened',
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 5,
                            child: Text(
                              createdAt,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Container(
                              width: (50 / MediaQuery
                                  .of(context)
                                  .size
                                  .width) *
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width,
                              height:
                              (50 / MediaQuery
                                  .of(context)
                                  .size
                                  .height) *
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height,
                              color: Colors.grey,
                              child: Image.network(
                                img,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.03),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              (trend ?? 'No Trend'),
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.02),
                          SizedBox(
                            height: 35,
                            child: VerticalDivider(
                              color: isDarkMode ? Colors.white : Colors.black,
                              thickness: 2.0,
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.02),
                          Expanded(
                            flex: 5,
                            child: Text(
                              name + (pair ?? ''),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // const Spacer(),
                          // Expanded(
                          //   flex: 5,
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       color: Theme.of(context).colorScheme.onSurface,
                          //       borderRadius: BorderRadius.circular(10),
                          //     ),
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 12, vertical: 6),
                          //     child: Row(
                          //       children: [
                          //         const Expanded(
                          //           flex: 5,
                          //           child: Text(
                          //             'In progress',
                          //             overflow: TextOverflow.ellipsis,
                          //             style: TextStyle(
                          //               fontSize: 15,
                          //               fontFamily: 'Inconsolata',
                          //               color: Theme.of(context).colorScheme.onSurface,
                          //             ),
                          //           ),
                          //         ),
                          //         Image.asset(
                          //           'images/carbon_in-progress.png',
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Entry price',
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: Text(
                              entryPrice,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.01,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Stop Loss',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: Text(
                              stopLoss,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 10,
                                  child: Text(
                                    'Current Price',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inconsolata',
                                      color: isDarkMode ? Colors.white : Colors
                                          .black,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    currentPrice,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inconsolata',
                                      color: isDarkMode ? Colors.white : Colors
                                          .black,
                                    ),
                                  ),
                                ),
                                // const Spacer(),
                                // const Expanded(
                                //   flex: 4,
                                //   child: Text(
                                //     '-35.5%',
                                //     overflow: TextOverflow.ellipsis,
                                //     style: TextStyle(
                                //       fontSize: 15,
                                //       fontWeight: FontWeight.bold,
                                //       fontFamily: 'Inconsolata',
                                //       color: Color(0xFFFF0000),
                                //     ),
                                //   ),
                                // ),
                                GestureDetector(
                                  onTap: () {
                                    currentPriceNotifier.value =
                                    !currentPriceNotifier.value;
                                  },
                                  child: Image.asset(
                                    currentPriceExpanded
                                        ? 'images/material-symbols_arrow-drop-down-upwards.png'
                                        : 'images/material-symbols_arrow-drop-down.png',
                                  ),
                                ),
                              ],
                            ),
                            if (currentPriceExpanded)
                              ...targets.entries.map(
                                    (entry) =>
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.grey[900]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDarkMode ? Colors.grey
                                                  .withOpacity(0.2) : Colors
                                                  .grey.withOpacity(0.5),
                                              spreadRadius: 3,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 6),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                entry.key,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontSize: 15,
                                                  color: isDarkMode ? Colors
                                                      .white : Colors.black,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                entry.value.toString(),
                                                textAlign: TextAlign.end,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontSize: 15,
                                                  color: isDarkMode ? Colors
                                                      .white : Colors.black,
                                                ),
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
                    SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey[900] : Colors
                                    .white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDarkMode ? Colors.grey.withOpacity(
                                        0.2) : Colors.grey.withOpacity(0.5),
                                    spreadRadius: 3,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 6),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'View Analysis',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inconsolata',
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          analysisNotifier.value =
                                          !analysisNotifier.value;
                                        },
                                        child: Image.asset(
                                          analysisExpanded
                                              ? 'images/material-symbols_arrow-drop-down-upwards.png'
                                              : 'images/material-symbols_arrow-drop-down.png',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (analysisExpanded && insight != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0, vertical: 10.0),
                                      child: Text(
                                        insight,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Inconsolata',
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 10,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TradingViewPage(key: UniqueKey()),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[900] : Colors
                                      .white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode ? Colors.grey
                                          .withOpacity(0.2) : Colors.grey
                                          .withOpacity(0.5),
                                      spreadRadius: 3,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'View Chart',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inconsolata',
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery
                                          .of(context)
                                          .size
                                          .width *
                                          0.02,
                                    ),
                                    Image.asset(
                                      'images/material-symbols_pie-chart.png',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
