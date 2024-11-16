import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signal_app/card_details.dart';
import 'package:signal_app/packages_page.dart';
import 'package:signal_app/video_player_widget.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({super.key});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final ScrollController _courseScrollController = ScrollController();
  List<dynamic> courses = [];
  bool loadingCourse = false;
  String? errorMessage;
  bool _isLoadingMoreCourses = false;
  int currentCoursePage = 1; // Current page tracker
  int totalCoursePages = 1; // Total pages available
  bool isFetchingCourse = false; // To prevent multiple fetch calls
  bool loadingMoreCourses = false;
  bool _hasMoreCourses = true;
  bool subscribedForCourse = true;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    // if (subscribedForCourse == false) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _showFilterOverlay();
    //   });
    // }
    fetchCourses(isRefresh: true);
    _courseScrollController.addListener(_onScrollCourse);
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

  void _onScrollCourse() {
    if (_courseScrollController.position.pixels >=
            _courseScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreCourses) {
      _fetchMoreCourses();
    }
  }

  void _showFilterOverlay() {
    final overlay = Overlay.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    _overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: GestureDetector(
          onTap: () {
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
    }
  }

  @override
  void dispose() {
    _courseScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Courses',
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
                    await fetchCourses(isRefresh: true);
                  },
                  child: loadingCourse
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
                              itemCount: courses.length +
                                  (_isLoadingMoreCourses ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (_isLoadingMoreCourses &&
                                    index == courses.length) {
                                  // Show loading indicator at the bottom
                                  return Center(
                                      child: CircularProgressIndicator(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface));
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 20.0, right: 20.0, top: 0.0),
                                  child: courseCard(courses[
                                      index]), // Your course card widget
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ],
      ),
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
}
