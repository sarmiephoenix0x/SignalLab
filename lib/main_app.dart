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
import 'package:signal_app/menu_page.dart';
import 'package:signal_app/news_details.dart';
import 'package:signal_app/notification_page.dart';
import 'package:signal_app/packages_page.dart';
import 'package:signal_app/payment_method.dart';
import 'package:signal_app/sentiment_page.dart';
import 'package:signal_app/settings.dart';
import 'package:signal_app/trading_web_view.dart';
import 'package:signal_app/transaction_history.dart';
import 'package:signal_app/video_player_widget.dart';
import 'package:signal_app/view_analysis.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'edit_profile.dart';
import 'dart:math'; // For Random
import 'package:google_mobile_ads/google_mobile_ads.dart'; // For ads

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MainApp extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;

  const MainApp(
      {super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  // ignore: library_private_types_in_public_api
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp>
    with TickerProviderStateMixin, RouteAware {
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
  int _currentSignalPage = 1;
  bool _isLoadingMoreSignal = false;
  bool _hasMoreSignal = true;
  List<dynamic> _signalsList = [];
  late Future<void> _signalsFuture1;
  late Future<void> _signalsFuture2;
  late Future<void> _signalsFuture3;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool loadingNews = false;
  bool loadingLatestNews = false;
  bool loadingCourse = false;
  bool loading3 = false;
  int _eduIndex = 0;
  String? errorMessage;
  bool removeFakeSplashScreen = false;
  List<int> adIndices = []; // tracks where ads are placed
  final Random random = Random();
  final int minCardsBetweenAds = 3; // Minimum cards before an ad
  final int maxRandomCards = 5; // Maximum random cards before an ad
  BannerAd? _bannerAd; // Store the banner ad
  bool _isAdLoaded = false;
  Map<int, BannerAd> _bannerAds = {};
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  List searchResults = [];
  bool searchLoading = false;
  PageController _pageController = PageController(); // Add a PageController
  int _currentPage = 0; // Track the current page for indicators

  int currentNewsPage = 1; // Current page tracker
  int totalNewsPages = 1; // Total pages available
  bool isFetchingNews = false; // To prevent multiple fetch calls
  ScrollController _newsScrollController = ScrollController();

  int currentCoursePage = 1; // Current page tracker
  int totalCoursePages = 1; // Total pages available
  bool isFetchingCourse = false; // To prevent multiple fetch calls
  ScrollController _courseScrollController = ScrollController();
  ScrollController _signalScrollController = ScrollController();
  bool loadingMoreCourses = false;
  bool loadingMoreNews = false;
  bool _isLoadingMoreCourses = false;
  bool _isLoadingMoreNews = false;
  bool _hasMoreCourses = true;
  bool _hasMoreNews = true;
  bool subscribedForCourse = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    fetchCourses(isRefresh: true);
    fetchNews(isRefresh: true);
    fetchLatestNews();
    homeTab = TabController(length: 2, vsync: this);
    homeTab!.addListener(() {
      setState(() {
        _eduIndex = homeTab!.index;
      });
    });
    signalTab = TabController(length: 3, vsync: this);
    _signalsFuture1 = _fetchInitialSignals('crypto');
    _signalsFuture2 = _fetchInitialSignals('forex');
    _signalsFuture3 = _fetchInitialSignals('stocks');
    _signalScrollController.addListener(_onScroll);
    _newsScrollController.addListener(_onScrollNews);

    _courseScrollController.addListener(_onScrollCourse);
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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final ModalRoute? modalRoute = ModalRoute.of(context);
  //   if (modalRoute is PageRoute) {
  //     if (_currentBottomIndex == 3) {
  //       if (subscribedForCourse == false) {
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           _showFilterOverlay();
  //         });
  //       }
  //     }

  //     routeObserver.subscribe(this, modalRoute);
  //   }
  // }

// Initialize the BannerAd only once
  void _initializeAd(int index) {
    if (_bannerAds[index] != null) return;

    _bannerAds[index] = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/9214589741',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          print('BannerAd loaded.');
          setState(() {
            // Trigger UI update when ad is loaded
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose(); // Dispose the ad on error
          _bannerAds.remove(index); // Remove the failed ad from the map
        },
      ),
    )..load(); // Load the ad
  }

  List<int> getAdIndices(int totalNews, int minCards, int maxRandom) {
    List<int> adIndices = [];
    Random random = Random();

    // Ensure there are enough news items to place ads
    if (totalNews <= minCards) {
      return adIndices; // Return an empty list if there aren't enough news items
    }

    // Start placing ads after a minimum number of news cards
    int nextAdIndex = minCards; // Start after minCards

    while (nextAdIndex < totalNews) {
      adIndices.add(nextAdIndex);
      // Randomize the next position for the ad; it will be after the current ad index
      int additionalCards =
          random.nextInt(maxRandom) + minCards; // Add a random number of cards
      nextAdIndex += additionalCards;
    }

    return adIndices;
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
  List<Map<String, dynamic>> latestNews = [];

  Future<void> fetchCourses({int page = 1, bool isRefresh = false}) async {
    if (subscribedForCourse == true) {
      if (mounted) {
        setState(() {
          if (isRefresh) {
            loadingCourse = true;
          }
          errorMessage = null;
        });
      }

      try {
        final String? accessToken = await storage.read(key: 'accessToken');
        print(accessToken);
        final response = await http.get(
          Uri.parse('https://signal.payguru.com.ng/api/courses?page=$page'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List<Map<String, dynamic>> fetchedCourses =
              List<Map<String, dynamic>>.from(responseData['data']);

          if (mounted) {
            setState(() {
              if (isRefresh) {
                courses.clear();
              }
              courses.addAll(fetchedCourses);
              totalCoursePages = responseData['pagination']['total_pages'];
              currentCoursePage = page;
              _hasMoreCourses =
                  responseData['pagination']['next_page_url'] != null;
              loadingCourse = false;
            });
          }
          print("Courses Loaded");
        } else {
          final message = json.decode(response.body)['message'];
          if (mounted) {
            setState(() {
              loadingCourse = false;
              errorMessage = message;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            loadingCourse = false;
            errorMessage =
                'Failed to load data. Please check your network connection.';
          });
        }
        print('Exception: $e');
      }
    }
  }

  Future<void> _fetchMoreCourses() async {
    if (_isLoadingMoreCourses || !_hasMoreCourses) return;

    setState(() {
      _isLoadingMoreCourses = true;
    });

    try {
      currentCoursePage++;
      await fetchCourses(page: currentCoursePage); // No need to store result
    } catch (e) {
      print('Error fetching more signals: $e');
    } finally {
      setState(() {
        _isLoadingMoreCourses = false;
      });
    }
  }

  Future<void> fetchNews({int page = 1, bool isRefresh = false}) async {
    if (mounted) {
      setState(() {
        if (isRefresh) {
          loadingNews = true;
        }
        errorMessage = null; // Reset error message before fetch
      });
    }

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      // print(accessToken);
      final response = await http.get(
        Uri.parse('https://signal.payguru.com.ng/api/news?page=$page'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<Map<String, dynamic>> fetchedNews =
            List<Map<String, dynamic>>.from(responseData['data']);

        if (mounted) {
          setState(() {
            if (isRefresh) {
              news.clear();
            }
            news.addAll(fetchedNews); // Append new data to the list
            totalNewsPages =
                responseData['pagination']['total_pages']; // Update total pages
            currentNewsPage = page; // Update current page
            _hasMoreNews = responseData['pagination']['next_page_url'] !=
                null; // Check if there's more data
            loadingNews = false;
          });
        }
        print('Total News Length: ${news.length}');
        adIndices = getAdIndices(news.length, minCardsBetweenAds,
            maxRandomCards); // Update ad positions
        print('Generated Ad Indices: $adIndices');
        print("News Loaded");
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        if (mounted) {
          setState(() {
            loadingNews = false;
            errorMessage = json.decode(response.body)['message'];
          });
        }
        print('Error: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loadingNews = false;
          errorMessage =
              'Failed to load data. Please check your network connection.';
        });
      }
      print('Exception: $e');
    }
  }

  Future<void> _fetchMoreNews() async {
    if (_isLoadingMoreNews || !_hasMoreNews)
      return; // Prevent further loading if already loading or no more data

    setState(() {
      _isLoadingMoreNews = true;
    });

    try {
      currentNewsPage++; // Move to the next page
      await fetchNews(page: currentNewsPage); // Fetch the next page of news
    } catch (e) {
      print('Error fetching more news: $e');
    } finally {
      setState(() {
        _isLoadingMoreNews = false; // Stop the loading spinner
      });
    }
  }

  Future<void> fetchLatestNews() async {
    if (mounted) {
      setState(() {
        loadingLatestNews = true;
        errorMessage = null; // Reset error message before fetch
      });
    }

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      final response = await http.get(
        Uri.parse('https://signal.payguru.com.ng/api/latest/news'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          final newsData =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          latestNews = newsData; // Store all news items
          loadingLatestNews = false;
          print("Latest News Loaded");
        }
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        if (mounted) {
          setState(() {
            loadingLatestNews = false;
            errorMessage = json.decode(response.body)['message'];
          });
        }
        print('Error: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loadingLatestNews = false;
          errorMessage =
              'Failed to load data. Please check your network connection.';
        });
      }
      print('Exception: $e');
    }
  }

  Future<Map<String, dynamic>> fetchSignals(String type, {int page = 1}) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse(
          'https://signal.payguru.com.ng/api/signal?type=$type&page=$page'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'signals': responseData['data'],
        'pagination': responseData['pagination'],
      };
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

  Future<void> _fetchInitialSignals(String type) async {
    _currentSignalPage = 1;
    try {
      final result = await fetchSignals(type, page: _currentSignalPage);
      setState(() {
        _signalsList = result['signals'];
        _hasMoreSignal = result['pagination']['next_page_url'] != null;
      });
    } catch (e) {
      print('Error fetching signals: $e');
    }
  }

  Future<void> _fetchMoreSignals(String type) async {
    if (_isLoadingMoreSignal || !_hasMoreSignal) return;

    setState(() {
      _isLoadingMoreSignal = true;
    });

    try {
      _currentSignalPage++;
      final result = await fetchSignals(type, page: _currentSignalPage);
      setState(() {
        _signalsList.addAll(result['signals']);
        _hasMoreSignal = result['pagination']['next_page_url'] != null;
      });
    } catch (e) {
      print('Error fetching more signals: $e');
    } finally {
      setState(() {
        _isLoadingMoreSignal = false;
      });
    }
  }

  void _onScroll() {
    if (_signalScrollController.position.pixels >=
            _signalScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreSignal) {
      // Load more signals dynamically based on the active tab
      if (signalTab!.index == 0) {
        _fetchMoreSignals('crypto');
      } else if (signalTab!.index == 1) {
        _fetchMoreSignals('forex');
      } else if (signalTab!.index == 2) {
        _fetchMoreSignals('stocks');
      }
    }
  }

  void _onScrollCourse() {
    if (_courseScrollController.position.pixels >=
            _courseScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreCourses) {
      _fetchMoreCourses();
    }
  }

  void _onScrollNews() {
    if (_newsScrollController.position.pixels >=
            _newsScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreNews) {
      fetchLatestNews();
      _fetchMoreNews();
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
                width: MediaQuery.of(context).size.width * 0.05,
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
                width: MediaQuery.of(context).size.width * 0.05,
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
                width: MediaQuery.of(context).size.width * 0.05,
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
                width: MediaQuery.of(context).size.width * 0.05,
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
      await fetchCourses(isRefresh: true);
      await fetchNews(isRefresh: true);
    } else if (_currentBottomIndex == 1) {
      if (signalTab!.index == 0) {
        _fetchMoreSignals('crypto');
      } else if (signalTab!.index == 1) {
        _fetchMoreSignals('forex');
      } else if (signalTab!.index == 2) {
        _fetchMoreSignals('stocks');
      }
      // await Future.wait([_signalsFuture1, _signalsFuture2, _signalsFuture3]);
    } else if (_currentBottomIndex == 2) {
      await fetchNews(isRefresh: true);
    } else if (_currentBottomIndex == 3) {
      await fetchCourses(isRefresh: true);
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
        loading3 = true;
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

  Future<void> _performSearch(String query) async {
    setState(() {
      searchLoading = true;
    });
    final String? accessToken = await storage.read(key: 'accessToken');
    final url = 'https://signal.payguru.com.ng/api/search?query=$query';
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    // Perform GET request
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      setState(() {
        searchResults = jsonDecode(response.body);
        searchLoading = false;
      });
    } else if (response.statusCode == 404) {
      setState(() {
        searchResults = [];
        searchLoading = false;
      });
      _showCustomSnackBar(
        context,
        'No results found for the query.',
        isError: true,
      );
    } else if (response.statusCode == 422 || response.statusCode == 401) {
      setState(() {
        searchResults = [];
        searchLoading = false;
      });
      final errorMessage = jsonDecode(response.body)['message'];
      _showCustomSnackBar(
        context,
        errorMessage,
        isError: true,
      );
    }
  }

  void _showFilterOverlay() {
    final overlay = Overlay.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: GestureDetector(
          onTap: () {
            if (mounted) {
              setState(() {
                _currentBottomIndex = 0;
              });
            }
            _removeOverlay();
          }, // Close the overlay on tap outside
          child: Material(
            color: Colors.black.withOpacity(0.5),
            // Semi-transparent background
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Do nothing on tap inside this widget
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 30), // Margin to limit width
                  padding: const EdgeInsets.only(
                      left: 12.0, right: 12.0, top: 20.0, bottom: 20.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(15),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // Makes container adjust height based on content
                    children: [
                      Text(
                        'FOR SUSCRIBERS ONLY',
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontFamily: 'Inconsolata',
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Text(
                        'To access this feature, you need to subscribe to one of our plans',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontFamily: 'Inconsolata',
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Image.asset(
                        'images/LockedImg.png',
                        height: 120,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Container(
                        width: double.infinity,
                        height: (60 / MediaQuery.of(context).size.height) *
                            MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _removeOverlay(loadPackage: true);
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
                          child: const Text(
                            'SUBSCRIBE',
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Inconsolata',
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
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay({bool loadPackage = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (loadPackage == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PackagesPage(key: UniqueKey()),
        ),
      );
      setState(() {
        _currentBottomIndex = 0;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _signalScrollController.removeListener(_onScroll);
    _newsScrollController.dispose();
    _courseScrollController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
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
          if (_overlayEntry != null) {
            setState(() {
              _currentBottomIndex = 0;
            });
            _removeOverlay();
          } else {
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
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _isSearching
            ? AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.black, // Background to match your theme
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white, // White text for search input
                          fontSize: 18, // Adjust size for better visibility
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(
                            color: Colors.white54, // Light gray hint text
                            fontSize:
                                16, // Slightly smaller hint size for contrast
                          ),
                          filled: true,
                          fillColor: Colors
                              .white10, // Slight translucent effect for input background
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide:
                                BorderSide.none, // No border for a clean look
                          ),
                          // Add a search icon with onPressed event
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              // Trigger search only when the search icon is tapped
                              _performSearch(_searchController.text);
                            },
                          ),
                        ),
                      )
                    : Container(), // Empty container if not searching
                actions: _isSearching
                    ? [
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white), // White close icon
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchController.clear();
                            });
                          },
                        ),
                      ]
                    : [], // Return an empty list when not searching
              )
            : null,
        // drawer: ClipRRect(
        //   borderRadius: const BorderRadius.only(
        //     topRight: Radius.circular(30.0),
        //     bottomRight: Radius.circular(30.0),
        //   ),
        //   child: SafeArea(
        //     child: Padding(
        //       padding: const EdgeInsets.only(bottom: 60.0),
        //       child: Drawer(
        //         child: Container(
        //           color: Colors.black, // Set your desired background color here
        //           child: ListView(
        //             padding: EdgeInsets.zero,
        //             children: <Widget>[
        //               DrawerHeader(
        //                 decoration: const BoxDecoration(
        //                   color: Colors
        //                       .black, // Set your desired header color here
        //                 ),
        //                 padding:
        //                     const EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 8.0),
        //                 child: Row(children: [
        //                   if (profileImg == null)
        //                     ClipRRect(
        //                       borderRadius: BorderRadius.circular(55),
        //                       child: Container(
        //                         width:
        //                             (35 / MediaQuery.of(context).size.width) *
        //                                 MediaQuery.of(context).size.width,
        //                         height:
        //                             (35 / MediaQuery.of(context).size.height) *
        //                                 MediaQuery.of(context).size.height,
        //                         color: Colors.grey,
        //                         child: Image.asset(
        //                           'images/Pexels Photo by 3Motional Studio.png',
        //                           fit: BoxFit.cover,
        //                         ),
        //                       ),
        //                     )
        //                   else if (profileImg != null)
        //                     ClipRRect(
        //                       borderRadius: BorderRadius.circular(55),
        //                       child: Container(
        //                         width:
        //                             (35 / MediaQuery.of(context).size.width) *
        //                                 MediaQuery.of(context).size.width,
        //                         height:
        //                             (35 / MediaQuery.of(context).size.height) *
        //                                 MediaQuery.of(context).size.height,
        //                         color: Colors.grey,
        //                         child: Image.network(
        //                           profileImg!,
        //                           fit: BoxFit.cover,
        //                         ),
        //                       ),
        //                     ),
        //                   SizedBox(
        //                       width: MediaQuery.of(context).size.width * 0.03),
        //                   if (userName != null)
        //                     Text(
        //                       userName!,
        //                       style: const TextStyle(
        //                         fontFamily: 'GolosText',
        //                         fontSize: 16.0,
        //                         fontWeight: FontWeight.bold,
        //                         color: Colors.white,
        //                       ),
        //                     )
        //                   else
        //                     const CircularProgressIndicator(
        //                         color: Colors.black),
        //                 ]),
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/ic_round-add-card.png',
        //                 ),
        //                 title: const Text(
        //                   'Payment Method',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (context) => PaymentMethod(
        //                           key: UniqueKey(),
        //                           onToggleDarkMode: widget.onToggleDarkMode,
        //                           isDarkMode: widget.isDarkMode),
        //                     ),
        //                   );
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/carbon_event.png',
        //                 ),
        //                 title: const Text(
        //                   'Events',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (context) =>
        //                           EventsPage(key: UniqueKey()),
        //                     ),
        //                   );
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/fluent-mdl2_sentiment-analysis.png',
        //                 ),
        //                 title: const Text(
        //                   'Sentiment',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (context) =>
        //                           SentimentPage(key: UniqueKey()),
        //                     ),
        //                   );
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/Packages-dollarsign.png',
        //                 ),
        //                 title: const Text(
        //                   'Packages',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (context) =>
        //                           PackagesPage(key: UniqueKey()),
        //                     ),
        //                   );
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/Referrals.png',
        //                 ),
        //                 title: const Text(
        //                   'Referrals',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   // Navigate to home or any action you want
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/solar_settings-outline.png',
        //                   height: 25,
        //                 ),
        //                 title: const Text(
        //                   'Settings',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (context) => AccountSettings(
        //                           key: UniqueKey(),
        //                           onToggleDarkMode: widget.onToggleDarkMode,
        //                           isDarkMode: widget.isDarkMode),
        //                     ),
        //                   );
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/grommet-icons_transaction.png',
        //                 ),
        //                 title: const Text(
        //                   'Transaction History',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (context) =>
        //                           TransactionHistory(key: UniqueKey()),
        //                     ),
        //                   );
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/fluent_person-support-16-regular.png',
        //                   height: 25,
        //                 ),
        //                 title: const Text(
        //                   'Customer Support',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                 },
        //               ),
        //               ListTile(
        //                 leading: Image.asset(
        //                   'images/bookmark.png',
        //                   height: 25,
        //                 ),
        //                 title: const Text(
        //                   'Bookmarks',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context); // Close the drawer
        //                   Navigator.push(
        //                     context,
        //                     MaterialPageRoute(
        //                       builder: (context) =>
        //                           BookmarkPage(key: UniqueKey()),
        //                     ),
        //                   );
        //                 },
        //               ),
        //               ListTile(
        //                 contentPadding:
        //                     const EdgeInsets.only(top: 16, left: 16),
        //                 leading: Image.asset(
        //                   'images/material-symbols-light_logout-sharp.png',
        //                   height: 25,
        //                 ),
        //                 title: const Text(
        //                   'Log out',
        //                   style: TextStyle(
        //                     fontFamily: 'GolosText',
        //                     fontSize: 16.0,
        //                     fontWeight: FontWeight.bold,
        //                     color: Colors.white,
        //                   ),
        //                 ),
        //                 onTap: () {
        //                   Navigator.pop(context);
        //                   _showLogoutConfirmationDialog();
        //                 },
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
        body: _isSearching
            ? (searchLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context)
                              .colorScheme
                              .onSurface), // Use primary color
                      strokeWidth: 4.0,
                    ),
                  )
                : (searchResults.isNotEmpty
                    ? ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              searchResults[index]['title'] ?? 'No Title',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              searchResults[index]['description'] ??
                                  'No Description',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          'No results to display',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      )))
            : removeFakeSplashScreen == false
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
                          // Custom circular loader
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Black & White Gradient CircularProgressIndicator
                                ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        Colors.black,
                                        Colors.white,
                                      ], // Black and white gradient
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds);
                                  },
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 4.0, // Sleeker look
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                // Center Icon
                                const Icon(
                                  Icons.circle, // More neutral, minimalist icon
                                  size: 24.0,
                                  color: Colors
                                      .black, // Matching black and white theme
                                ),
                              ],
                            ),
                          ),
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
              selectedItemColor: Theme.of(context).colorScheme.onSurface,
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
                  icon: const ImageIcon(
                    AssetImage('images/ion_home.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    const AssetImage('images/ion_home_active.png'),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: const ImageIcon(
                    AssetImage('images/mingcute_signal-fill.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    const AssetImage('images/mingcute_signal-fill_active.png'),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  label: 'Signal',
                ),
                BottomNavigationBarItem(
                  icon: const ImageIcon(
                    AssetImage('images/iconamoon_news-thin.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    const AssetImage('images/iconamoon_news-thin_active.png'),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  label: 'News',
                ),
                BottomNavigationBarItem(
                  icon: const ImageIcon(
                    AssetImage('images/fluent-mdl2_publish-course.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    const AssetImage(
                        'images/fluent-mdl2_publish-course_active.png'),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  label: 'Course',
                ),
                BottomNavigationBarItem(
                  icon: const ImageIcon(
                    AssetImage('images/majesticons_user-line.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    const AssetImage('images/majesticons_user-line_active.png'),
                    color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.onSurface,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        // _scaffoldKey.currentState?.openDrawer();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MenuPage(
                                                key: UniqueKey(),
                                                onToggleDarkMode:
                                                    widget.onToggleDarkMode,
                                                isDarkMode: widget.isDarkMode,
                                                userName: userName,
                                                profileImg: profileImg),
                                          ),
                                        );
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
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isSearching = true;
                                        });
                                      },
                                      child: Image.asset(
                                        'images/tabler_search.png',
                                        height: 50,
                                      ),
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
                                  height: MediaQuery.of(context).size.height *
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
                                                MediaQuery.of(context)
                                                    .size
                                                    .width) *
                                            MediaQuery.of(context).size.width,
                                        height: (35 /
                                                MediaQuery.of(context)
                                                    .size
                                                    .height) *
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
                                        width: (35 /
                                                MediaQuery.of(context)
                                                    .size
                                                    .width) *
                                            MediaQuery.of(context).size.width,
                                        height: (35 /
                                                MediaQuery.of(context)
                                                    .size
                                                    .height) *
                                            MediaQuery.of(context).size.height,
                                        color: Colors.grey,
                                        child: Image.network(
                                          profileImg!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface),
                                ]),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Container(
                                  height: (130 /
                                          MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                        width: 0, color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      Image.asset(
                                        'images/Balance.png',
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      const VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 1.0,
                                        width: 20.0,
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
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
                                                height: MediaQuery.of(context)
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
                                  height: MediaQuery.of(context).size.height *
                                      0.02),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Container(
                                  height: (130 /
                                          MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                        width: 0, color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      Image.asset(
                                        'images/Package.png',
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      const VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 1.0,
                                        width: 20.0,
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
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
                                                height: MediaQuery.of(context)
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
                                  height: MediaQuery.of(context).size.height *
                                      0.02),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Container(
                                  height: (130 /
                                          MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                        width: 0, color: Colors.grey),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      Image.asset(
                                        'images/Signals.png',
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      const VerticalDivider(
                                        color: Colors.grey,
                                        thickness: 1.0,
                                        width: 20.0,
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
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
                                                height: MediaQuery.of(context)
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
                                  height: MediaQuery.of(context).size.height *
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
                                        color: Theme.of(context)
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
                                  height: MediaQuery.of(context).size.height *
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
                                      Theme.of(context).colorScheme.onSurface,
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
                                  height: MediaQuery.of(context).size.height *
                                      0.03),
                              SizedBox(
                                height:
                                    (400 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                child: TabBarView(
                                  controller: homeTab,
                                  children: [
                                    if (loadingNews)
                                      Center(
                                        child: CircularProgressIndicator(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                      )
                                    else if (errorMessage != null)
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
                                              onPressed: () async {
                                                await fetchNews(
                                                    isRefresh: true);
                                              },
                                              child: Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Theme.of(context)
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
                                        controller: _newsScrollController,
                                        itemCount:
                                            news.length + adIndices.length,
                                        itemBuilder: (context, index) {
                                          int actualIndex = index;
                                          int adCount = adIndices
                                              .where((adIndex) =>
                                                  adIndex < actualIndex)
                                              .length;
                                          final newsIndex =
                                              actualIndex - adCount;

                                          // Display loader as the last item if loading is true
                                          if (_isLoadingMoreNews &&
                                              index ==
                                                  news.length +
                                                      adIndices.length) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          // Check if the current index should display an ad
                                          if (adIndices.contains(actualIndex)) {
                                            _initializeAd(actualIndex);
                                            BannerAd? bannerAd =
                                                _bannerAds[actualIndex];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20.0,
                                                      vertical: 10.0),
                                              child: SizedBox(
                                                height: 100,
                                                child: bannerAd != null
                                                    ? AdWidget(ad: bannerAd)
                                                    : const SizedBox.shrink(),
                                              ),
                                            );
                                          }

                                          // Ensure that we do not access out of bounds for news items
                                          if (newsIndex >= news.length) {
                                            return const SizedBox
                                                .shrink(); // Handle out of bounds differently if needed
                                          }

                                          // Display the news card
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            child: newsCard(news[newsIndex]),
                                          );
                                        },
                                      ),
                                    if (loadingCourse)
                                      Center(
                                        child: CircularProgressIndicator(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                      )
                                    else if (errorMessage != null)
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
                                              onPressed: () async {
                                                await fetchCourses(
                                                    isRefresh: true);
                                              },
                                              child: Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (subscribedForCourse == false)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20.0, right: 20.0, top: 0.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          // Makes container adjust height based on content
                                          children: [
                                            Text(
                                              'FOR SUSCRIBERS ONLY',
                                              style: TextStyle(
                                                decoration: TextDecoration.none,
                                                fontFamily: 'Inconsolata',
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.02),
                                            Text(
                                              'To access this feature, you need to subscribe to one of our plans',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                decoration: TextDecoration.none,
                                                fontFamily: 'Inconsolata',
                                                fontSize: 20,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.02),
                                            Image.asset(
                                              'images/LockedImg.png',
                                              height: 120,
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05),
                                            Container(
                                              width: double.infinity,
                                              height: (60 /
                                                      MediaQuery.of(context)
                                                          .size
                                                          .height) *
                                                  MediaQuery.of(context)
                                                      .size
                                                      .height,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 30.0),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  _removeOverlay(
                                                      loadPackage: true);
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty
                                                          .resolveWith<Color>(
                                                    (Set<WidgetState> states) {
                                                      if (states.contains(
                                                          WidgetState
                                                              .pressed)) {
                                                        return Colors.white;
                                                      }
                                                      return Colors.black;
                                                    },
                                                  ),
                                                  foregroundColor:
                                                      WidgetStateProperty
                                                          .resolveWith<Color>(
                                                    (Set<WidgetState> states) {
                                                      if (states.contains(
                                                          WidgetState
                                                              .pressed)) {
                                                        return Colors.black;
                                                      }
                                                      return Colors.white;
                                                    },
                                                  ),
                                                  elevation: WidgetStateProperty
                                                      .all<double>(4.0),
                                                  shape: WidgetStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  15)),
                                                    ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'SUBSCRIBE',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        controller: _courseScrollController,
                                        itemCount: courses.length,
                                        itemBuilder: (context, index) {
                                          if (_isLoadingMoreCourses &&
                                              index == courses.length) {
                                            // Show loading indicator at the bottom
                                            return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface));
                                          }
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
                            height: MediaQuery.of(context).size.height * 0.05),
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
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
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
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03),
                        TabBar(
                          controller: signalTab,
                          tabs: [
                            _buildTab2('Crypto'),
                            _buildTab2('Forex'),
                            _buildTab2('Stocks'),
                          ],
                          labelColor: Theme.of(context).colorScheme.onSurface,
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
                              Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03),
                        Expanded(
                          child: TabBarView(
                            controller: signalTab,
                            children: [
                              FutureBuilder<void>(
                                future: _signalsFuture1,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator(
                                            color: Theme.of(context)
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
                                            onPressed: () {
                                              setState(() {
                                                _signalsFuture1 =
                                                    _fetchInitialSignals(
                                                        'crypto');
                                              });
                                            },
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final isDarkMode =
                                      Theme.of(context).brightness ==
                                          Brightness.dark;
                                  return RefreshIndicator(
                                    onRefresh: () =>
                                        _fetchInitialSignals('crypto'),
                                    child: ListView.builder(
                                      controller: _signalScrollController,
                                      itemCount: _signalsList.length + 1,
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
                                                color: isDarkMode
                                                    ? Colors.grey[900]
                                                    : Colors.white,
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
                                        } else if (index ==
                                            _signalsList.length) {
                                          // Show loading indicator at the bottom
                                          return _isLoadingMoreSignal
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface),
                                                  ),
                                                )
                                              : SizedBox
                                                  .shrink(); // No more signals to load
                                        }

                                        final signal = _signalsList[index - 1];

                                        Map<String, dynamic> targetsMap =
                                            jsonDecode(signal['targets']);

                                        return signals(
                                          id: signal['id'],
                                          type: signal['type'],
                                          authorId: signal['author_id'],
                                          authorName: signal['author_name'],
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
                              FutureBuilder<void>(
                                future: _signalsFuture2,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator(
                                            color: Theme.of(context)
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
                                            onPressed: () {
                                              setState(() {
                                                // Trigger the future again by refreshing the state
                                                _signalsFuture2 =
                                                    _fetchInitialSignals(
                                                        'forex');
                                              });
                                            },
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final isDarkMode =
                                      Theme.of(context).brightness ==
                                          Brightness.dark;
                                  return RefreshIndicator(
                                    onRefresh: () =>
                                        _fetchInitialSignals('forex'),
                                    child: ListView.builder(
                                      controller: _signalScrollController,
                                      itemCount: _signalsList.length + 1,
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
                                                color: isDarkMode
                                                    ? Colors.grey[900]
                                                    : Colors.white,
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

                                        final signal = _signalsList[index - 1];

                                        Map<String, dynamic> targetsMap =
                                            jsonDecode(signal['targets']);

                                        return signals(
                                          id: signal['id'],
                                          type: signal['type'],
                                          authorId: signal['author_id'],
                                          authorName: signal['author_name'],
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
                              FutureBuilder<void>(
                                future: _signalsFuture3,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator(
                                            color: Theme.of(context)
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
                                            onPressed: () {
                                              setState(() {
                                                // Trigger the future again by refreshing the state
                                                _signalsFuture3 =
                                                    _fetchInitialSignals(
                                                        'stocks');
                                              });
                                            },
                                            child: Text(
                                              'Retry',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  final isDarkMode =
                                      Theme.of(context).brightness ==
                                          Brightness.dark;
                                  return RefreshIndicator(
                                    onRefresh: () =>
                                        _fetchInitialSignals('stocks'),
                                    child: ListView.builder(
                                      controller: _signalScrollController,
                                      itemCount: _signalsList.length + 1,
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
                                                color: isDarkMode
                                                    ? Colors.grey[900]
                                                    : Colors.white,
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

                                        final signal = _signalsList[index - 1];

                                        Map<String, dynamic> targetsMap =
                                            jsonDecode(signal['targets']);

                                        return signals(
                                          id: signal['id'],
                                          type: signal['type'],
                                          authorId: signal['author_id'],
                                          authorName: signal['author_name'],
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
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            tabBarViewChildren.add(
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'News',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await fetchLatestNews();
                              await fetchNews(isRefresh: true);
                            },
                            child: loadingNews
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: Theme.of(context)
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
                                              onPressed: () async {
                                                await fetchLatestNews();
                                                await fetchNews();
                                              },
                                              child: Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          // Carousel for the latest news
                                          Stack(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.grey[900]
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12), // Smoother corners
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey
                                                          .withOpacity(0.2),
                                                      // Softer shadow for a clean look
                                                      spreadRadius: 2,
                                                      blurRadius: 8,
                                                      offset: const Offset(0,
                                                          2), // Position shadow for depth
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20.0,
                                                      vertical: 10.0),
                                                  child: SizedBox(
                                                    height: (160.0 /
                                                            MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height) *
                                                        MediaQuery.of(context)
                                                            .size
                                                            .height,
                                                    child: PageView.builder(
                                                      itemCount: latestNews
                                                          .length, // Number of latest news items
                                                      itemBuilder:
                                                          (context, index) {
                                                        return latestNewsCard(
                                                          latestNews[
                                                              index], // Display each news card
                                                        );
                                                      },
                                                      onPageChanged: (index) {
                                                        setState(() {
                                                          _currentPage =
                                                              index; // Update the current page index
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 20,
                                                child: buildIndicators(),
                                              ),
                                            ],
                                          ),

                                          // ListView for other news cards and ads
                                          Expanded(
                                            child: ListView.builder(
                                              controller: _newsScrollController,
                                              itemCount: news.length +
                                                  adIndices
                                                      .length, // The extra loader item when loading is true
                                              itemBuilder: (context, index) {
                                                int actualIndex = index;
                                                int adCount = adIndices
                                                    .where((adIndex) =>
                                                        adIndex < actualIndex)
                                                    .length;
                                                final newsIndex =
                                                    actualIndex - adCount;

                                                // Display loader as the last item if loading is true
                                                if (_isLoadingMoreNews &&
                                                    index ==
                                                        news.length +
                                                            adIndices.length) {
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }

                                                // Check if the current index should display an ad
                                                if (adIndices
                                                    .contains(actualIndex)) {
                                                  _initializeAd(actualIndex);
                                                  BannerAd? bannerAd =
                                                      _bannerAds[actualIndex];
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 10.0),
                                                    child: SizedBox(
                                                      height: 100,
                                                      child: bannerAd != null
                                                          ? AdWidget(
                                                              ad: bannerAd)
                                                          : const SizedBox
                                                              .shrink(),
                                                    ),
                                                  );
                                                }

                                                // Ensure that we do not access out of bounds for news items
                                                if (newsIndex >= news.length) {
                                                  return const SizedBox
                                                      .shrink(); // Handle out of bounds differently if needed
                                                }

                                                // Display the news card
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20.0,
                                                      vertical: 10.0),
                                                  child:
                                                      newsCard(news[newsIndex]),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
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
            if (subscribedForCourse == false) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showFilterOverlay();
              });
            }
            tabBarViewChildren.add(
              Expanded(
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Courses',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              // await fetchCourses();
                            },
                            child: loadingCourse
                                ? Center(
                                    child: CircularProgressIndicator(
                                        color: Theme.of(context)
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
                                              onPressed: () async {
                                                await fetchCourses(
                                                    isRefresh: true);
                                              },
                                              child: Text(
                                                'Retry',
                                                style: TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: _courseScrollController,
                                        itemCount: courses.length,
                                        itemBuilder: (context, index) {
                                          if (_isLoadingMoreCourses &&
                                              index == courses.length) {
                                            // Show loading indicator at the bottom
                                            return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface));
                                          }
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
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            tabBarViewChildren.add(
              Expanded(
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
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05),
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
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Spacer(),
                              ],
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05),
                            Center(
                              child: Stack(
                                children: [
                                  if (profileImg == null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(55),
                                      child: Container(
                                        width: (111 /
                                                MediaQuery.of(context)
                                                    .size
                                                    .width) *
                                            MediaQuery.of(context).size.width,
                                        height: (111 /
                                                MediaQuery.of(context)
                                                    .size
                                                    .height) *
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
                                        width: (111 /
                                                MediaQuery.of(context)
                                                    .size
                                                    .width) *
                                            MediaQuery.of(context).size.width,
                                        height: (111 /
                                                MediaQuery.of(context)
                                                    .size
                                                    .height) *
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
                                                onToggleDarkMode:
                                                    widget.onToggleDarkMode,
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
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05),
                            Center(
                              child: userName != null
                                  ? Text(
                                      userName!,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    )
                                  : CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.01),
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
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.1),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AccountSettings(
                                          key: UniqueKey(),
                                          onToggleDarkMode:
                                              widget.onToggleDarkMode,
                                          isDarkMode: widget.isDarkMode),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: (50 /
                                          MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[900]
                                        : Colors.white,
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
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      Image.asset(
                                        'images/solar_settings-outline-black.png',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04),
                                      Text(
                                        'Settings',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
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
                                    MediaQuery.of(context).size.height * 0.05),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
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
                                  height: (50 /
                                          MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[900]
                                        : Colors.white,
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
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      Image.asset(
                                        'images/Packages-dollarsign-black.png',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04),
                                      Text(
                                        'Manage Subscription',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
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
                                    MediaQuery.of(context).size.height * 0.05),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Container(
                                height:
                                    (50 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
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
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Image.asset(
                                      'images/fluent_person-support-16-regular-black.png',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.04),
                                    Text(
                                      'Customer Support',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: InkWell(
                                onTap: () {
                                  _showLogoutConfirmationDialog();
                                },
                                child: Container(
                                  height: (50 /
                                          MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.grey[900]
                                        : Colors.white,
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
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.02),
                                      Image.asset(
                                        'images/material-symbols-light_logout-sharp-black.png',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.04),
                                      Text(
                                        'Log out',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
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
                                    MediaQuery.of(context).size.height * 0.05),
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
              color: Theme.of(context).colorScheme.onSurface,
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
              color: Theme.of(context).colorScheme.onSurface,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                        errorBuilder: (context, error, stackTrace) => Icon(
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

  Widget latestNewsCard(Map<String, dynamic> newsItem) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Align content to start
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(55),
                  child: Container(
                    width: (40 / MediaQuery.of(context).size.width) *
                        MediaQuery.of(context).size.width,
                    height: (40 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    color: Colors.grey,
                    child: Image.network(
                      newsItem['user_profile_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons
                            .error); // Show an error icon if image fails to load
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.02,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        newsItem['user'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
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
          ],
        ),
      ),
    );
  }

  Widget buildIndicators() {
    if (latestNews.isEmpty) {
      return const SizedBox
          .shrink(); // Return an empty widget if there are no news items
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(latestNews.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage
                ? Theme.of(context).colorScheme.onSurface // Active color
                : Colors.grey, // Inactive color
          ),
        );
      }),
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
            style: const TextStyle(
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
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: Image.network(
                        course['images'],
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (course['videos'] != null)
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
                          height: MediaQuery.of(context).size.height * 0.25,
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
                            color: Theme.of(context).colorScheme.onSurface,
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
                                    (35 / MediaQuery.of(context).size.width) *
                                        MediaQuery.of(context).size.width,
                                height:
                                    (35 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
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
    required int id,
    required String type,
    required String authorId,
    required String authorName,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                      color: isDarkMode
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.5),
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
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Container(
                              width: (50 / MediaQuery.of(context).size.width) *
                                  MediaQuery.of(context).size.width,
                              height:
                                  (50 / MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                              color: Colors.grey,
                              child: Image.network(
                                img,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),
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
                              width: MediaQuery.of(context).size.width * 0.02),
                          SizedBox(
                            height: 35,
                            child: VerticalDivider(
                              color: isDarkMode ? Colors.white : Colors.black,
                              thickness: 2.0,
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02),
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
                      height: MediaQuery.of(context).size.height * 0.02,
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
                      height: MediaQuery.of(context).size.height * 0.01,
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
                      height: MediaQuery.of(context).size.height * 0.02,
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
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
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
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
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
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.white,
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
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
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
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 10,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewAnalysis(
                                      key: UniqueKey(),
                                      signalId: id,
                                      authorId: authorId,
                                      authorName: authorName,
                                      coinName: name,
                                      coinImg: img,
                                      pair: pair,
                                      trend: trend,
                                      type: type,
                                      currentPrice: currentPrice,
                                      insight: insight,
                                      createdAt: createdAt,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
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
                                    horizontal: 0, vertical: 6),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        // GestureDetector(
                                        //   onTap: () {
                                        //     analysisNotifier.value =
                                        //         !analysisNotifier.value;
                                        //   },
                                        //   child: Image.asset(
                                        //     analysisExpanded
                                        //         ? 'images/material-symbols_arrow-drop-down-upwards.png'
                                        //         : 'images/material-symbols_arrow-drop-down.png',
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    // if (analysisExpanded && insight != null)
                                    //   Padding(
                                    //     padding: const EdgeInsets.symmetric(
                                    //         horizontal: 20.0, vertical: 10.0),
                                    //     child: Text(
                                    //       insight,
                                    //       style: TextStyle(
                                    //         fontSize: 15,
                                    //         fontFamily: 'Inconsolata',
                                    //         color: isDarkMode
                                    //             ? Colors.white
                                    //             : Colors.black,
                                    //       ),
                                    //     ),
                                    //   ),
                                  ],
                                ),
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
                                  color: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
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
                                      width: MediaQuery.of(context).size.width *
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
