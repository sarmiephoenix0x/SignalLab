import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signal_app/trading_web_view.dart';
import 'package:signal_app/view_analysis.dart';

class SignalPage extends StatefulWidget {
  const SignalPage({super.key});

  @override
  _SignalPageState createState() => _SignalPageState();
}

class _SignalPageState extends State<SignalPage> with TickerProviderStateMixin {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late SharedPreferences prefs;
  late TabController homeTab;
  late TabController signalTab;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _signalScrollController = ScrollController();
  String? userName;
  String? userBalance;
  String? profileImg;
  int? totalSignal;
  bool loadingNews = false;
  String? errorMessage;
  bool _isRefreshing = false;

  List<dynamic> _signalsList1 = [];
  List<dynamic> _signalsList2 = [];
  List<dynamic> _signalsList3 = [];
  late Future<void> _signalsFuture1;
  late Future<void> _signalsFuture2;
  late Future<void> _signalsFuture3;
  bool _isLoadingMoreSignal = false;
  bool _isLoadingMoreSignal1 = false;
  bool _isLoadingMoreSignal2 = false;
  bool _isLoadingMoreSignal3 = false;
  bool _hasMoreSignal1 = true;
  bool _hasMoreSignal2 = true;
  bool _hasMoreSignal3 = true;
  int _currentSignalPage = 1;

  @override
  void initState() {
    super.initState();
    homeTab = TabController(length: 2, vsync: this);
    signalTab = TabController(length: 3, vsync: this);
    _initializePrefs();
    _signalsFuture1 = _fetchInitialSignals('crypto');
    _signalsFuture2 = _fetchInitialSignals('forex');
    _signalsFuture3 = _fetchInitialSignals('stocks');
    _signalScrollController.addListener(_onScroll);
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    totalSignal = await getTotalSignal();
    setState(() {});
  }

  Future<int?> getTotalSignal() async {
    final String? userJson = prefs.getString('user');
    if (userJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return userMap['total_signals'];
    }
    return null;
  }

  Future<void> _fetchInitialSignals(String type) async {
    _currentSignalPage = 1;
    try {
      final result = await fetchSignals(type, page: _currentSignalPage);
      setState(() {
        if (type == 'crypto') {
          _signalsList1 = result['signals'];
          _hasMoreSignal1 = result['pagination']['next_page_url'] != null;
        } else if (type == 'forex') {
          _signalsList2 = result['signals'];
          _hasMoreSignal2 = result['pagination']['next_page_url'] != null;
        } else if (type == 'stocks') {
          _signalsList3 = result['signals'];
          _hasMoreSignal3 = result['pagination']['next_page_url'] != null;
        }
      });
    } catch (e) {
      print('Error fetching signals for $type: $e');
    }
  }

  Future<void> _fetchMoreSignals(String type) async {
    if ((type == 'crypto' && _isLoadingMoreSignal1) ||
        (type == 'forex' && _isLoadingMoreSignal2) ||
        (type == 'stocks' && _isLoadingMoreSignal3)) return;

    setState(() {
      if (type == 'crypto') {
        _isLoadingMoreSignal1 = true;
      } else if (type == 'forex') {
        _isLoadingMoreSignal2 = true;
      } else if (type == 'stocks') {
        _isLoadingMoreSignal3 = true;
      }
    });

    try {
      _currentSignalPage++;
      final result = await fetchSignals(type, page: _currentSignalPage);
      setState(() {
        if (type == 'crypto') {
          _signalsList1.addAll(result['signals']);
          _hasMoreSignal1 = result['pagination']['next_page_url'] != null;
        } else if (type == 'forex') {
          _signalsList2.addAll(result['signals']);
          _hasMoreSignal2 = result['pagination']['next_page_url'] != null;
        } else if (type == 'stocks') {
          _signalsList3.addAll(result['signals']);
          _hasMoreSignal3 = result['pagination']['next_page_url'] != null;
        }
      });
    } catch (e) {
      print('Error fetching more signals for $type: $e');
    } finally {
      setState(() {
        if (type == 'crypto') {
          _isLoadingMoreSignal1 = false;
        } else if (type == 'forex') {
          _isLoadingMoreSignal2 = false;
        } else if (type == 'stocks') {
          _isLoadingMoreSignal3 = false;
        }
      });
    }
  }

