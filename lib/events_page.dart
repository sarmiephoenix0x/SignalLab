import 'package:flutter/material.dart';
import 'package:signal_app/events_details.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class EventsPage extends StatefulWidget {
  const EventsPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with TickerProviderStateMixin {
  TabController? tabController;
  Color _indicatorColor = const Color(0xFFFF0000);
  bool tabTapped = false;
  String trendImg = 'images/lets-icons_up-white.png';
  List<dynamic> events = [];
  final storage = const FlutterSecureStorage();
  bool loading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  String? errorMessage;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 8, vsync: this);
    tabController!.addListener(_handleTabSelection);
    fetchEvents();
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
          break;
        case 1:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          break;
        case 2:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          break;
        default:
          _indicatorColor = Theme.of(context).colorScheme.onSurface;
          trendImg = 'images/lets-icons_up.png';
      }
    });
  }

  Future<void> fetchEvents() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }
    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      const url = 'https://script.teendev.dev/signal/api/events';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            events = json.decode(response.body);
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false;
            errorMessage = 'Failed to load events'; // Failed to load data
          });
        }
        // Handle the error accordingly
        print('Failed to load events');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage =
          'Failed to load data. Please check your network connection.';
        });
      }
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
        Future.delayed(Duration(seconds: 15), () {
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
    await fetchEvents();
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

  void _showFilterOverlay() {
    final overlay = Overlay.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
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
                            Text(
                              'Add Event',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontFamily: 'Inconsolata',
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.05),
                            textBoxEventInput('Event title'),
                            textBoxEventInput(
                                'Date i.e. time period when the event will occur'),
                            dropDownEventInput(
                                'Select coin', ValueNotifier<bool>(false)),
                            dropDownEventInput(
                                'Event category', ValueNotifier<bool>(false)),
                            bigTextBoxEventInput('Description'),
                            textBoxEventInput('Source url'),
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
                                  'Submit',
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
                    SizedBox(height: MediaQuery
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
                            child: Image.asset(
                              'images/tabler_arrow-back.png', height: 50,),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.02),
                          Text(
                            'Events',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                              onTap: () {
                                _showFilterOverlay();
                              },
                              child: Image.asset('images/PlusButton.png',height:50,)),
                          Image.asset('images/SearchButton.png',height:50,),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * 0.03,
                    ),
                    _latestInfoTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Colors.black,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          if (loading)
                            Center(
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.onSurface),
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
                              )
                            else
                              RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(events[index]);
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
        );
      },
    );
  }

  Widget _latestInfoTabBar() {
    if (tabController != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TabBar(
          indicator: BoxDecoration(
            color: _indicatorColor,
            borderRadius: BorderRadius.circular(10),
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
            _buildCurvedTab('Trending', trendImg),
            _buildCurvedTab('Hot', 'images/noto_fire.png'),
            _buildCurvedTab('Significant', 'images/noto_crown.png'),
            _buildCurvedTab('Top 100 coins', ''),
            _buildCurvedTab('Top 300 coins', ''),
            _buildCurvedTab('Top 500 coins', ''),
            _buildCurvedTab('Major categories', ''),
            _buildCurvedTab('Next 10 days', ''),
          ],
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
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
                height:16,
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

  Widget cryptoCard(Map<String, dynamic> event) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    int upvotes = event['upvotes'] is int
        ? event['upvotes']
        : int.parse(event['upvotes']);
    int downvotes = event['downvotes'] is int
        ? event['downvotes']
        : int.parse(event['downvotes']);
    int totalVotes = upvotes + downvotes;
    double upvotePercentage = totalVotes > 0 ? upvotes / totalVotes : 0.0;

    Future<void> vote(String type) async {
      final String eventId = event['id'].toString(); // Ensure ID is a string
      final String? accessToken = await storage.read(key: 'accessToken');

      final response = await http.post(
        Uri.parse('https://script.teendev.dev/signal/api/vote'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': type,
          'group': 'event', // Specify the group if needed
          'id': eventId,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update event counts based on the type of vote
        if (type == 'upvote') {
          event['upvotes'] = (int.parse(event['upvotes']) + 1).toString();
        } else {
          event['downvotes'] = (int.parse(event['downvotes']) + 1).toString();
        }

        // Recalculate the vote percentage after updating votes
        int updatedUpvotes = int.parse(event['upvotes']);
        int updatedDownvotes = int.parse(event['downvotes']);
        int updatedTotalVotes = updatedUpvotes + updatedDownvotes;
        upvotePercentage =
        updatedTotalVotes > 0 ? updatedUpvotes / updatedTotalVotes : 0.0;

        // Show success message
        _showCustomSnackBar(
          context,
          'Successfully ${type == 'upvote' ? 'Upvoted' : 'Downvoted'}',
          isError: false,
        );

        setState(() {}); // Update the UI
      } else {
        _showCustomSnackBar(
          context,
          responseBody['message'] ?? 'An error occurred',
          isError: true,
        );
      }
    }
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EventsDetails(key: UniqueKey(), eventId: event['id']),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Container(
                      width: (48 / MediaQuery
                          .of(context)
                          .size
                          .width) *
                          MediaQuery
                              .of(context)
                              .size
                              .width,
                      height: (48 / MediaQuery
                          .of(context)
                          .size
                          .height) *
                          MediaQuery
                              .of(context)
                              .size
                              .height,
                      color: Colors.grey,
                      child: Image.network(
                        event['image'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1, // Limits title to one line
                          style: TextStyle(
                            fontFamily: 'Inconsolata',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          event['created_at'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Inconsolata',
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery
                              .of(context)
                              .size
                              .height * 0.02,
                        ),
                        Text(
                          event['sub_text'],
                          maxLines: 2, // Limits sub_text to two lines
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Upvotes: ${event['upvotes']} | Downvotes: ${event['downvotes']}',
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Stack(
                          children: [
                            Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width *
                                  0.2 *
                                  upvotePercentage,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0000FF),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            Container(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.2,
                              height: 5,
                              decoration: BoxDecoration(
                                border:
                                Border.all(width: 0.5, color: Colors.black),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.15,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => vote('upvote'),
                          child: Image.asset(
                            'images/Thumbs-up.png',
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => vote('downvote'),
                          child: Image.asset(
                            'images/Thumbs-down.png',
                          ),
                        ),
                      ],
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

  Widget dropDownEventInput(String text, ValueNotifier<bool> notifier) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, varName, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
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
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: Row(
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: Row(
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: Row(
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
                                color: Theme.of(context).colorScheme.onSurface,
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

  Widget textBoxEventInput(String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            TextFormField(
              style: const TextStyle(
                fontSize: 16.0,
              ),
              decoration: InputDecoration(
                labelText: text,
                labelStyle: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inconsolata',
                  color: Colors.grey,
                ),
                contentPadding:
                const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    top: 0),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                border: InputBorder.none,
              ),
              cursorColor: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget bigTextBoxEventInput(String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        height: (160 / MediaQuery
            .of(context)
            .size
            .height) *
            MediaQuery
                .of(context)
                .size
                .height,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            TextFormField(
              maxLength: 140,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 16.0,
              ),
              decoration: InputDecoration(
                labelText: text,
                labelStyle: const TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inconsolata',
                  color: Colors.grey,
                ),
                contentPadding:
                const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    top: 0),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                border: InputBorder.none,
              ),
              cursorColor: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

}
