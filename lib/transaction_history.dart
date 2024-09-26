import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  TransactionHistoryState createState() => TransactionHistoryState();
}

class TransactionHistoryState extends State<TransactionHistory> {
  late Future<List<Map<String, dynamic>>> _transactionsFuture;
  final storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = fetchTransactions();
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

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final String? accessToken = await storage.read(key: 'accessToken');
    const url = 'https://script.teendev.dev/signal/api/transactions';
    final response = await http.get(Uri.parse(url), headers: {
      'Authorization': 'Bearer $accessToken',
    });

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((transaction) {
        return {
          "id": transaction["id"],
          "amount": transaction["amount"],
          "reason": transaction["reason"],
          "time": transaction["time"],
        };
      }).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to load transactions');
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
    setState(() {
      _transactionsFuture = fetchTransactions();
    });
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

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshData,
            color: Colors.black,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.black));
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
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No transactions available',
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

                List<Map<String, dynamic>> transactions = snapshot.data!;
                Map<String, List<Map<String, dynamic>>> groupedTransactions =
                {};

                for (var transaction in transactions) {
                  String formattedDate = formatDate(transaction['created_at']);
                  if (groupedTransactions.containsKey(formattedDate)) {
                    groupedTransactions[formattedDate]!.add(transaction);
                  } else {
                    groupedTransactions[formattedDate] = [transaction];
                  }
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.1,
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child:
                              Image.asset('images/tabler_arrow-back.png',height:50,),
                            ),
                            const Spacer(),
                            const Text(
                              'Transaction History',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.1),
                            const Spacer(),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.05,
                        ),
                        ...groupedTransactions.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.02,
                              ),
                              Column(
                                children: entry.value.map((transaction) {
                                  return Padding(
                                    padding:
                                    const EdgeInsets.only(bottom: 15.0),
                                    child: transactionWidget(
                                      'images/iconamoon_transaction.png',
                                      transaction['description'],
                                      transaction['created_at'],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget transactionWidget(String img, String description, String time) {
    return Row(
      children: [
        SizedBox(width: MediaQuery
            .of(context)
            .size
            .width * 0.02),
        Image.asset(img),
        SizedBox(width: MediaQuery
            .of(context)
            .size
            .width * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                softWrap: true,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.02),
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

  String formatDate(String dateString) {
    try {
      DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('yMMMd').format(parsedDate);
    } catch (e) {
      if (dateString.contains('days ago')) {
        int daysAgo = int.tryParse(dateString.split(' ')[0]) ?? 0;
        DateTime now = DateTime.now();
        DateTime pastDate = now.subtract(Duration(days: daysAgo));
        return DateFormat('yMMMd').format(pastDate);
      }
      return dateString;
    }
  }
}
