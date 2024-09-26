import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart'
as http; // import 'package:signal_app/sentiments_details.dart';
import 'package:signal_app/sentiment_page_view_coin.dart';
import 'package:signal_app/sentiment_page_view_coin_crypto.dart';

class SentimentPage extends StatefulWidget {
  const SentimentPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SentimentPageState createState() => _SentimentPageState();
}

class _SentimentPageState extends State<SentimentPage>
    with TickerProviderStateMixin {
  TabController? tabController;
  Color _indicatorColor = const Color(0xFFFF0000);
  bool tabTapped = false;
  String trendImg = 'images/lets-icons_up-white.png';
  String todayImg = 'images/wpf_today-black.png';
  String resultImg = 'images/carbon_result-new.png';
  OverlayEntry? _overlayEntry;
  List<dynamic> sentiments = [];
  final storage = const FlutterSecureStorage();
  bool loading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController!.addListener(_handleTabSelection);
    fetchSentiments();
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

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      switch (tabController!.index) {
        case 0:
          _indicatorColor = const Color(0xFFFF0000);
          trendImg = 'images/lets-icons_up-white.png';
          todayImg = 'images/wpf_today-black.png';
          resultImg = 'images/carbon_result-new.png';
          break;
        case 1:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          todayImg = 'images/wpf_today-black.png';
          resultImg = 'images/carbon_result-new.png';
          break;
        case 2:
          _indicatorColor = Colors.black;
          todayImg = 'images/wpf_today.png';
          resultImg = 'images/carbon_result-new.png';
          break;
        case 5:
          _indicatorColor = Colors.black;
          resultImg = 'images/carbon_result-new-white.png';
          todayImg = 'images/wpf_today-black.png';
          break;
        default:
          _indicatorColor = Colors.black;
          trendImg = 'images/lets-icons_up.png';
          todayImg = 'images/wpf_today-black.png';
          resultImg = 'images/carbon_result-new.png';
      }
    });
  }

  void _showFilterOverlay() {
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) =>
          SafeArea(
            child: GestureDetector(
              onTap: _removeOverlay, // Close the overlay on tap outside
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          // Makes container adjust height based on content
                          children: [
                            const Text(
                              'Filter',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontFamily: 'Inconsolata',
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width,
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 10,
                                      child: filterContents2(
                                          'Dates', ValueNotifier<bool>(false))),
                                  const Spacer(),
                                  Expanded(
                                      flex: 10,
                                      child: filterContents2(
                                          'Dates', ValueNotifier<bool>(false))),
                                ],
                              ),
                            ),
                            filterContents('Keywords',
                                ValueNotifier<bool>(false)),
                            filterContents(
                                'Select coins', ValueNotifier<bool>(false)),
                            filterContents(
                                'Exchanges - All', ValueNotifier<bool>(false)),
                            filterContents(
                                'Categories - All', ValueNotifier<bool>(false)),
                            filterContents('Sort by',
                                ValueNotifier<bool>(false)),
                            filterContents('Show only',
                                ValueNotifier<bool>(false)),
                            SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            Container(
                              width: double.infinity,
                              height: (60 / MediaQuery
                                  .of(context)
                                  .size
                                  .height) *
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30.0),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ButtonStyle(
                                  backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                      if (states.contains(
                                          WidgetState.pressed)) {
                                        return Colors.white;
                                      }
                                      return Colors.black;
                                    },
                                  ),
                                  foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                      if (states.contains(
                                          WidgetState.pressed)) {
                                        return Colors.black;
                                      }
                                      return Colors.white;
                                    },
                                  ),
                                  elevation: WidgetStateProperty.all<double>(
                                      4.0),
                                  shape: WidgetStateProperty.all<
                                      RoundedRectangleBorder>(
                                    const RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Proceed',
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
          ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> fetchSentiments() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      const url = 'https://script.teendev.dev/signal/api/sentiments';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          sentiments = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false; // Failed to load data
          errorMessage = 'Failed to load sentiments';
        });
        // Handle the error accordingly
        print('Failed to load sentiments');
      }
    } catch (e) {
      setState(() {
        loading = false;
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
    await fetchSentiments();
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
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, dynamic result) {
            if (!didPop) {
              if (_overlayEntry != null) {
                _removeOverlay();
              } else {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                }
              }
            }
          },
          child: Scaffold(
            body: Center(
              child: SizedBox(
                height: orientation == Orientation.portrait
                    ? MediaQuery
                    .of(context)
                    .size
                    .height
                    : MediaQuery
                    .of(context)
                    .size
                    .height * 1.5,
                child: SizedBox(
                  height: MediaQuery
                      .of(context)
                      .size
                      .height,
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
                              Image.asset('images/tabler_arrow-back.png',height:50,),
                            ),
                            SizedBox(
                                width:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.02),
                            const Expanded(
                              flex: 10,
                              child: Text(
                                'Sentiment',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Image.asset('images/SearchButton.png',height:50,),
                            InkWell(
                              onTap: () {
                                _showFilterOverlay();
                              },
                              child: Image.asset('images/FilterButton.png',height:50,),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.03,
                      ),
                      TabBar(
                        controller: tabController,
                        tabs: [
                          _buildTab('Crypto'),
                          _buildTab('Forex'),
                          _buildTab('Stocks'),
                        ],
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inconsolata',
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inconsolata',
                        ),
                        labelPadding: EdgeInsets.zero,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorColor: Colors.black,
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: [
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
                                RefreshIndicator(
                                  onRefresh: _refreshData,
                                  color: Colors.black,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: sentiments.length,
                                    itemBuilder: (context, index) {
                                      return forexCard(sentiments[index]);
                                    },
                                  ),
                                ),
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
                                RefreshIndicator(
                                  onRefresh: _refreshData,
                                  color: Colors.black,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: sentiments.length,
                                    itemBuilder: (context, index) {
                                      return forexCard(sentiments[index]);
                                    },
                                  ),
                                ),
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
                                RefreshIndicator(
                                  onRefresh: _refreshData,
                                  color: Colors.black,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount: sentiments.length,
                                    itemBuilder: (context, index) {
                                      return forexCard(sentiments[index]);
                                    },
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
          ),
        );
      },
    );
  }

  Widget _buildCurvedTab(String label, String img) {
    return Tab(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            if (img != '')
              Image.asset(
                img,
              ),
            SizedBox(width: MediaQuery
                .of(context)
                .size
                .width * 0.01),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cryptoCard() {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'Daily Movers',
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        Text(
          "Explore the biggest crypto movers in the market",
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontSize: 18,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        dailyMovers('images/logos_bitcoin.png', 'BTC', "Bitcoin", "20.66%",
            Colors.green.withOpacity(0.5), const Color(0xFF008000)),
        dailyMovers(
            'images/icon _Ethereum Cryptocurrency_.png',
            'ETH',
            "Ethereum",
            "-20.66%",
            Colors.red.withOpacity(0.5),
            const Color(0xFFFF0000)),
        dailyMovers('images/icon _Dogecoin Cryptocurrency_.png', 'Doge',
            "Dogecoin", "20.66%", Colors.transparent, const Color(0xFF008000)),
        dailyMovers('images/cryptocurrency-color_usdt.png', 'USDT', "USDT",
            "20.66%", Colors.transparent, const Color(0xFF008000)),
        dailyMovers('icon _TRON Cryptocurrency_.png', 'TRON', "TRON", "20.66%",
            Colors.transparent, const Color(0xFF008000)),
        dailyMovers('icon _Litecoin Cryptocurrency_.png', 'LITECOIN',
            "LITECOIN", "20.66%", Colors.transparent, const Color(0xFF008000)),
        Row(children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.white;
                    }
                    return Colors.black;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.black;
                    }
                    return Colors.white;
                  },
                ),
                elevation: MaterialStateProperty.all<double>(4.0),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ]),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        const Text(
          'By Market Cap',
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        Text(
          "The global market cap is 1.9T, a 0.78% increase over the last days",
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontSize: 18,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        Row(children: [
          const Expanded(
            flex: 10,
            child: Text(
              "Coin",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(width: MediaQuery
              .of(context)
              .size
              .width * 0.13),
          const Expanded(
            flex: 10,
            child: Text(
              "Price",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          const Expanded(
            flex: 10,
            child: Text(
              "MarketCap",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          const Expanded(
            flex: 10,
            child: Text(
              "Volume(24H)",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ]),
        marketCap(
            'images/logos_bitcoin.png',
            'BTC',
            "Bitcoin",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        marketCap(
            'images/icon _Ethereum Cryptocurrency_.png',
            'ETH',
            "Ethereum",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        marketCap(
            'images/token-branded_binance-smart-chain.png',
            'BNB',
            "Binance",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        marketCap(
            'images/token-branded_solana.png',
            'SOL',
            "Solana",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        Row(children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.white;
                    }
                    return Colors.black;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.black;
                    }
                    return Colors.white;
                  },
                ),
                elevation: MaterialStateProperty.all<double>(4.0),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ]),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        const Text(
          'Trending Crypto',
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        Text(
          "Coins accelerating among our users right now",
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontSize: 18,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        Row(children: [
          const Expanded(
            flex: 10,
            child: Text(
              "Coin",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(width: MediaQuery
              .of(context)
              .size
              .width * 0.13),
          const Expanded(
            flex: 10,
            child: Text(
              "Price",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          const Expanded(
            flex: 10,
            child: Text(
              "MarketCap",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const Spacer(),
          const Expanded(
            flex: 10,
            child: Text(
              "Volume(24H)",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ]),
        trendingCrypto(
            'images/logos_bitcoin.png',
            'BTC',
            "Bitcoin",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        trendingCrypto(
            'images/icon _Ethereum Cryptocurrency_.png',
            'ETH',
            "Ethereum",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        trendingCrypto(
            'images/token-branded_binance-smart-chain.png',
            'BNB',
            "Binance",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        trendingCrypto(
            'images/token-branded_solana.png',
            'SOL',
            "Solana",
            "53720.87",
            "1.07T",
            "18.35B",
            "43.4%",
            const Color(0xFF008000)),
        SizedBox(height: MediaQuery
            .of(context)
            .size
            .height * 0.02),
        Row(children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.white;
                    }
                    return Colors.black;
                  },
                ),
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.black;
                    }
                    return Colors.white;
                  },
                ),
                elevation: MaterialStateProperty.all<double>(4.0),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                  ),
                ),
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget dailyMovers(String img, String name, String description, String value,
      Color bgColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SentimentViewCoinCrypto(
                      key: UniqueKey(),
                      sentimentId: 1,
                      sentimentTitle: "BTC",
                      sentimentImg: ""),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(children: [
            Image.asset(
              img,
              height: 50,
            ),
            SizedBox(width: MediaQuery
                .of(context)
                .size
                .width * 0.02),
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: MediaQuery
                      .of(context)
                      .size
                      .height * 0.02),
                  Text(
                    description,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontSize: 15,
                color: textColor,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget marketCap(String img, String name, String description, String price,
      String marketCap, String volume, String percentage, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(children: [
        Image.asset(
          img,
          height: 30,
        ),
        SizedBox(width: MediaQuery
            .of(context)
            .size
            .width * 0.02),
        Expanded(
          flex: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),

              Text(
                description,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 10,
          child: Text(
            price,
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 10,
          child: Text(
            marketCap,
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 10,
          child: Column(
            children: [
              Text(
                volume,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                percentage,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget trendingCrypto(String img, String name, String description,
      String price,
      String marketCap, String volume, String percentage, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(children: [
        Image.asset(
          img,
          height: 30,
        ),
        SizedBox(width: MediaQuery
            .of(context)
            .size
            .width * 0.02),
        Expanded(
          flex: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),

              Text(
                description,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 10,
          child: Text(
            price,
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 10,
          child: Text(
            marketCap,
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 10,
          child: Column(
            children: [
              Text(
                volume,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                percentage,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 12,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget forexCard(Map<String, dynamic> sentiment) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    int upvotes = sentiment['upvotes'] is int
        ? sentiment['upvotes']
        : int.parse(sentiment['upvotes']);
    int downvotes = sentiment['downvotes'] is int
        ? sentiment['downvotes']
        : int.parse(sentiment['downvotes']);
    int totalVotes = upvotes + downvotes;
    double upvotePercentage = totalVotes > 0 ? (upvotes / totalVotes) * 100 : 0;
    double downvotePercentage =
    totalVotes > 0 ? (downvotes / totalVotes) * 100 : 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.01,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SentimentViewCoin(
                      key: UniqueKey(),
                      sentimentId: sentiment['id'],
                      sentimentTitle: sentiment['title'],
                      sentimentImg: sentiment['image']),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      sentiment['title'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Inconsolata',
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.05,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Image.asset(
                          'images/bi_people.png',
                          height: 15,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          '$totalVotes Votes',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: screenWidth * 0.03,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${upvotePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Inconsolata',
                        fontSize: 14,
                        color: Color(0xFF008000),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      '${downvotePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontFamily: 'Inconsolata',
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Expanded(
                    flex: upvotePercentage.round(), // Green bar flex
                    child: Container(
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF008000),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: downvotePercentage.round(), // Red bar flex
                    child: Container(
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget filterContents(String text, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, varName, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inconsolata',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        notifier.value = !notifier.value;
                      },
                      child: Image.asset(
                        varName
                            ? 'images/material-symbols_arrow-drop-down-upwards.png'
                            : 'images/material-symbols_arrow-drop-down.png',
                      ),
                    ),
                  ],
                ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget filterContents2(String text, ValueNotifier<bool> notifier) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, varName, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              SizedBox(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inconsolata',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        notifier.value = !notifier.value;
                      },
                      child: Image.asset(
                        varName
                            ? 'images/material-symbols_arrow-drop-down-upwards.png'
                            : 'images/material-symbols_arrow-drop-down.png',
                      ),
                    ),
                  ],
                ),
              ),
              if (varName)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Empty List',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inconsolata',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (varName)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Empty List',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inconsolata',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (varName)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Empty List',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inconsolata',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String name) {
    return Tab(
      child: Text(name),
    );
  }
}
