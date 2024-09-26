import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signal_app/video_player_widget.dart';

class CardDetails extends StatefulWidget {
  final int course;

  const CardDetails({super.key, required this.course});

  @override
  CardDetailsState createState() => CardDetailsState();
}

class CardDetailsState extends State<CardDetails> {
  Map<String, dynamic>? courseDetails;
  String? errorMessage;
  final storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    print(widget.course);
    fetchCourseDetails(widget.course);
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

  Future<void> fetchCourseDetails(int id) async {
    setState(() {
      errorMessage = null;
    });
    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      final response = await http.get(
        Uri.parse('https://script.teendev.dev/signal/api/courses/$id?id=$id'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          courseDetails = json.decode(response.body);
        });
      } else if (response.statusCode == 401) {
        setState(() {
          errorMessage = json.decode(response.body)['message'];
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'No Course found!';
        });
      } else if (response.statusCode == 422) {
        setState(() {
          errorMessage = json.decode(response.body)['message'];
        });
      } else {
        setState(() {
          errorMessage = 'An unexpected error occurred.';
        });
        print('Unexpected error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Failed to load data. Please check your network connection.';
      });
      print('Exception caught: $e');
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
    await fetchCourseDetails(widget.course);
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

  Future<void> addBookmark(String type) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.post(
      Uri.parse('https://script.teendev.dev/signal/api/bookmark/add'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': type,
        'course_id': widget.course.toString(),
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
      });
      await fetchCourseDetails(widget.course);
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
      Uri.parse('https://script.teendev.dev/signal/api/bookmark/delete'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': widget.course.toString(),
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
      });
      await fetchCourseDetails(widget.course);
      setState(() {}); // Update the UI
    } else {
      _showCustomSnackBar(
        context,
        responseBody['message'] ?? 'An error occurred',
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
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: Center(
            child: SizedBox(
              height: orientation == Orientation.portrait
                  ? MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 1.5,
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.1),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: Image.asset(
                                      'images/tabler_arrow-back.png',height:50,),
                                ),
                                const Spacer(),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.05),
                          if (errorMessage != null) ...[
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
                            ),
                          ] else if (courseDetails != null) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Center(
                                child: Text(
                                  courseDetails!['title'],
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.03),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (courseDetails!['videos'] == null)
                                      // Display the image first
                                      Image.network(
                                        courseDetails!['images'],
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    else if (courseDetails!['videos'] != null)
                                      // Wrap the VideoPlayerWidget with GestureDetector
                                      GestureDetector(
                                        onTap: () {
                                          // Prevents tap from propagating
                                        },
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          // Adjust the aspect ratio as needed
                                          child: ClipRect(
                                            child: VideoPlayerWidget(
                                              videoUrl:
                                                  courseDetails!['videos'],
                                              shouldPlay: false,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      'https://via.placeholder.com/150', // Placeholder for author's image
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.01,
                                  ),
                                  Expanded(
                                    child: Text(
                                      courseDetails!['username'],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    courseDetails!['created_at'],
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                courseDetails!['article'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // SizedBox(
                            //   height: MediaQuery.of(context).size.height *
                            //       0.1,
                            // ),
                          ] else ...[
                            const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.black)),
                          ],
                        ],
                      ),
                    ),
                    // if (courseDetails != null)
                    //   Positioned(
                    //     bottom: 0,
                    //     child: Container(
                    //       height: (70 / MediaQuery.of(context).size.height) *
                    //           MediaQuery.of(context).size.height,
                    //       padding: const EdgeInsets.all(12.0),
                    //       decoration: BoxDecoration(
                    //         color: Colors.white,
                    //         border: Border.all(width: 0, color: Colors.black),
                    //         borderRadius: BorderRadius.circular(15),
                    //         boxShadow: [
                    //           BoxShadow(
                    //             color: Colors.grey.withOpacity(0.5),
                    //             spreadRadius: 3,
                    //             blurRadius: 5,
                    //           ),
                    //         ],
                    //       ),
                    //       child: SizedBox(
                    //         width: MediaQuery.of(context).size.width,
                    //         child: Padding(
                    //           padding:
                    //               const EdgeInsets.symmetric(horizontal: 20.0),
                    //           child: Row(children: [
                    //             SizedBox(
                    //                 width: MediaQuery.of(context).size.width *
                    //                     0.06),
                    //             // Row(
                    //             //   children: [
                    //             //     IconButton(
                    //             //       icon: const Icon(Icons.visibility),
                    //             //       onPressed: () {},
                    //             //     ),
                    //             //     SizedBox(width: MediaQuery.of(context).size.width * 0.01),
                    //             //     const Text(
                    //             //       '1K',
                    //             //       style: TextStyle(
                    //             //         fontFamily: 'Inconsolata',
                    //             //         fontSize: 15,
                    //             //         fontWeight: FontWeight.bold,
                    //             //         color: Colors.black,
                    //             //       ),
                    //             //     ),
                    //             //   ],
                    //             // ),
                    //             const Spacer(),
                    //             IconButton(
                    //               icon: Icon(
                    //                   isBookmarked
                    //                       ? Icons.bookmark
                    //                       : Icons.bookmark_border,
                    //                   color: isBookmarked
                    //                       ? Colors.blue
                    //                       : originalIconColor),
                    //               onPressed: () {
                    //                 if (isBookmarked == false) {
                    //                   addBookmark("course");
                    //                 } else if (isBookmarked == true) {
                    //                   removeBookmark();
                    //                 }
                    //               },
                    //             ),
                    //           ]),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
