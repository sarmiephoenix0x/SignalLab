import 'dart:convert';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signal_app/news_details.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:math'; // For Random
import 'package:google_mobile_ads/google_mobile_ads.dart'; // For ads

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final ScrollController _newsScrollController = ScrollController();
  final CarouselController _controller = CarouselController();
  List<dynamic> news = [];
  List<dynamic> latestNews = [];
  bool loadingNews = false;
  bool loadingLatestNews = false;
  String? errorMessage;
  bool loadingMoreNews = false;
  bool _isLoadingMoreNews = false;
  int currentNewsPage = 1; // Current page tracker
  int totalNewsPages = 1; // Total pages available
  bool isFetchingNews = false; // To prevent multiple fetch calls
  bool _hasMoreNews = true;
  int _currentPage = 0;
  List<int> adIndices = []; // tracks where ads are placed
  final Random random = Random();
  final int minCardsBetweenAds = 3; // Minimum cards before an ad
  final int maxRandomCards = 5; // Maximum random cards before an ad
  BannerAd? _bannerAd; // Store the banner ad
  bool _isAdLoaded = false;
  Map<int, BannerAd> _bannerAds = {};

  @override
  void initState() {
    super.initState();
    fetchLatestNews();
    fetchNews(isRefresh: true);
    _newsScrollController.addListener(_onScrollNews);
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
    _newsScrollController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Expanded(
                child: RefreshIndicator(
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
                                      height: (16 /
                                              MediaQuery.of(context)
                                                  .size
                                                  .height) *
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
                                              MediaQuery.of(context)
                                                  .size
                                                  .height,
                                          child: CarouselSlider(
                                            options: CarouselOptions(
                                              autoPlay: true,
                                              enlargeCenterPage: false,
                                              height: MediaQuery.of(context)
                                                  .size
                                                  .height,
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
                                          .where((adIndex) =>
                                              adIndex < actualIndex)
                                          .length;
                                      final newsIndex = actualIndex - adCount;

                                      // Display loader as the last item if loading is true
                                      if (_isLoadingMoreNews &&
                                          index ==
                                              news.length + adIndices.length) {
                                        return const Center(
                                            child: CircularProgressIndicator());
                                      }

                                      // Check if the current index should display an ad
                                      if (adIndices.contains(actualIndex)) {
                                        _initializeAd(actualIndex);
                                        BannerAd? bannerAd =
                                            _bannerAds[actualIndex];
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
              ),
            ],
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
}
