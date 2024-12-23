import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsDetails extends StatefulWidget {
  final int newsId;
  final String tags;

  const NewsDetails({super.key, required this.newsId, required this.tags});

  @override
  NewsDetailsState createState() => NewsDetailsState();
}

class NewsDetailsState extends State<NewsDetails> {
  late Future<Map<String, dynamic>?> _newsFuture;
  final storage = const FlutterSecureStorage();
  final GlobalKey _key = GlobalKey();
  final FocusNode _commentFocusNode = FocusNode();

  final TextEditingController commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool isLiked = false;
  bool isBookmarked = false;
  InterstitialAd? _interstitialAd;
  int pageOpenCount = 0; // Count of how many times the page is opened
  bool isAdLoaded = false;
  Completer<void> _adLoadCompleter = Completer<void>();

  void _showPopupMenu(BuildContext context) async {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
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
                height: 25,
                color: Theme.of(context).colorScheme.onSurface,
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
                height: 25,
                color: Theme.of(context).colorScheme.onSurface,
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
                height: 25,
                color: Theme.of(context).colorScheme.onSurface,
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
                height: 25,
                color: Theme.of(context).colorScheme.onSurface,
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

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
    _loadPageOpenCount();
    _newsFuture = fetchNewsDetails(widget.newsId);
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

  Future<void> _loadPageOpenCount() async {
    final prefs = await SharedPreferences.getInstance();

    // Wait for the ad to be loaded
    await _loadInterstitialAd();

    setState(() {
      pageOpenCount = prefs.getInt('pageOpenCount') ?? 0;
      print(pageOpenCount);
      pageOpenCount++; // Increment each time the page is opened
      prefs.setInt('pageOpenCount', pageOpenCount);

      // Check if we should show an ad (randomly after 3 or more opens)
      if (pageOpenCount >= 3 && _shouldShowAd()) {
        _showInterstitialAd();
        print("Show ad ooooo");
      }
    });
  }

  bool _shouldShowAd() {
    // Add some randomness or a threshold to avoid showing ads too frequently
    return pageOpenCount % 3 == 0 || pageOpenCount % 4 == 0;
  }

  Future<void> _loadInterstitialAd() async {
    print('Attempting to load interstitial ad...');

    // Reset the Completer each time you load an ad
    _adLoadCompleter = Completer<void>();

    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ad unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          print('Interstitial Ad Loaded');
          _interstitialAd = ad;
          isAdLoaded = true;

          // Complete the Completer to signal that the ad is loaded
          _adLoadCompleter.complete();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load interstitial ad: $error');
          isAdLoaded = false;

          // Complete the Completer even if the ad fails to load
          _adLoadCompleter.complete();
          _retryLoadingAd(); // Retry loading after failure
        },
      ),
    );

    // Wait for the ad to be fully loaded (or failed) before continuing
    await _adLoadCompleter.future;
  }

  void _retryLoadingAd() {
    print('Retry loading interstitial ad in 5 seconds...');
    Future.delayed(Duration(seconds: 5), () {
      _loadInterstitialAd();
    });
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('Interstitial Ad is null');
      return;
    }

    if (!isAdLoaded) {
      print('Interstitial Ad is not loaded yet');
      return;
    }

    // Attach the FullScreenContentCallback before showing the ad
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose(); // Dispose the ad after it's shown
        _loadInterstitialAd(); // Load a new ad
        print('Load New InterstitialAd after dismissing');
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('Failed to show interstitial ad: $error');
        ad.dispose();
        _loadInterstitialAd(); // Reload if failed to show
      },
    );

    print('Show InterstitialAd');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _interstitialAd!.show();
    });
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> fetchNewsDetails(int id) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final url = 'https://signal.payguru.com.ng/api/news/$id';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final news = jsonDecode(response.body);

        // Set booleans based on response
        setState(() {
          isLiked = news['upvotes'] > 0; // True if upvotes > 0
        });
        checkIfNewsIsBookmarked(id.toString());
        return news;
      } else {
        // Handle different status codes
        if (response.statusCode == 401) {
          // Unauthorized, handle accordingly
          print('Unauthorized request');
        } else if (response.statusCode == 404) {
          // Not Found, handle accordingly
          print('No News Exists with this ID');
        } else if (response.statusCode == 400 || response.statusCode == 422) {
          // Bad Request or Unprocessable Entity
          final responseBody = jsonDecode(response.body);
          print('Error: ${responseBody['message']}');
          // Handle the validation errors if any
          if (responseBody['errors'] != null) {
            print('Validation Errors: ${responseBody['errors']}');
          }
        }
        return null;
      }
    } catch (e) {
      print('An unexpected error occurred: $e');
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
    _newsFuture = fetchNewsDetails(widget.newsId);
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

  Future<void> vote() async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.post(
      Uri.parse('https://signal.payguru.com.ng/api/news/vote'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'news_id': widget.newsId,
      }),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Show success message
      _showCustomSnackBar(
        context,
        responseBody['message'],
        isError: false,
      );

      setState(() {
        isLiked = true;
        _newsFuture = fetchNewsDetails(widget.newsId);
      });
      setState(() {}); // Update the UI
    } else {
      _showCustomSnackBar(
        context,
        responseBody['message'] ?? 'An error occurred',
        isError: true,
      );
    }
  }

  Future<void> addBookmark(String type) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.post(
      Uri.parse('https://signal.payguru.com.ng/api/bookmark/add'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': type,
        'news_id': widget.newsId.toString(),
      }),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Show success message
      _showCustomSnackBar(
        context,
        responseBody['message'],
        isError: false,
      );

      setState(() {
        isBookmarked = true;
        _newsFuture = fetchNewsDetails(widget.newsId);
      });
      setState(() {}); // Update the UI
    } else {
      _showCustomSnackBar(
        context,
        responseBody['message'] ?? 'An error occurred',
        isError: true,
      );
    }
  }

  Future<void> removeBookmark() async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.post(
      Uri.parse('https://signal.payguru.com.ng/api/bookmark/delete'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': widget.newsId.toString(),
      }),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Show success message
      _showCustomSnackBar(
        context,
        responseBody['message'],
        isError: false,
      );

      setState(() {
        isBookmarked = false;
        _newsFuture = fetchNewsDetails(widget.newsId);
      });
      setState(() {}); // Update the UI
    } else {
      _showCustomSnackBar(
        context,
        responseBody['message'] ?? 'An error occurred',
        isError: true,
      );
    }
  }

  Future<void> checkIfNewsIsBookmarked(String newsId) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('https://signal.payguru.com.ng/api/bookmark/exist/$newsId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        isBookmarked = true;
      });
      setState(() {});
    } else {
      setState(() {
        isBookmarked = false;
      });
    }
  }

  String _formatUpvotes(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K'; // Appends 'K' for 1000+
    } else {
      return count.toString();
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
    Color originalIconColor = IconTheme.of(context).color ?? Colors.black;
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: SizedBox(
              height: orientation == Orientation.portrait
                  ? MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 1.5,
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: Theme.of(context).colorScheme.onSurface,
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _newsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onSurface));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final news = snapshot.data;
                      if (news == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No news found',
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
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
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
                                      // SizedBox(
                                      //     width:
                                      //     MediaQuery
                                      //         .of(context)
                                      //         .size
                                      //         .width * 0.02),
                                      // Expanded(
                                      //   flex: 10,
                                      //   child: Text(
                                      //     'News',
                                      //     overflow: TextOverflow.ellipsis,
                                      //     style: TextStyle(
                                      //       fontFamily: 'Inter',
                                      //       fontWeight: FontWeight.bold,
                                      //       fontSize: 22.0,
                                      //       color: Theme.of(context).colorScheme.onSurface,
                                      //     ),
                                      //   ),
                                      // ),
                                      const Spacer(),
                                      SizedBox(
                                        key: _key,
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.more_vert_outlined),
                                          onPressed: () {
                                            _showPopupMenu(context);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.05,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(55),
                                        child: Container(
                                          width: (40 /
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width) *
                                              MediaQuery.of(context).size.width,
                                          height: (40 /
                                                  MediaQuery.of(context)
                                                      .size
                                                      .height) *
                                              MediaQuery.of(context)
                                                  .size
                                                  .height,
                                          color: Colors.grey,
                                          child: Image.network(
                                            news['user_profile_image'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(Icons
                                                  .error); // Show an error icon if image fails to load
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              news['user'] ?? '',
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
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: Image.network(
                                      news['images'] ?? '',
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Text(
                                    news['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Text(
                                    news['created_at'] ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: _buildTag(widget.tags),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Text(
                                    news['article'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 16, fontFamily: 'Inter'),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom:
                                20, // Distance from the bottom of the screen
                            right:
                                20, // Distance from the right side of the screen
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Like button with number
                                Column(
                                  children: [
                                    FloatingActionButton(
                                      onPressed: () {
                                        if (!isLiked) {
                                          vote();
                                        }
                                      },
                                      backgroundColor: isLiked
                                          ? Colors.red
                                          : Colors.grey.shade300,
                                      mini: true,
                                      child: Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            4), // Space between FAB and number
                                    Text(
                                      _formatUpvotes(news[
                                          'upvotes']), // Use your existing method
                                      style: const TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                    height:
                                        16), // Space between Like and Comment sections

                                // Comment button with number
                                Column(
                                  children: [
                                    FloatingActionButton(
                                      onPressed: () {
                                        // Action to open comments section
                                      },
                                      backgroundColor: Colors.grey.shade300,
                                      mini: true,
                                      child: const Icon(
                                        Icons.comment,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(
                                        height:
                                            4), // Space between FAB and number
                                    const Text(
                                      '0', // Replace with dynamic comment count
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                    height:
                                        16), // Space between Comment and Bookmark sections

                                // Bookmark button (no number needed for bookmark)
                                FloatingActionButton(
                                  onPressed: () {
                                    if (!isBookmarked) {
                                      addBookmark("news");
                                    } else {
                                      removeBookmark();
                                    }
                                  },
                                  backgroundColor: isBookmarked
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  mini: true,
                                  child: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No data available',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          );
        },
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
            color: Colors.grey,
            // Modern blue color
            borderRadius: BorderRadius.circular(30),
            // More rounded corners for a pill-like shape
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
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
              color: Colors.black,
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
}
