import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signal_app/course_page.dart';
import 'package:signal_app/menu_page.dart';
import 'package:signal_app/news_page.dart';
import 'package:signal_app/notification_page.dart';
import 'package:signal_app/news_details.dart';
import 'package:signal_app/card_details.dart';
import 'package:signal_app/packages_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:signal_app/video_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomePage extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;
  final Function onLoaded;
  const HomePage(
      {super.key,
      required this.onToggleDarkMode,
      required this.isDarkMode,
      required this.onLoaded});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late SharedPreferences prefs;
  final ScrollController _scrollController = ScrollController();
  ScrollController _newsScrollController = ScrollController();
  ScrollController _courseScrollController = ScrollController();
  late TabController homeTab;

  String? userName;
  String? userBalance;
  String? profileImg;
  int? totalSignal;
  bool loadingNews = false;
  bool loadingLatestNews = false;
  bool loadingCourse = false;
  bool loading3 = false;
  int currentNewsPage = 1; // Current page tracker
  int totalNewsPages = 1; // Total pages available
  bool isFetchingNews = false; // To prevent multiple fetch calls
  int currentCoursePage = 1; // Current page tracker
  int totalCoursePages = 1; // Total pages available
  bool isFetchingCourse = false; // To prevent multiple fetch calls
  bool loadingMoreCourses = false;
  bool loadingMoreNews = false;
  bool _isLoadingMoreCourses = false;
  bool _isLoadingMoreNews = false;
  bool _hasMoreCourses = true;
  bool _hasMoreNews = true;
  bool subscribedForCourse = true;
  OverlayEntry? _overlayEntry;
  String? errorMessage;
  int _eduIndex = 0;
  bool removeFakeSplashScreen = false;
  bool _isRefreshing = false; // Added to track refreshing state

  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> news = [];

  List<int> adIndices = []; // tracks where ads are placed
  final Random random = Random();
  final int minCardsBetweenAds = 3; // Minimum cards before an ad
  final int maxRandomCards = 5;
  BannerAd? _bannerAd; // Store the banner ad
  bool _isAdLoaded = false;
  Map<int, BannerAd> _bannerAds = {};

  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  List searchResults = [];
  bool searchLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNews(isRefresh: true);
    fetchCourses(isRefresh: true);
    homeTab = TabController(length: 2, vsync: this);
    homeTab.addListener(() {
      setState(() {
        _eduIndex = homeTab.index;
      });
    });
    _newsScrollController.addListener(_onScrollNews);
    _courseScrollController.addListener(_onScrollCourse);
    _initializePrefs();
  }

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
        widget.onLoaded();
      });
    }
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
      return userMap['profile_photo'];
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

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        _showNoInternetDialog(context);
        setState(() {
          _isRefreshing = false;
        });
        return;
      }

      await Future.any([
        Future.delayed(const Duration(seconds: 15), () {
          throw TimeoutException('The operation took too long.');
        }),
        fetchNews(isRefresh: true),
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

  void _showFilterOverlay() {
    final overlay = Overlay.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: GestureDetector(
          onTap: () {
            if (mounted) {
              // setState(() {
              //   _currentBottomIndex = 0;
              // });
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
      // setState(() {
      //   _currentBottomIndex = 0;
      // });
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
      _fetchMoreNews();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    homeTab.dispose();
    _newsScrollController.dispose();
    _courseScrollController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
                              if (_searchController.text.isNotEmpty) {
                                _performSearch(_searchController.text.trim());
                              }
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
        body: Stack(
          children: [
            _isSearching
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                                subtitle: Text(
                                  searchResults[index]['description'] ??
                                      'No Description',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
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
                    ? _buildSplashScreen()
                    : OrientationBuilder(
                        builder: (context, orientation) {
                          return Stack(
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
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.05),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          MenuPage(
                                                        key: UniqueKey(),
                                                        onToggleDarkMode: widget
                                                            .onToggleDarkMode,
                                                        isDarkMode:
                                                            widget.isDarkMode,
                                                        userName: userName,
                                                        profileImg: profileImg,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Image.asset(
                                                    'images/tabler_menu_button.png',
                                                    height: 50),
                                              ),
                                              const Spacer(),
                                              Image.asset(
                                                  'images/tabler_help.png',
                                                  height: 50),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _isSearching =
                                                        true; // Start searching
                                                  });
                                                },
                                                child: Image.asset(
                                                    'images/tabler_search.png',
                                                    height: 50),
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
                                                    height: 50),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.05),

                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(55),
                                                child: Container(
                                                  width: (35 /
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width) *
                                                      MediaQuery.of(context)
                                                          .size
                                                          .width,
                                                  height: (35 /
                                                          MediaQuery.of(context)
                                                              .size
                                                              .height) *
                                                      MediaQuery.of(context)
                                                          .size
                                                          .height,
                                                  color: Colors.grey,
                                                  child: profileImg == null
                                                      ? Image.asset(
                                                          'images/Pexels Photo by 3Motional Studio.png',
                                                          fit: BoxFit.cover)
                                                      : Image.network(
                                                          profileImg!,
                                                          fit: BoxFit.cover),
                                                ),
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
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
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.05),
                                        // Balance Card
                                        _buildBalanceCard(),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.02),
                                        // Package Card
                                        _buildPackageCard(),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.02),
                                        // Signals Card
                                        _buildSignalsCard(),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.05),
                                        // Educational Content
                                        // _buildEducationalContent(),
                                        // SizedBox(
                                        //     height: MediaQuery.of(context).size.height *
                                        //         0.03),
                                        // // TabBar
                                        // _buildTabBar(),
                                        // SizedBox(
                                        //     height: MediaQuery.of(context).size.height *
                                        //         0.03),
                                        // // TabBarView
                                        // _buildTabBarView(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: (130 / MediaQuery.of(context).size.height) *
            MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(width: 0, color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Image.asset('images/Balance.png'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            const VerticalDivider(
                color: Colors.grey, thickness: 1.0, width: 20.0),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: (130 / MediaQuery.of(context).size.height) *
            MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(width: 0, color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Image.asset('images/Package.png'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            const VerticalDivider(
                color: Colors.grey, thickness: 1.0, width: 20.0),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
    );
  }

  Widget _buildSignalsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: (130 / MediaQuery.of(context).size.height) *
            MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(width: 0, color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Image.asset('images/Signals.png'),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            const VerticalDivider(
                color: Colors.grey, thickness: 1.0, width: 20.0),
            SizedBox(width: MediaQuery.of(context).size.width * 0.02),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationalContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Text(
            "Educational Content",
            style: TextStyle(
              fontFamily: 'Golos Text',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              if (_eduIndex == 0) {
                // Show NewsPage in a modal bottom sheet
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.8, // Set height for the bottom sheet
                      child: const NewsPage(), // Display the NewsPage
                    );
                  },
                );
              } else if (_eduIndex == 1) {
                // Show CoursePage in a modal bottom sheet
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.8, // Set height for the bottom sheet
                      child: const CoursePage(), // Display the CoursePage
                    );
                  },
                );
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
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: TabBar(
        tabAlignment: TabAlignment.start,
        controller: homeTab,
        isScrollable: true,
        tabs: [
          _buildTab('News'),
          _buildTab('Courses'),
        ],
        labelColor: Theme.of(context).colorScheme.onSurface,
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
        indicatorPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
      ),
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

  Widget _buildTabBarView() {
    return SizedBox(
      height: (400 / MediaQuery.of(context).size.height) *
          MediaQuery.of(context).size.height,
      child: TabBarView(
        controller: homeTab,
        children: [
          if (loadingNews)
            Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onSurface),
            )
          else if (errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      await fetchNews(isRefresh: true);
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'Inconsolata',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              controller: _newsScrollController,
              itemCount: news.length + adIndices.length,
              itemBuilder: (context, index) {
                int actualIndex = index;
                int adCount =
                    adIndices.where((adIndex) => adIndex < actualIndex).length;
                final newsIndex = actualIndex - adCount;

                // Display loader as the last item if loading is true
                if (_isLoadingMoreNews &&
                    index == news.length + adIndices.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Check if the current index should display an ad
                if (adIndices.contains(actualIndex)) {
                  _initializeAd(actualIndex);
                  BannerAd? bannerAd = _bannerAds[actualIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
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
                      horizontal: 20.0, vertical: 10.0),
                  child: newsCard(news[newsIndex]),
                );
              },
            ),
          if (loadingCourse)
            Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onSurface),
            )
          else if (errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      await fetchCourses(isRefresh: true);
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'Inconsolata',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (subscribedForCourse == false)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0),
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  Image.asset(
                    'images/LockedImg.png',
                    height: 120,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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
                if (_isLoadingMoreCourses && index == courses.length) {
                  // Show loading indicator at the bottom
                  return Center(
                      child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onSurface));
                }
                return Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0),
                  child: courseCard(courses[index]),
                );
              },
            ),
        ],
      ),
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
                          if (mounted) {
                            setState(() {
                              _shouldPlay = info.visibleFraction > 0.5;
                            });
                          }
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

  Widget _buildSplashScreen() {
    return Container(
      color: const Color(0xFFF2F2F2), // Background color
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                double imageSize =
                    constraints.maxWidth * 0.4; // 40% of the screen width
                return Image.asset(
                  'images/AppLogo.png',
                  width: imageSize.clamp(256.0, 1024.0),
                  height: imageSize.clamp(256.0, 1024.0),
                  fit: BoxFit.contain,
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [
                          Colors.black,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: const CircularProgressIndicator(
                      strokeWidth: 4.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const Icon(
                    Icons.circle,
                    size: 24.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
