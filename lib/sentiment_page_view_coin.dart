import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SentimentViewCoin extends StatefulWidget {
  final int sentimentId;
  final String sentimentTitle;
  final String sentimentImg;

  const SentimentViewCoin(
      {super.key,
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
  bool isLoading2 = false;
  late final WebViewController _controller;
  final String coinSymbol = "BINANCE:BTCUSDT";
  String voteText = "UP";
  String currentVote = "upvote";
  bool _notifyActive = false;
  bool shared = false;
  Offset _fabPosition = Offset.zero;
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();
  bool tooltipShown = false;

  @override
  void initState() {
    super.initState();
    _checkTooltipStatus();
    tabController = TabController(length: 2, vsync: this);
    tabController2 = TabController(length: 4, vsync: this);
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
    // Define your indicators here
    String studies = '["MA@tv-basicstudies", "RSI@tv-basicstudies"]';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          'https://s.tradingview.com/widgetembed/?symbol=$coinSymbol&interval=D&hidesidetoolbar=1&symboledit=1&saveimage=1&toolbarbg=f1f3f6&studies=$studies&theme=Dark&style=1&timezone=Etc/UTC&studies_overrides={}&overrides={}&enabled_features=[]&disabled_features=[]&locale=en'));
  }

  @override
  void dispose() {
    tabController?.dispose();
    tabController2?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Set the initial position of the FAB to the bottom-right corner of the screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      _fabPosition = Offset(
          screenWidth - 76,
          screenHeight -
              136); // 76 and 136 are offsets for padding and FAB size
    });
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
      final url = 'https://signal.payguru.com.ng/api/sentiment?id=$id';

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

          if (sentiments.isNotEmpty) {
            String time = sentiments[0]
                ['time']; // Assuming you want the first sentiment's time
            switch (time) {
              case 'daily':
                tabController2!.index = 0;
                break;
              case 'weekly':
                tabController2!.index = 1;
                break;
              case 'monthly':
                tabController2!.index = 2;
                break;
              case 'yearly':
                tabController2!.index = 3;
                break;
              default:
                // Handle unexpected values if necessary
                tabController2!.index =
                    0; // Default to daily or any other logic
                break;
            }
          }
        });
        if (!tooltipShown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tooltipKey.currentState?.ensureTooltipVisible();
            _markTooltipAsShown();
          });
        }
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
    setState(() {
      isLoading2 = true;
    });
    final response = await http.post(
      Uri.parse('https://signal.payguru.com.ng/api/vote'),
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
      _showCustomSnackBar(
        context,
        'Successfully ${type == 'upvote' ? 'Upvoted' : 'Downvoted'}',
        isError: false,
      );

      setState(() {
        shared = true;
        isLoading2 = false;
      });
      setState(() {}); // Update the UI
    } else {
      _showCustomSnackBar(
        context,
        responseBody['message'] ?? 'An error occurred',
        isError: true,
      );

      setState(() {
        isLoading2 = false;
      });
    }
  }

  void _share() {
    vote(currentVote);
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

  Future<void> _checkTooltipStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tooltipShown = prefs.getBool('tooltipShown') ?? false;
    });
  }

  Future<void> _markTooltipAsShown() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tooltipShown', true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: loading
              ? Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onSurface))
              : Center(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: Theme.of(context).colorScheme.onSurface,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
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
                                    const Spacer(),
                                    Expanded(
                                      flex: 10,
                                      child: Text(
                                        widget.sentimentTitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Inconsolata',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.001),
                              if (loading)
                                Center(
                                  child: CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                )
                              else if (errorMessage != null)
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
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // WebView content
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.5, // Specify the height
                                      child: WebViewWidget(
                                          controller: _controller),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.01),
                                    Center(
                                      child: Text(
                                        'Share your opinion',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Inconsolata',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.01),
                                    Center(
                                      child: Text(
                                        "${widget.sentimentTitle} will go",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Inconsolata',
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    // Voting buttons
                                    _voteButtons(),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    Center(
                                      child: Text(
                                        "${widget.sentimentTitle} will go $voteText over the",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Inconsolata',
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.01),
                                    _voteButtons2(),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 20.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 10,
                                            child: Text(
                                              'Notify me when the prediction has finished',
                                              softWrap: true,
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20.0),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _notifyActive =
                                                      !_notifyActive;
                                                });
                                              },
                                              child: Stack(
                                                children: [
                                                  Image.asset(
                                                    'images/RadioButBody.png',
                                                    fit: BoxFit.cover,
                                                    color: _notifyActive
                                                        ? Colors.black
                                                        : null,
                                                  ),
                                                  AnimatedPositioned(
                                                    bottom:
                                                        MediaQuery.of(context)
                                                                .padding
                                                                .bottom +
                                                            -3,
                                                    left: _notifyActive
                                                        ? MediaQuery.of(context)
                                                                .padding
                                                                .left +
                                                            16
                                                        : MediaQuery.of(context)
                                                                .padding
                                                                .left +
                                                            -2,
                                                    duration: const Duration(
                                                        milliseconds: 160),
                                                    child: Image.asset(
                                                      'images/RadioButHandle.png',
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // SizedBox(
                                    //     height:
                                    //         MediaQuery.of(context).size.height *
                                    //             0.05),
                                    //
                                    // // Share button
                                    // Container(
                                    //   width: double.infinity,
                                    //   height: (60 /
                                    //           MediaQuery.of(context)
                                    //               .size
                                    //               .height) *
                                    //       MediaQuery.of(context).size.height,
                                    //   padding: const EdgeInsets.symmetric(
                                    //       horizontal: 20.0),
                                    //   child: ElevatedButton(
                                    //     onPressed:
                                    //         isLoading ? null : () => _share(),
                                    //     style: ButtonStyle(
                                    //       backgroundColor: MaterialStateProperty
                                    //           .resolveWith<Color>(
                                    //         (Set<MaterialState> states) {
                                    //           if (states.contains(
                                    //               MaterialState.pressed)) {
                                    //             return Colors.white;
                                    //           }
                                    //           return Colors.black;
                                    //         },
                                    //       ),
                                    //       foregroundColor: MaterialStateProperty
                                    //           .resolveWith<Color>(
                                    //         (Set<MaterialState> states) {
                                    //           if (states.contains(
                                    //               MaterialState.pressed)) {
                                    //             return Colors.black;
                                    //           }
                                    //           return Colors.white;
                                    //         },
                                    //       ),
                                    //       elevation:
                                    //           MaterialStateProperty.all<double>(
                                    //               4.0),
                                    //       shape: MaterialStateProperty.all<
                                    //           RoundedRectangleBorder>(
                                    //         const RoundedRectangleBorder(
                                    //           borderRadius: BorderRadius.all(
                                    //               Radius.circular(15)),
                                    //         ),
                                    //       ),
                                    //     ),
                                    //     child: isLoading2
                                    //         ? const CircularProgressIndicator(
                                    //             color: Colors.white,
                                    //           )
                                    //         : const Text(
                                    //             'Share',
                                    //             style: TextStyle(
                                    //               fontFamily: 'Inter',
                                    //               fontWeight: FontWeight.bold,
                                    //             ),
                                    //           ),
                                    //   ),
                                    // ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (shared)
                          Positioned.fill(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  shared = false;
                                });
                              },
                              child: Container(
                                color: Colors.black.withOpacity(0.5),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'images/Submitted-Tick.png',
                                        height: 60,
                                      ),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.02),
                                      const Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        child: Center(
                                          child: Text(
                                            "Your opinion has been shared with the community",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]),
                              ),
                            ),
                          ),
                        Positioned(
                          left: _fabPosition.dx.clamp(0.0, screenWidth - 56),
                          // Keep within left-right screen bounds
                          top: _fabPosition.dy.clamp(0.0, screenHeight - 56),
                          // Keep within top-bottom screen bounds
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                // Calculate the new position but constrain it within screen bounds
                                _fabPosition = Offset(
                                  (_fabPosition.dx + details.delta.dx).clamp(
                                      0.0,
                                      screenWidth - 56), // 56 is the FAB size
                                  (_fabPosition.dy + details.delta.dy)
                                      .clamp(0.0, screenHeight - 56),
                                );
                              });
                            },
                            child: Tooltip(
                              key: _tooltipKey,
                              message: 'Tap here to share the content',
                              child: FloatingActionButton(
                                onPressed: isLoading2 ? null : () => _share(),
                                backgroundColor: Colors.black,
                                child: isLoading2
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Icon(Icons.share,
                                        color: Colors.white),
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
  }

  Widget _voteButtons() {
    if (tabController != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 60.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                width: 1, color: Theme.of(context).colorScheme.onSurface),
            borderRadius: BorderRadius.circular(25),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          child: TabBar(
            onTap: (index) {
              if (index == 0) {
                currentVote = 'upvote';
              } else if (index == 1) {
                currentVote = 'downvote';
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
              fontSize: 11,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
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
            border: Border.all(
                width: 1, color: Theme.of(context).colorScheme.onSurface),
            borderRadius: BorderRadius.circular(25),
            color: Theme.of(context).colorScheme.onSurface,
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
              _buildCurvedTab('YEAR'),
            ],
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
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
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
