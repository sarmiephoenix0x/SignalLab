import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({
    super.key,
  });

  @override
  NotificationPageState createState() => NotificationPageState();
}

class NotificationPageState extends State<NotificationPage> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _notificationsFuture = fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final String? accessToken = await storage.read(key: 'accessToken');
    const url = 'https://script.teendev.dev/signal/api/notifications';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
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

  DateTime parseRelativeDate(String relativeDate) {
    final now = DateTime.now();

    if (relativeDate.contains("day")) {
      final daysAgo = int.parse(relativeDate.split(" ")[0]);
      return now.subtract(Duration(days: daysAgo));
    }
    // Handle other cases (e.g., hours ago, minutes ago) if necessary

    return now; // Fallback to current date if parsing fails
  }

  String formatDate(String relativeDate) {
    final parsedDate = parseRelativeDate(relativeDate);
    final today = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    if (parsedDate.year == today.year &&
        parsedDate.month == today.month &&
        parsedDate.day == today.day) {
      return 'Today';
    } else if (parsedDate.year == yesterday.year &&
        parsedDate.month == yesterday.month &&
        parsedDate.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.black));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No notifications available'));
              }

              List<Map<String, dynamic>> notifications = snapshot.data!;
              Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

              for (var notification in notifications) {
                String formattedDate = formatDate(notification['created_at']);
                if (groupedNotifications.containsKey(formattedDate)) {
                  groupedNotifications[formattedDate]!.add(notification);
                } else {
                  groupedNotifications[formattedDate] = [notification];
                }
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupedNotifications.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.05),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.02),
                          Column(
                            children: entry.value.map((notification) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: notificationWidget(
                                  'images/iconamoon_news-thin_active.png',
                                  notification['message'],
                                  notification['created_at'],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget notificationWidget(String img, String message, String time) {
    return Row(
      children: [
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Image.asset(
          img,
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                softWrap: true,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
