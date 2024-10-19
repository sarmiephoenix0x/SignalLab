import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class SentimentViewCoinCrypto extends StatefulWidget {
  final int sentimentId;
  final String sentimentTitle;
  final String sentimentImg;

  const SentimentViewCoinCrypto(
      {super.key,
      required this.sentimentId,
      required this.sentimentTitle,
      required this.sentimentImg});

  @override
  // ignore: library_private_types_in_public_api
  _SentimentViewCoinCryptoState createState() =>
      _SentimentViewCoinCryptoState();
}

class _SentimentViewCoinCryptoState extends State<SentimentViewCoinCrypto>
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
  String overviewImg = 'images/overview_tab_img.png';
  String chartImg = 'images/chart_tab_img_faded.png';
  String analysisImg = 'images/analysis_tab_img_faded.png';
  String newsImg = 'images/news_tab_img_faded.png';
  String financialsImg = 'images/financials_tab_img_faded.png';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 5, vsync: this);
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
          overviewImg = 'images/overview_tab_img.png';
          chartImg = 'images/chart_tab_img_faded.png';
          analysisImg = 'images/analysis_tab_img_faded.png';
          newsImg = 'images/news_tab_img_faded.png';
          financialsImg = 'images/financials_tab_img_faded.png';
          break;
        case 1:
          overviewImg = 'images/overview_tab_img_faded.png';
          chartImg = 'images/chart_tab_img_faded.png';
          analysisImg = 'images/analysis_tab_img_faded.png';
          newsImg = 'images/news_tab_img_faded.png';
          financialsImg = 'images/financials_tab_img_faded.png';
          break;
        case 2:
          overviewImg = 'images/overview_tab_img_faded.png';
          chartImg = 'images/chart_tab_img_faded.png';
          analysisImg = 'images/analysis_tab_img.png';
          newsImg = 'images/news_tab_img_faded.png';
          financialsImg = 'images/financials_tab_img_faded.png';
          break;
        case 3:
          overviewImg = 'images/overview_tab_img_faded.png';
          chartImg = 'images/chart_tab_img_faded.png';
          analysisImg = 'images/analysis_tab_img_faded.png';
          newsImg = 'images/news_tab_img_faded.png';
          financialsImg = 'images/financials_tab_img_faded.png';
          break;
        case 4:
          overviewImg = 'images/overview_tab_img_faded.png';
          chartImg = 'images/chart_tab_img_faded.png';
          analysisImg = 'images/analysis_tab_img_faded.png';
          newsImg = 'images/news_tab_img_faded.png';
          financialsImg = 'images/financials_tab_img.png';
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
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1),
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
                                  height: MediaQuery.of(context).size.height *
                                      0.05),
                              if (loading)
                                const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.black),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0),
                                      child: Row(
                                        children: [
                                          Image.asset(
                                            "images/logos_bitcoin.png",
                                            height: 50,
                                          ),
                                          SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.02),
                                          Column(children: [
                                            Row(
                                              children: [
                                                Text(
                                                  "${widget.sentimentTitle}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  ". Bitcoin",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 22,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ]),
                                          const Spacer(),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    _tabBar(),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    // WebView content
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.7, // Specify the height
                                      child: WebViewWidget(
                                          controller: _controller),
                                    ),
                                  ],
                                ),
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

  Widget _tabBar() {
    if (tabController != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: TabBar(
          indicator: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(0),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding:
              const EdgeInsets.only(left: 2.1, right: 2.1, bottom: 6.6, top: 5),
          dividerHeight: 0,
          tabAlignment: TabAlignment.start,
          controller: tabController!,
          isScrollable: true,
          splashBorderRadius: BorderRadius.circular(10),
          tabs: [
            _buildCurvedTab('Overview', overviewImg),
            _buildCurvedTab('Chart', chartImg),
            _buildCurvedTab('Analysis', analysisImg),
            _buildCurvedTab('News', newsImg),
            _buildCurvedTab('Financials', financialsImg),
          ],
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black.withOpacity(0.5),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Inconsolata',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Inconsolata',
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildCurvedTab(String label, String img) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            if (img != '')
              Image.asset(
                img,
                height: 24,
              ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inconsolata',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