  Future<Map<String, dynamic>> fetchSignals(String type, {int page = 1}) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse(
          'https://signal.payguru.com.ng/api/signal?type=$type&page=$page'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'signals': responseData['data'],
        'pagination': responseData['pagination'],
      };
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized access');
    } else if (response.statusCode == 404) {
      throw Exception('No signals available');
    } else if (response.statusCode == 422) {
      throw Exception('Validation error');
    } else {
      throw Exception('Failed to load signals');
    }
  }

  void _onScroll() {
    if (_signalScrollController.position.pixels >=
            _signalScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreSignal) {
      // Load more signals dynamically based on the active tab
      if (signalTab.index == 0) {
        _fetchMoreSignals('crypto');
      } else if (signalTab.index == 1) {
        _fetchMoreSignals('forex');
      } else if (signalTab.index == 2) {
        _fetchMoreSignals('stocks');
      }
    }
  }

  @override
  void dispose() {
    homeTab.dispose();
    signalTab.dispose();
    _scrollController.dispose();
    _signalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: OrientationBuilder(
        builder: (context, orientation) {
          return Scaffold(
            body: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Text(
                        'Signals',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 22.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(
                          'Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                TabBar(
                  controller: signalTab,
                  tabs: [
                    _buildTab('Crypto'),
                    _buildTab('Forex'),
                    _buildTab('Stocks'),
                  ],
                  labelColor: Theme.of(context).colorScheme.onSurface,
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
                  indicatorColor: Theme.of(context).colorScheme.onSurface,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Expanded(
                  child: TabBarView(
                    controller: signalTab,
                    children: [
                      _buildSignalTabView(_signalsFuture1, _signalsList1),
                      _buildSignalTabView(_signalsFuture2, _signalsList2),
                      _buildSignalTabView(_signalsFuture3, _signalsList3),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignalTabView(
      Future<void> signalsFuture, List<dynamic> signalsList) {
    return FutureBuilder<void>(
      future: signalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onSurface),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('An error occurred: ${snapshot.error}'),
          );
        }

        return ListView.builder(
          controller: _signalScrollController,
          itemCount:
              signalsList.length + 1, // Include space for loading indicator
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header or statistics section
              return Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10.0, bottom: 5),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[900]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildStatRow(
                          'Trades last 7 days: ----', 'Win rate: ----'),
                      buildStatRow(
                          'Trades last 14 days: ----', 'Win rate: ----'),
                      buildStatRow(
                          'Trades last 30 days: ----', 'Win rate: ----'),
                    ],
                  ),
                ),
              );
            } else if (index == signalsList.length) {
              // Show loading indicator at the bottom
              return _isLoadingMoreSignal
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    )
                  : const SizedBox.shrink(); // No more signals to load
            }

            // Render the signal item
            final signal = signalsList[index - 1];
            Map<String, dynamic> targetsMap = jsonDecode(signal['targets']);

            return signals(
              id: signal['id'],
              type: signal['type'],
              authorId: signal['author_id'],
              authorName: signal['author_name'],
              img: signal['coin_image'],
              name: signal['coin'],
              entryPrice: signal['entry_price'],
              stopLoss: signal['stop_loss'],
              currentPrice: signal['current_price'],
              targets: targetsMap,
              createdAt: signal['created_at'],
              insight: signal['insight'],
              trend: signal['trend'],
              pair: signal['pair'],
              analysisNotifier: ValueNotifier<bool>(false),
              currentPriceNotifier: ValueNotifier<bool>(false),
            );
          },
        );
      },
    );
  }

  Widget _buildTab(String name) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(name),
      ),
    );
  }

  Widget buildStatRow(String leftText, String rightText) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Text(
            leftText,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 4,
          child: Text(
            rightText,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget signals({
    required int id,
    required String type,
    required String authorId,
    required String authorName,
    required String img,
    required String name,
    required String entryPrice,
    required String stopLoss,
    required String currentPrice,
    required Map<String, dynamic> targets,
    required String createdAt,
    required String? insight,
    required String? trend,
    required String? pair,
    required ValueNotifier<bool> currentPriceNotifier,
    required ValueNotifier<bool>
        analysisNotifier, // Add a new notifier for analysis dropdown
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<bool>(
      valueListenable: currentPriceNotifier,
      builder: (context, currentPriceExpanded, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: analysisNotifier,
          builder: (context, analysisExpanded, _) {
            return Padding(
              padding: const EdgeInsets.only(
                  left: 20.0, right: 20.0, top: 5.0, bottom: 5.0),
              child: Container(
                padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Opened',
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 5,
                            child: Text(
                              createdAt,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: Container(
                              width: (50 / MediaQuery.of(context).size.width) *
                                  MediaQuery.of(context).size.width,
                              height:
                                  (50 / MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                              color: Colors.grey,
                              child: Image.network(
                                img,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.white : Colors.black,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Text(
                              (trend ?? 'No Trend'),
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02),
                          SizedBox(
                            height: 35,
                            child: VerticalDivider(
                              color: isDarkMode ? Colors.white : Colors.black,
                              thickness: 2.0,
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02),
                          Expanded(
                            flex: 5,
                            child: Text(
                              name + (pair ?? ''),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // const Spacer(),
                          // Expanded(
                          //   flex: 5,
                          //   child: Container(
                          //     decoration: BoxDecoration(
                          //       color: Theme.of(context).colorScheme.onSurface,
                          //       borderRadius: BorderRadius.circular(10),
                          //     ),
                          //     padding: const EdgeInsets.symmetric(
                          //         horizontal: 12, vertical: 6),
                          //     child: Row(
                          //       children: [
                          //         const Expanded(
                          //           flex: 5,
                          //           child: Text(
                          //             'In progress',
                          //             overflow: TextOverflow.ellipsis,
                          //             style: TextStyle(
                          //               fontSize: 15,
                          //               fontFamily: 'Inconsolata',
                          //               color: Theme.of(context).colorScheme.onSurface,
                          //             ),
                          //           ),
                          //         ),
                          //         Image.asset(
                          //           'images/carbon_in-progress.png',
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Entry price',
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: Text(
                              entryPrice,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.01,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'Stop Loss',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            child: Text(
                              stopLoss,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 13,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode
                                  ? Colors.grey.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 10,
                                  child: Text(
                                    'Current Price',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inconsolata',
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    currentPrice,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inconsolata',
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                // const Spacer(),
                                // const Expanded(
                                //   flex: 4,
                                //   child: Text(
                                //     '-35.5%',
                                //     overflow: TextOverflow.ellipsis,
                                //     style: TextStyle(
                                //       fontSize: 15,
                                //       fontWeight: FontWeight.bold,
                                //       fontFamily: 'Inconsolata',
                                //       color: Color(0xFFFF0000),
                                //     ),
                                //   ),
                                // ),
                                GestureDetector(
                                  onTap: () {
                                    currentPriceNotifier.value =
                                        !currentPriceNotifier.value;
                                  },
                                  child: Image.asset(
                                    currentPriceExpanded
                                        ? 'images/material-symbols_arrow-drop-down-upwards.png'
                                        : 'images/material-symbols_arrow-drop-down.png',
                                  ),
                                ),
                              ],
                            ),
                            if (currentPriceExpanded)
                              ...targets.entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDarkMode
                                              ? Colors.grey.withOpacity(0.2)
                                              : Colors.grey.withOpacity(0.5),
                                          spreadRadius: 3,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            entry.key,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 15,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            entry.value.toString(),
                                            textAlign: TextAlign.end,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontSize: 15,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 10,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewAnalysis(
                                      key: UniqueKey(),
                                      signalId: id,
                                      authorId: authorId,
                                      authorName: authorName,
                                      coinName: name,
                                      coinImg: img,
                                      pair: pair,
                                      trend: trend,
                                      type: type,
                                      currentPrice: currentPrice,
                                      insight: insight,
                                      createdAt: createdAt,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode
                                          ? Colors.grey.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.5),
                                      spreadRadius: 3,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 6),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'View Analysis',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inconsolata',
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                        // GestureDetector(
                                        //   onTap: () {
                                        //     analysisNotifier.value =
                                        //         !analysisNotifier.value;
                                        //   },
                                        //   child: Image.asset(
                                        //     analysisExpanded
                                        //         ? 'images/material-symbols_arrow-drop-down-upwards.png'
                                        //         : 'images/material-symbols_arrow-drop-down.png',
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    // if (analysisExpanded && insight != null)
                                    //   Padding(
                                    //     padding: const EdgeInsets.symmetric(
                                    //         horizontal: 20.0, vertical: 10.0),
                                    //     child: Text(
                                    //       insight,
                                    //       style: TextStyle(
                                    //         fontSize: 15,
                                    //         fontFamily: 'Inconsolata',
                                    //         color: isDarkMode
                                    //             ? Colors.white
                                    //             : Colors.black,
                                    //       ),
                                    //     ),
                                    //   ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 10,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TradingViewPage(key: UniqueKey()),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDarkMode
                                          ? Colors.grey.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.5),
                                      spreadRadius: 3,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'View Chart',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inconsolata',
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.02,
                                    ),
                                    Image.asset(
                                      'images/material-symbols_pie-chart.png',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
