import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

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
          errorMessage = null;
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
        errorMessage = 'An error occurred: $e';
      });
      print('Exception caught: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await fetchCourseDetails(widget.course);
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: Center(
            child: SizedBox(
              height: orientation == Orientation.portrait
                  ? MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 1.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Image.asset('images/tabler_arrow-back.png'),
                          ),
                          const Spacer(),
                        ],
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      if (errorMessage != null) ...[
                        Center(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (courseDetails != null) ...[
                        Center(
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
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03),
                        Image.network(
                          courseDetails!['images'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundImage: NetworkImage(
                                'https://via.placeholder.com/150', // Placeholder for author's image
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01,
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
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        Text(
                          courseDetails!['article'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        const Center(
                            child:
                                CircularProgressIndicator(color: Colors.black)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
