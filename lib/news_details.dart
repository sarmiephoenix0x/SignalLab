import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NewsDetails extends StatefulWidget {
  final int newsId;

  const NewsDetails({super.key, required this.newsId});

  @override
  NewsDetailsState createState() => NewsDetailsState();
}

class NewsDetailsState extends State<NewsDetails> {
  late Future<Map<String, dynamic>?> _newsFuture;
  final storage = const FlutterSecureStorage();
  final GlobalKey _key = GlobalKey();
  final FocusNode _commentFocusNode = FocusNode();

  final TextEditingController commentController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _newsFuture = fetchNewsDetails(widget.newsId);
  }

  Future<Map<String, dynamic>?> fetchNewsDetails(int id) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final url = 'https://script.teendev.dev/signal/api/news/$id';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.black));
          } else if (snapshot.hasError) {
            return const Center(child: Text('An unexpected error occurred'));
          } else if (snapshot.hasData) {
            final news = snapshot.data;
            if (news == null) {
              return const Center(child: Text('No news found'));
            }
            return OrientationBuilder(
              builder: (context, orientation) {
                return Scaffold(
                  body: Center(
                    child: SizedBox(
                      height: orientation == Orientation.portrait
                          ? MediaQuery.of(context).size.height
                          : MediaQuery.of(context).size.height * 1.5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.1,
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Image.asset(
                                            'images/tabler_arrow-back.png'),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.05,
                                  ),
                                  Row(
                                    children: [
                                      Image.asset('images/NewsProfileImg.png'),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.01,
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
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            Text(
                                              news['created_at'] ?? '',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.lightBlue,
                                                fontSize: 16,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.03,
                                  ),
                                  Text(
                                    news['title'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 16, fontFamily: 'Inter'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20.0),
                                    child: Image.network(
                                      news['images'] ?? '',
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 76.0),
                                    child: Text(
                                      news['article'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 16, fontFamily: 'Inter'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              height:
                                  (80 / MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(width: 0, color: Colors.black),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 3,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Row(children: [
                                    Image.asset(
                                      'images/camera-3-line.png',
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.04),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            child: SingleChildScrollView(
                                              child: TextFormField(
                                                keyboardType:
                                                    TextInputType.multiline,
                                                maxLines: null,
                                                controller: commentController,
                                                focusNode: _commentFocusNode,
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                  decoration:
                                                      TextDecoration.none,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 20,
                                                          right: 65,
                                                          bottom: 20,
                                                          top: 0),
                                                  labelText: 'Write a comment',
                                                  labelStyle: TextStyle(
                                                    color: Colors.grey,
                                                    fontFamily: 'Inter',
                                                    fontSize: 16.0,
                                                  ),
                                                  floatingLabelBehavior:
                                                      FloatingLabelBehavior
                                                          .never,
                                                  border: InputBorder.none,
                                                ),
                                                cursorColor: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: MediaQuery.of(context)
                                                    .padding
                                                    .left +
                                                10,
                                            bottom: 0,
                                            child: Image.asset(
                                              'images/user-smile-line.png',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
