import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart' hide CarouselController;
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
import 'package:carousel_slider/carousel_slider.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({
    super.key,
  });

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage>
    with TickerProviderStateMixin {
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
  List<dynamic> latestNews = [];

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
  final CarouselController _controller = CarouselController();
  int _currentPage = 0;
  String newsImg = 'images/iconamoon_news-thin_active.png';
  String coursesImg = 'images/fluent-mdl2_publish-course_active.png';

  @override
  void initState() {
    super.initState();
    fetchLatestNews();
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
      fetchLatestNews();
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
        body: Stack(
          children: [
            OrientationBuilder(
              builder: (context, orientation) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshData,
                      color: Theme.of(context).colorScheme.onSurface,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.05),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                'Articles',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
                            // TabBar
                            _buildTabBar(),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03),
                            // TabBarView
                            _buildTabBarView(),
                          ],
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

  Widget _buildTabBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white, // Background color
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          tabAlignment: TabAlignment.start,
          controller: homeTab,
          isScrollable: true,
          tabs: [
            _buildTab(newsImg, 'News', isDarkMode),
            _buildTab(coursesImg, 'Courses', isDarkMode),
          ],
          labelColor:
              isDarkMode ? Colors.white : Colors.black, // Selected tab color
          unselectedLabelColor: isDarkMode
              ? Colors.grey.withOpacity(0.5)
              : Colors.grey, // Unselected tab color
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Golos Text',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Golos Text',
          ),
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white : Colors.black,
                width: 2,
              ),
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
    );
  }

  Widget _buildTab(String img, String name, bool isDarkMode) {
    bool isSelected = homeTab.index ==
        (name == 'News' ? 0 : 1); // Check if the tab is selected

    return Tab(
      child: Row(
        children: [
          Image.asset(
            img,
            width: 24, // Adjust the size of the images
            height: 24,
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey, // Color of the images
          ),
          const SizedBox(width: 10), // Space between image and text
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.grey, // Color for tab text
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: TabBarView(
        controller: homeTab,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await fetchLatestNews();
              await fetchNews(isRefresh: true);
            },
            child: loadingNews
                ? Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onSurface),
                  )
                : errorMessage != null
                    ? Center(
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
                            SizedBox(
                                height:
                                    (16 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height),
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10.0),
                                  child: SizedBox(
                                    height: (160.0 /
                                            MediaQuery.of(context)
                                                .size
                                                .height) *
                                        MediaQuery.of(context).size.height,
                                    child: CarouselSlider(
                                      options: CarouselOptions(
                                        autoPlay: true,
                                        enlargeCenterPage: false,
                                        height:
                                            MediaQuery.of(context).size.height,
                                        viewportFraction: 1.0,
                                        enableInfiniteScroll: true,
                                        initialPage: 0,
                                        onPageChanged: (index, reason) {
                                          setState(() {
                                            _currentPage = index;
                                          });
                                        },
                                      ),
                                      carouselController: _controller,
                                      items: latestNews.map((newsItem) {
                                        return latestNewsCard(newsItem);
                                      }).toList(),
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
                              itemCount: news.length + adIndices.length,
                              itemBuilder: (context, index) {
                                int actualIndex = index;
                                int adCount = adIndices
                                    .where((adIndex) => adIndex < actualIndex)
                                    .length;
                                final newsIndex = actualIndex - adCount;

                                // Display loader as the last item if loading is true
                                if (_isLoadingMoreNews &&
                                    index == news.length + adIndices.length) {
                                  return const Center(
                                      child: CircularProgressIndicator());
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
                                  return const SizedBox.shrink();
                                }

                                // Display the news card
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 10.0),
                                  child: newsCard(news[newsIndex]),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.grey,
                    child: Image.network(
                      newsItem['user_profile_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newsItem['user'] ?? 'Unknown User',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              newsItem['title'],
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Article snippet
            Text(
              newsItem['article'].split('. ').first +
                  '...', // Display the first sentence as a snippet
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            // Created time
            Text(
              newsItem['created_at'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white54 : Colors.black38,
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
