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
          _indicatorColor = Colors.black;
          trendImg = 'images/lets-icons_up.png';
      }
    });
  }

  Future<void> fetchEvents() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });
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
        setState(() {
          events = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          errorMessage = 'Failed to load events'; // Failed to load data
        });
        // Handle the error accordingly
        print('Failed to load events');
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

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: Center(
            child: SizedBox(
              height: orientation == Orientation.portrait
                  ? MediaQuery.of(context).size.height
                  : MediaQuery.of(context).size.height * 1.5,
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Image.asset('images/tabler_arrow-back.png'),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02),
                          const Text(
                            'Events',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          Image.asset('images/PlusButton.png'),
                          Image.asset('images/SearchButton.png'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.03,
                    ),
                    _latestInfoTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
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
          unselectedLabelColor: Colors.black,
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
              ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
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
    final screenHeight = MediaQuery.of(context).size.height;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully ${type == 'upvote' ? 'Upvoted' : 'Downvoted'}'),
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
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Container(
                      width: (48 / MediaQuery.of(context).size.width) *
                          MediaQuery.of(context).size.width,
                      height: (48 / MediaQuery.of(context).size.height) *
                          MediaQuery.of(context).size.height,
                      color: Colors.grey,
                      child: Image.network(
                        event['image'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1, // Limits title to one line
                          style: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.black,
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
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Text(
                          event['sub_text'],
                          maxLines: 2, // Limits sub_text to two lines
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inconsolata',
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Upvotes: ${event['upvotes']} | Downvotes: ${event['downvotes']}',
                              style: const TextStyle(
                                fontFamily: 'Inconsolata',
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Stack(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width *
                                  0.2 *
                                  upvotePercentage,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0000FF),
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.2,
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
                    height: MediaQuery.of(context).size.height * 0.15,
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
}
