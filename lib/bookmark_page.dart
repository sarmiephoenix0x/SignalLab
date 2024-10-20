import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signal_app/card_details.dart';
import 'package:signal_app/news_details.dart';
import 'package:signal_app/video_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({
    super.key,
  });

  @override
  BookmarkPageState createState() => BookmarkPageState();
}

class BookmarkPageState extends State<BookmarkPage>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  bool _isRefreshing = false;
  String? errorMessage;
  List<Map<String, dynamic>> bookmarkedNews = [];
  List<Map<String, dynamic>> bookmarkedCourses = [];
  late TabController homeTab;
  final storage = const FlutterSecureStorage();
  String newsImg = 'images/iconamoon_news-thin_active.png';
  String coursesImg = 'images/fluent-mdl2_publish-course.png';
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  bool isLastPage = false;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    homeTab = TabController(length: 2, vsync: this);
    homeTab.addListener(_handleTabSelection);
    _fetchBookmarkedItems();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLastPage) {
        _fetchBookmarkedItems(loadMore: true);
      }
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

  @override
void dispose() {
  _scrollController.dispose();
  super.dispose();
}

  void _handleTabSelection() {
    setState(() {
      switch (homeTab.index) {
        case 0:
          newsImg = 'images/iconamoon_news-thin_active.png';
          coursesImg = 'images/fluent-mdl2_publish-course.png';
          break;
        case 1:
          newsImg = 'images/iconamoon_news-thin.png';
          coursesImg = 'images/fluent-mdl2_publish-course_active.png';
          break;
      }
    });
  }

  Future<void> _fetchBookmarkedItems({bool loadMore = false}) async {
    if (loadMore && isLoadingMore) return; // Prevent multiple calls

    try {
      if (loadMore) {
        setState(() {
          isLoadingMore = true;
        });
      } else {
        setState(() {
          loading = true;
        });
      }

      final String? accessToken = await storage.read(key: 'accessToken');
      final response = await http.get(
        Uri.parse(
            'https://signal.payguru.com.ng/api/bookmark/get?page=$currentPage'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(response.body); // Parse as Map
        final Map<String, dynamic> dataMap =
            responseData['data']; // Extract 'data' map
        final List<Map<String, dynamic>> data = dataMap.values
            .toList()
            .cast<Map<String, dynamic>>(); // Convert map to list

        final pagination =
            responseData['pagination']; // Extract pagination details

        setState(() {
          if (loadMore) {
            // Append the new data to the existing list
            bookmarkedNews.addAll(data
                .where((item) => item['upvotes'] != null)
                .cast<Map<String, dynamic>>()
                .toList());
            bookmarkedCourses.addAll(data
                .where((item) => item['upvotes'] == null)
                .cast<Map<String, dynamic>>()
                .toList());
          } else {
            // Replace the list on initial load
            bookmarkedNews = data
                .where((item) => item['upvotes'] != null)
                .cast<Map<String, dynamic>>()
                .toList();
            bookmarkedCourses = data
                .where((item) => item['upvotes'] == null)
                .cast<Map<String, dynamic>>()
                .toList();
          }

          // Update pagination data
          isLastPage = pagination['next_page_url'] == null;
          currentPage++;
          loading = false;
          isLoadingMore = false;
        });
      } else if (response.statusCode == 400) {
        setState(() {
          errorMessage = "You don't have any bookmarks at the moment";
          loading = false;
          isLoadingMore = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = "Unauthorized";
          loading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred";
        loading = false;
        isLoadingMore = false;
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
        _fetchBookmarkedItems(),
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

  Widget _buildBookmarkedNewsList() {
    if (loading) {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onSurface));
    } else if (errorMessage != null) {
      return Center(
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
              onPressed: _fetchBookmarkedItems,
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
      );
    } else {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).colorScheme.onSurface,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: bookmarkedNews.length + (isLastPage ? 0 : 1),
          itemBuilder: (context, index) {
            if (index == bookmarkedNews.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return Padding(
              padding:
                  const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0),
              child: newsCard(bookmarkedNews[
                  index]), // Adjust as per your newsCard implementation
            );
          },
        ),
      );
    }
  }

  Widget _buildBookmarkedCoursesList() {
    if (loading) {
      return Center(
          child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onSurface));
    } else if (errorMessage != null) {
      return Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    } else {
      return RefreshIndicator(
        onRefresh: _refreshData,
        color: Theme.of(context).colorScheme.onSurface,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: bookmarkedCourses.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 0.0),
              child: courseCard(
                  bookmarkedCourses[index]), // Implement your courseCard widget
            );
          },
        ),
      );
    }
  }

  Widget _buildTab(String img, String name, {bool isLast = false}) {
    return Tab(
      child: Row(
        children: [
          Image.asset(img),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget newsCard(Map<String, dynamic> newsItem) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(
          bottom: 0.0), // Increased bottom padding for more spacing
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
                color: Colors.grey
                    .withOpacity(0.2), // Softer shadow for a clean look
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2), // Position shadow for depth
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to start
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                        8), // Slightly rounded image corners
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
                            fontWeight:
                                FontWeight.w500, // Semi-bold for emphasis
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
          padding: const EdgeInsets.symmetric(
              horizontal: 12.0, vertical: 6.0), // Padding around the tag
          decoration: BoxDecoration(
            color: Colors.blueAccent, // Modern blue color
            borderRadius: BorderRadius.circular(
                30), // More rounded corners for a pill-like shape
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
              color: Colors.white, // White text on blue background
              fontWeight: FontWeight.w600, // Slightly bolder font for emphasis
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
            elevation: 6.0, // Slight elevation for a modern look
            shadowColor: Colors.grey.shade300, // Softer shadow color
            margin: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(12.0), // Rounded edges for media
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
                            CircleAvatar(
                              backgroundImage: AssetImage(
                                'images/Pexels Photo by Pixabay.png', // Placeholder for user image
                              ),
                              radius: 16, // Size of avatar
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                    height: 50,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                Text(
                  'Bookmarks',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // TabBar(
          //   controller: homeTab,
          //   tabs: [
          //     _buildTab(newsImg, 'News'),
          //     // const Padding(
          //     //   padding: EdgeInsets.symmetric(horizontal: 8.0), // Adjust padding as needed
          //     //   child: Text(
          //     //     '|',
          //     //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //     //   ),
          //     // ),
          //     _buildTab(coursesImg, 'Courses', isLast: true),
          //   ],
          //   dividerHeight: 0,
          //   tabAlignment: TabAlignment.start,
          //   isScrollable: true,
          //   indicatorSize: TabBarIndicatorSize.label,
          //   labelColor: Colors.black,
          //   unselectedLabelColor: Colors.grey,
          //   labelStyle:
          //       const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //   unselectedLabelStyle:
          //       const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          //   indicator: const BoxDecoration(),
          // ),
          Expanded(
            child: _buildBookmarkedNewsList(),
          ),
          // Expanded(
          //   child: TabBarView(
          //     controller: homeTab,
          //     children: [
          //       _buildBookmarkedNewsList(),
          //       _buildBookmarkedCoursesList(),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
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
                _refreshData();
              },
            ),
          ],
        );
      },
    );
  }
}
