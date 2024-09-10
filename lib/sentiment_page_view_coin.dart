import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class SentimentViewCoin extends StatefulWidget {
  final int sentimentId;
  final String sentimentTitle;
  final String sentimentImg;

  const SentimentViewCoin({super.key,
    required this.sentimentId,
    required this.sentimentTitle,
    required this.sentimentImg});

  @override
  // ignore: library_private_types_in_public_api
  _SentimentViewCoinState createState() => _SentimentViewCoinState();
}

class _SentimentViewCoinState extends State<SentimentViewCoin>
    with TickerProviderStateMixin {
  TabController? tabController;
  TabController? tabController2;
  String? errorMessage;
  final storage = const FlutterSecureStorage();
  List<dynamic> sentiments = [];
  bool loading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  Color _indicatorColor = Colors.green;
  bool isLoading = false;
  late final WebViewController _controller;
  final String coinSymbol = "BINANCE:BTCUSDT";
  String voteText = "UP";

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController2 = TabController(length: 3, vsync: this);
    tabController!.addListener(_handleTabSelection);
    _fetchSentimentDetails(widget.sentimentId);
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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          'https://s.tradingview.com/widgetembed/?symbol=$coinSymbol&interval=D&hidesidetoolbar=1&symboledit=1&saveimage=1&toolbarbg=f1f3f6&studies=[]&theme=Dark&style=1&timezone=Etc/UTC&studies_overrides={}&overrides={}&enabled_features=[]&disabled_features=[]&locale=en'));
  }

  @override
  void dispose() {
    tabController?.dispose();
    tabController2?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      switch (tabController!.index) {
        case 0:
          _indicatorColor = Colors.green;
          voteText = "UP";
          break;
        case 1:
          _indicatorColor = Colors.red;
          voteText = "DOWN";
          break;
      }
    });
  }

  Future<void> _fetchSentimentDetails(int id) async {
    setState(() {
      loading = true;
      errorMessage = null; // Reset error message before fetch
    });

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      final url = 'https://script.teendev.dev/signal/api/sentiment?id=$id';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        setState(() {
          final responseData = json.decode(response.body);
          sentiments =
          responseData is List<dynamic> ? responseData : [responseData];
          loading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          loading = false;
          errorMessage = 'Unauthorized. Please check your token.';
        });
        print(errorMessage);
      } else if (response.statusCode == 422) {
        final errorResponse = jsonDecode(response.body);
        setState(() {
          loading = false;
          errorMessage = 'Validation Error: ${errorResponse['message']}';
        });
        print(errorMessage);
      } else {
        setState(() {
          loading = false;
          errorMessage = 'Unexpected error occurred.';
        });
        print(errorMessage);
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage =
        'Failed to load data. Please check your network connection.';
      });
      print('Exception: $e');
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
    await _fetchSentimentDetails(widget.sentimentId);
    _controller.loadRequest(Uri.parse(
        'https://s.tradingview.com/widgetembed/?symbol=$coinSymbol&interval=D&hidesidetoolbar=1&symboledit=1&saveimage=1&toolbarbg=f1f3f6&studies=[]&theme=Dark&style=1&timezone=Etc/UTC&studies_overrides={}&overrides={}&enabled_features=[]&disabled_features=[]&locale=en'));
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

  Future<void> vote(String type) async {
    final String? accessToken = await storage.read(key: 'accessToken');

    final response = await http.post(
      Uri.parse('https://script.teendev.dev/signal/api/vote'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': type,
        'group': 'sentiment', // Specify the group if needed
        'id': widget.sentimentId,
      }),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully ${type == 'upvote' ? 'Upvoted' : 'Downvoted'}'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {}); // Update the UI
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseBody['message'] ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _share() {}

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: loading
              ? const Center(
              child: CircularProgressIndicator(color: Colors.black))
              : Center(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: Colors.black,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child:
                            Image.asset('images/tabler_arrow-back.png'),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 10,
                            child: Text(
                              widget.sentimentTitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.05),
                    if (loading)
                      const Center(
                        child: CircularProgressIndicator(
                            color: Colors.black),
                      )
                    else
                      if (errorMessage != null)
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
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20.0, right: 20.0, bottom: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // WebView content
                              SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.7, // Specify the height
                                child: WebViewWidget(controller: _controller),
                              ),
                              Center(
                                child:
                                Text(
                                  'Share your opinion',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.02),
                              Center(
                                child: Text(
                                  widget.sentimentTitle,
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.02),
                              // Voting buttons
                              _voteButtons(),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.02),
                              Center(
                                child: Text(
                                  "${widget
                                      .sentimentTitle} will go $voteText over the",
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.02),
                              _voteButtons2(),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.05),
                              Center(
                                child: Text(
                                  'Share your opinion',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: MediaQuery
                                  .of(context)
                                  .size
                                  .height * 0.05),

                              // Share button
                              Container(
                                width: double.infinity,
                                height: (60 / MediaQuery.of(context).size.height) *
                                    MediaQuery.of(context).size.height,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: ElevatedButton(
                                  onPressed:
                                  isLoading ? null : () => _share(),
                                  style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty
                                        .resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                        if (states.contains(
                                            MaterialState.pressed)) {
                                          return Colors.white;
                                        }
                                        return Colors.black;
                                      },
                                    ),
                                    foregroundColor: MaterialStateProperty
                                        .resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                        if (states.contains(
                                            MaterialState.pressed)) {
                                          return Colors.black;
                                        }
                                        return Colors.white;
                                      },
                                    ),
                                    elevation:
                                    MaterialStateProperty.all<double>(
                                        4.0),
                                    shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                      const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15)),
                                      ),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                      : const Text('Share',style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                  ),),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _voteButtons() {
    if (tabController != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(25),
            color: Colors.black,
          ),
          child: TabBar(
            onTap: (index) {
              if (index == 0) {
                vote('upvote');
              } else if (index == 1) {
                vote('downvote');
              }
            },
            indicator: BoxDecoration(
              color: _indicatorColor,
              borderRadius: BorderRadius.circular(25),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            overlayColor: WidgetStatePropertyAll(_indicatorColor),
            splashBorderRadius: BorderRadius.circular(25),
            dividerHeight: 0,
            controller: tabController!,
            tabs: [
              _buildCurvedTab('UP'),
              _buildCurvedTab('DOWN'),
            ],
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _voteButtons2() {
    if (tabController2 != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(25),
            color: Colors.black,
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            overlayColor: WidgetStatePropertyAll(Colors.white),
            splashBorderRadius: BorderRadius.circular(25),
            dividerHeight: 0,
            controller: tabController2!,
            tabs: [
              _buildCurvedTab('DAY'),
              _buildCurvedTab('WEEK'),
              _buildCurvedTab('MONTH'),
            ],
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildCurvedTab(String label) {
    return Tab(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
