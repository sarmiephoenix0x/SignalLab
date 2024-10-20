import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  final storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _totalPages = 1;
  late Future<void> _initialLoadFuture;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _fetchInitialNotifications();
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

  Future<void> _fetchInitialNotifications() async {
    _currentPage = 1; // Reset page count
    _notifications =
        await fetchNotifications(page: _currentPage); // Fetch the first page
    _totalPages =
        3; // Example total pages, replace this with your API's total pages
    setState(() {}); // Update the UI after the first fetch
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({int page = 1}) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final url = 'https://signal.payguru.com.ng/api/notifications?page=$page';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      List<dynamic> jsonData = responseBody['data'];
      _currentPage = responseBody['pagination']['current_page'];
      _totalPages = responseBody['pagination']['total_pages'];

      return jsonData.map((notification) {
        return {
          "id": notification["id"],
          "message": notification["message"],
          "created_at": notification["created_at"],
        };
      }).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_currentPage >= _totalPages || _isLoadingMore)
      return; // Avoid loading if no more pages
    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    List<Map<String, dynamic>> moreNotifications =
        await fetchNotifications(page: _currentPage);

    setState(() {
      _notifications.addAll(moreNotifications); // Append new notifications
      _isLoadingMore = false;
    });
  }

  DateTime parseRelativeDate(String relativeDate) {
    final now = DateTime.now();
    final dateFormats = {
      'day': const Duration(days: 1),
      'hours': const Duration(hours: 1),
      'minutes': const Duration(minutes: 1),
    };

    for (var format in dateFormats.keys) {
      if (relativeDate.contains(format)) {
        final amount = int.parse(relativeDate.split(" ")[0]);
        return now.subtract(dateFormats[format]! * amount);
      }
    }

    return now; // Fallback to current date if parsing fails
  }

  String formatDate(String dateString) {
    try {
      // Try parsing the date in ISO format
      DateTime parsedDate = DateTime.parse(dateString);
      // Format the parsed date as needed
      return DateFormat('yMMMd').format(parsedDate);
    } catch (e) {
      // Handle cases like "5 days ago"
      if (dateString.contains('days ago')) {
        int daysAgo = int.tryParse(dateString.split(' ')[0]) ?? 0;
        DateTime calculatedDate =
            DateTime.now().subtract(Duration(days: daysAgo));
        return DateFormat('yMMMd').format(calculatedDate);
      }
      // If the date format is unknown, return the original string
      return dateString;
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
    await _fetchInitialNotifications();
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
              child: Text('Retry',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
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

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.black,
          child: FutureBuilder<void>(
            future: _initialLoadFuture,
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (_notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No notifications available',
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group notifications by date
              Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

              for (var notification in _notifications) {
                String formattedDate = formatDate(notification['created_at']);
                if (groupedNotifications.containsKey(formattedDate)) {
                  groupedNotifications[formattedDate]!.add(notification);
                } else {
                  groupedNotifications[formattedDate] = [notification];
                }
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                      !_isLoadingMore) {
                    _loadMoreNotifications(); // Load more when scrolled to bottom
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1,
                        ),
                        Row(
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
                            const Spacer(),
                            Text(
                              'Notification',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(
                                width: MediaQuery.of(context).size.width * 0.1),
                            const Spacer(),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                        ...groupedNotifications.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Column(
                                children: entry.value.map((notification) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 15.0),
                                    child: notificationWidget(
                                      'images/iconamoon_news-thin_active.png',
                                      notification['message'],
                                      notification['created_at'],
                                    ),
                                  );
                                }).toList(),
                              ),
                              if (_isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget notificationWidget(String img, String message, String time) {
    return Row(
      children: [
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Image.asset(img, color: Theme.of(context).colorScheme.onSurface),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                time,
                style: TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
