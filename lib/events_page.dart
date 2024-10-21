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
  String trendImg = 'images/lets-icons_up.png';
  List<dynamic> events = [];
  final storage = const FlutterSecureStorage();
  bool loading = true;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  String? errorMessage;
  OverlayEntry? _overlayEntry;
  int currentPage = 1;
  bool isLastPage = false;
  bool isLoadingMore = false;
  TabController? airdropTab;
  late Future<void> _airdropsFuture1;
  late Future<void> _airdropsFuture2;
  late Future<void> _airdropsFuture3;
  List<dynamic> airdrops = [];
  List<dynamic> _airdropsList = [];
  bool _isLoadingAirdrops = true;

  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  List searchResults = [];
  bool searchLoading = false;

  @override
  void initState() {
    super.initState();
    _airdropsFuture1 = _fetchInitialAirdrops('airdrop');
    // _airdropsFuture1 = _fetchInitialAirdrops('crypto');
    // _airdropsFuture2 = _fetchInitialAirdrops('forex');
    // _airdropsFuture3 = _fetchInitialAirdrops('stocks');
    airdropTab = TabController(length: 3, vsync: this);
    tabController = TabController(length: 9, vsync: this);
    tabController!.addListener(_handleTabSelection);
    fetchEvents();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && !isLastPage) {
          fetchEvents(
              loadMore: true); // Load more when reaching near the bottom
        }
      }
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

  Future<void> _fetchInitialAirdrops(String type) async {
    if (mounted) {
      setState(() {
        _isLoadingAirdrops = true; // Set loading to true before fetching
      });
    }

    try {
      _airdropsList = await fetchAirdrops(type);
    } catch (e) {
      print('Error fetching airdrops: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAirdrops = false; // Set loading to false after fetching
        });
      }
    }
  }

  Future<List<dynamic>> fetchAirdrops(String type) async {
    final String? accessToken = await storage.read(key: 'accessToken');
    final response = await http.get(
      Uri.parse('https://signal.payguru.com.ng/api/event/sort?category=$type'),
      // Uri.parse('https://signal.payguru.com.ng/api/event/sort?coin=$type'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final dynamic responseData =
          json.decode(response.body); // Parse as dynamic

      // If the response is a list directly
      if (responseData is List) {
        return responseData; // Return the list directly
      } else if (responseData is Map && responseData.containsKey('data')) {
        return responseData['data']; // Handle if it's a map with a 'data' key
      } else {
        throw Exception('Unexpected response structure');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized access');
    } else if (response.statusCode == 404) {
      throw Exception('No signals available');
    } else if (response.statusCode == 422) {
      throw Exception(
          'Validation error: ${json.decode(response.body)['message']}');
    } else {
      throw Exception('Failed to load signals: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    tabController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      switch (tabController!.index) {
        case 0:
          _indicatorColor = const Color(0xFFFF0000);
          trendImg = 'images/lets-icons_up.png';
          break;
        case 1:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up-white.png';
          break;
        case 2:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          break;
        case 3:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          break;
        default:
          _indicatorColor = Theme.of(context).colorScheme.onSurface;
          trendImg = 'images/lets-icons_up.png';
      }
    });
  }

  Future<void> fetchEvents({bool loadMore = false}) async {
    // Prevent multiple loadMore calls or fetching if it's the last page
    if (loadMore && (isLoadingMore || isLastPage)) return;

    // Update UI loading state
    if (!loadMore) {
      if (mounted) {
        setState(() {
          loading = true;
          errorMessage = null;
        });
      }
    }

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      final url =
          'https://signal.payguru.com.ng/api/events?page=$currentPage'; // Add pagination parameter

      // Make API call
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      // Handle successful response
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            json.decode(response.body); // Parse response

        if (responseData.containsKey('data') &&
            responseData['data'].isNotEmpty) {
          final List<dynamic> eventsData =
              responseData['data']; // Extract 'data' list
          final pagination =
              responseData['pagination']; // Extract pagination details

          if (mounted) {
            setState(() {
              // Append or set events data
              if (loadMore) {
                events.addAll(eventsData); // Append new data
              } else {
                events = eventsData; // Set initial load
              }

              // Update pagination and loading state
              isLastPage =
                  pagination['next_page_url'] == null || eventsData.isEmpty;
              if (!isLastPage)
                currentPage++; // Increment page only if there's a next page
              loading = false;
              isLoadingMore = false;
            });
          }
        } else {
          // Handle unexpected cases where no events are found but no error message is present
          if (mounted) {
            setState(() {
              loading = false;
              isLoadingMore = false;
              errorMessage = 'No more events available';
            });
          }
        }
      } else if (response.statusCode == 404) {
        // Handle 404 status (no more events available)
        if (mounted) {
          setState(() {
            isLastPage = true; // No more data to load
            loading = false;
            isLoadingMore = false;
          });
        }
      } else {
        // Handle non-200 response status codes
        final String errorResponse =
            response.body; // Capture response error message
        if (mounted) {
          setState(() {
            loading = false;
            isLoadingMore = false;
            errorMessage =
                'Error: $errorResponse'; // Display detailed error response
          });
        }
      }
    } catch (e) {
      // Handle network or JSON parsing errors
      if (mounted) {
        setState(() {
          loading = false;
          isLoadingMore = false;
          errorMessage =
              'Exception caught: ${e.toString()}'; // Provide detailed exception
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
      builder: (context) => SafeArea(
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
                        color: isDarkMode
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.5),
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
                            height: MediaQuery.of(context).size.height * 0.05),
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
                            height: MediaQuery.of(context).size.height * 0.05),
                        Container(
                          width: double.infinity,
                          height: (60 / MediaQuery.of(context).size.height) *
                              MediaQuery.of(context).size.height,
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return Colors.white;
                                  }
                                  return Colors.black;
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return Colors.black;
                                  }
                                  return Colors.white;
                                },
                              ),
                              elevation: WidgetStateProperty.all<double>(4.0),
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

  Future<void> _performSearch(String query) async {
    setState(() {
      searchLoading = true;
    });
    final String? accessToken = await storage.read(key: 'accessToken');
    final url = 'https://signal.payguru.com.ng/api/search?query=$query';
    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    // Perform GET request
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      setState(() {
        searchResults = jsonDecode(response.body);
        searchLoading = false;
      });
    } else if (response.statusCode == 404) {
      setState(() {
        searchResults = [];
        searchLoading = false;
      });
      _showCustomSnackBar(
        context,
        'No results found for the query.',
        isError: true,
      );
    } else if (response.statusCode == 422 || response.statusCode == 401) {
      setState(() {
        searchResults = [];
        searchLoading = false;
      });
      final errorMessage = jsonDecode(response.body)['message'];
      _showCustomSnackBar(
        context,
        errorMessage,
        isError: true,
      );
    }
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
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(
                                  color: Colors
                                      .white, // White text for search input
                                  fontSize:
                                      18, // Adjust size for better visibility
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: const TextStyle(
                                    color:
                                        Colors.white54, // Light gray hint text
                                    fontSize:
                                        16, // Slightly smaller hint size for contrast
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .onSurface, // Slight translucent effect for input background
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide
                                        .none, // No border for a clean look
                                  ),
                                  // Add a search icon with onPressed event
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search,
                                        color: Colors.white),
                                    onPressed: () {
                                      // Trigger search only when the search icon is tapped
                                      _performSearch(_searchController.text);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface), // White close icon
                              onPressed: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
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
                                child: Image.asset(
                                  'images/PlusButton.png',
                                  height: 50,
                                )),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isSearching = true;
                                });
                              },
                              child: Image.asset(
                                'images/SearchButton.png',
                                height: 50,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.03,
                    ),
                    if (_isSearching) ...[
                      if (searchLoading) ...[
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onSurface,
                            ), // Use primary color
                            strokeWidth: 4.0,
                          ),
                        )
                      ] else ...[
                        if (searchResults.isNotEmpty) ...[
                          ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(
                                  searchResults[index]['title'] ?? 'No Title',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  searchResults[index]['description'] ??
                                      'No Description',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              );
                            },
                          )
                        ] else ...[
                          Center(
                            child: Text(
                              'No results to display',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ]
                      ]
                    ] else ...[
                      _latestInfoTabBar(),
                      // if (tabController!.index == 0)
                      //   TabBar(
                      //     controller:
                      //         airdropTab, // Ensure airdropTab is initialized
                      //     tabs: [
                      //       _buildTab('Crypto'),
                      //       _buildTab('Forex'),
                      //       _buildTab('Stocks'),
                      //     ],
                      //     labelColor: Theme.of(context).colorScheme.onSurface,
                      //     unselectedLabelColor: Colors.grey,
                      //     labelStyle: const TextStyle(
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.bold,
                      //       fontFamily: 'Inconsolata',
                      //     ),
                      //     unselectedLabelStyle: const TextStyle(
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.bold,
                      //       fontFamily: 'Inconsolata',
                      //     ),
                      //     labelPadding: EdgeInsets.zero,
                      //     indicatorSize: TabBarIndicatorSize.tab,
                      //     indicatorColor:
                      //         Theme.of(context).colorScheme.onSurface,
                      //   ),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: [
                            FutureBuilder<void>(
                              future: _airdropsFuture1,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                          onPressed: () {
                                            setState(() {
                                              _airdropsFuture1 =
                                                  _fetchInitialAirdrops(
                                                      'airdrop');
                                            });
                                          },
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
                                  );
                                }

                                return RefreshIndicator(
                                  onRefresh: () =>
                                      _fetchInitialAirdrops('airdrop'),
                                  child: _isLoadingAirdrops // Check if loading
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        )
                                      : _airdropsList
                                              .isEmpty // Check if the list is empty
                                          ? Center(
                                              child: Text(
                                                'No airdrops available',
                                                style: TextStyle(
                                                  fontFamily: 'Inconsolata',
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            )
                                          : ListView.builder(
                                              itemCount: _airdropsList
                                                  .length, // Use the length of the list
                                              itemBuilder: (context, index) {
                                                final signal = _airdropsList[
                                                    index]; // Access the list safely
                                                return cryptoCard(
                                                    signal); // Use the correct variable for the signal
                                              },
                                            ),
                                );
                              },
                            ),
                            // Expanded(
                            //   child: TabBarView(
                            //     controller: airdropTab,
                            //     children: [
                            //       FutureBuilder<void>(
                            //         future: _airdropsFuture1,
                            //         builder: (context, snapshot) {
                            //           if (snapshot.connectionState ==
                            //               ConnectionState.waiting) {
                            //             return Center(
                            //               child: CircularProgressIndicator(
                            //                 color: Theme.of(context)
                            //                     .colorScheme
                            //                     .onSurface,
                            //               ),
                            //             );
                            //           } else if (snapshot.hasError) {
                            //             return Center(
                            //               child: Column(
                            //                 mainAxisAlignment:
                            //                     MainAxisAlignment.center,
                            //                 children: [
                            //                   const Text(
                            //                     'An unexpected error occurred',
                            //                     textAlign: TextAlign.center,
                            //                     style: TextStyle(
                            //                       fontFamily: 'Inconsolata',
                            //                       color: Colors.red,
                            //                     ),
                            //                   ),
                            //                   const SizedBox(height: 16),
                            //                   ElevatedButton(
                            //                     onPressed: () {
                            //                       setState(() {
                            //                         _airdropsFuture1 =
                            //                             _fetchInitialAirdrops(
                            //                                 'crypto');
                            //                       });
                            //                     },
                            //                     child: Text(
                            //                       'Retry',
                            //                       style: TextStyle(
                            //                         fontFamily: 'Inconsolata',
                            //                         fontWeight: FontWeight.bold,
                            //                         fontSize: 18,
                            //                         color: Theme.of(context)
                            //                             .colorScheme
                            //                             .onSurface,
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             );
                            //           }

                            //           return RefreshIndicator(
                            //             onRefresh: () =>
                            //                 _fetchInitialAirdrops('crypto'),
                            //             child:
                            //                 _isLoadingAirdrops // Check if loading
                            //                     ? Center(
                            //                         child:
                            //                             CircularProgressIndicator(
                            //                           color: Theme.of(context)
                            //                               .colorScheme
                            //                               .onSurface,
                            //                         ),
                            //                       )
                            //                     : _airdropsList
                            //                             .isEmpty // Check if the list is empty
                            //                         ? Center(
                            //                             child: Text(
                            //                               'No airdrops available',
                            //                               style: TextStyle(
                            //                                 fontFamily:
                            //                                     'Inconsolata',
                            //                                 color: Theme.of(
                            //                                         context)
                            //                                     .colorScheme
                            //                                     .onSurface,
                            //                               ),
                            //                             ),
                            //                           )
                            //                         : ListView.builder(
                            //                             itemCount: _airdropsList
                            //                                 .length, // Use the length of the list
                            //                             itemBuilder:
                            //                                 (context, index) {
                            //                               final signal =
                            //                                   _airdropsList[
                            //                                       index]; // Access the list safely
                            //                               return cryptoCard(
                            //                                   signal); // Use the correct variable for the signal
                            //                             },
                            //                           ),
                            //           );
                            //         },
                            //       ),
                            //       FutureBuilder<void>(
                            //         future: _airdropsFuture2,
                            //         builder: (context, snapshot) {
                            //           if (snapshot.connectionState ==
                            //               ConnectionState.waiting) {
                            //             return Center(
                            //               child: CircularProgressIndicator(
                            //                 color: Theme.of(context)
                            //                     .colorScheme
                            //                     .onSurface,
                            //               ),
                            //             );
                            //           } else if (snapshot.hasError) {
                            //             return Center(
                            //               child: Column(
                            //                 mainAxisAlignment:
                            //                     MainAxisAlignment.center,
                            //                 children: [
                            //                   const Text(
                            //                     'An unexpected error occurred',
                            //                     textAlign: TextAlign.center,
                            //                     style: TextStyle(
                            //                       fontFamily: 'Inconsolata',
                            //                       color: Colors.red,
                            //                     ),
                            //                   ),
                            //                   const SizedBox(height: 16),
                            //                   ElevatedButton(
                            //                     onPressed: () {
                            //                       setState(() {
                            //                         _airdropsFuture2 =
                            //                             _fetchInitialAirdrops(
                            //                                 'forex');
                            //                       });
                            //                     },
                            //                     child: Text(
                            //                       'Retry',
                            //                       style: TextStyle(
                            //                         fontFamily: 'Inconsolata',
                            //                         fontWeight: FontWeight.bold,
                            //                         fontSize: 18,
                            //                         color: Theme.of(context)
                            //                             .colorScheme
                            //                             .onSurface,
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             );
                            //           }

                            //           return RefreshIndicator(
                            //             onRefresh: () =>
                            //                 _fetchInitialAirdrops('forex'),
                            //             child:
                            //                 _isLoadingAirdrops // Check if loading
                            //                     ? Center(
                            //                         child:
                            //                             CircularProgressIndicator(
                            //                           color: Theme.of(context)
                            //                               .colorScheme
                            //                               .onSurface,
                            //                         ),
                            //                       )
                            //                     : _airdropsList
                            //                             .isEmpty // Check if the list is empty
                            //                         ? Center(
                            //                             child: Text(
                            //                               'No airdrops available',
                            //                               style: TextStyle(
                            //                                 fontFamily:
                            //                                     'Inconsolata',
                            //                                 color: Theme.of(
                            //                                         context)
                            //                                     .colorScheme
                            //                                     .onSurface,
                            //                               ),
                            //                             ),
                            //                           )
                            //                         : ListView.builder(
                            //                             itemCount: _airdropsList
                            //                                 .length, // Use the length of the list
                            //                             itemBuilder:
                            //                                 (context, index) {
                            //                               final signal =
                            //                                   _airdropsList[
                            //                                       index]; // Access the list safely
                            //                               return cryptoCard(
                            //                                   signal); // Use the correct variable for the signal
                            //                             },
                            //                           ),
                            //           );
                            //         },
                            //       ),
                            //       FutureBuilder<void>(
                            //         future: _airdropsFuture3,
                            //         builder: (context, snapshot) {
                            //           if (snapshot.connectionState ==
                            //               ConnectionState.waiting) {
                            //             return Center(
                            //               child: CircularProgressIndicator(
                            //                 color: Theme.of(context)
                            //                     .colorScheme
                            //                     .onSurface,
                            //               ),
                            //             );
                            //           } else if (snapshot.hasError) {
                            //             return Center(
                            //               child: Column(
                            //                 mainAxisAlignment:
                            //                     MainAxisAlignment.center,
                            //                 children: [
                            //                   const Text(
                            //                     'An unexpected error occurred',
                            //                     textAlign: TextAlign.center,
                            //                     style: TextStyle(
                            //                       fontFamily: 'Inconsolata',
                            //                       color: Colors.red,
                            //                     ),
                            //                   ),
                            //                   const SizedBox(height: 16),
                            //                   ElevatedButton(
                            //                     onPressed: () {
                            //                       setState(() {
                            //                         _airdropsFuture3 =
                            //                             _fetchInitialAirdrops(
                            //                                 'stocks');
                            //                       });
                            //                     },
                            //                     child: Text(
                            //                       'Retry',
                            //                       style: TextStyle(
                            //                         fontFamily: 'Inconsolata',
                            //                         fontWeight: FontWeight.bold,
                            //                         fontSize: 18,
                            //                         color: Theme.of(context)
                            //                             .colorScheme
                            //                             .onSurface,
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             );
                            //           }

                            //           return RefreshIndicator(
                            //             onRefresh: () =>
                            //                 _fetchInitialAirdrops('stocks'),
                            //             child:
                            //                 _isLoadingAirdrops // Check if loading
                            //                     ? Center(
                            //                         child:
                            //                             CircularProgressIndicator(
                            //                           color: Theme.of(context)
                            //                               .colorScheme
                            //                               .onSurface,
                            //                         ),
                            //                       )
                            //                     : _airdropsList
                            //                             .isEmpty // Check if the list is empty
                            //                         ? Center(
                            //                             child: Text(
                            //                               'No airdrops available',
                            //                               style: TextStyle(
                            //                                 fontFamily:
                            //                                     'Inconsolata',
                            //                                 color: Theme.of(
                            //                                         context)
                            //                                     .colorScheme
                            //                                     .onSurface,
                            //                               ),
                            //                             ),
                            //                           )
                            //                         : ListView.builder(
                            //                             itemCount: _airdropsList
                            //                                 .length, // Use the length of the list
                            //                             itemBuilder:
                            //                                 (context, index) {
                            //                               final signal =
                            //                                   _airdropsList[
                            //                                       index]; // Access the list safely
                            //                               return cryptoCard(
                            //                                   signal); // Use the correct variable for the signal
                            //                             },
                            //                           ),
                            //           );
                            //         },
                            //       ),
                            //     ],
                            //   ),
                            // ),
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
                              RefreshIndicator(
                                onRefresh:
                                    _refreshData, // Function to refresh the events
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller:
                                      _scrollController, // Ensure _scrollController is properly set up
                                  itemCount: events.length +
                                      (isLastPage
                                          ? 0
                                          : 1), // Add 1 for the loading indicator if not the last page
                                  itemBuilder: (context, index) {
                                    if (index == events.length) {
                                      // Show a loading indicator at the bottom of the list when loading more
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
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
                              RefreshIndicator(
                                onRefresh:
                                    _refreshData, // Function to refresh the events
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller:
                                      _scrollController, // Ensure _scrollController is properly set up
                                  itemCount: events.length +
                                      (isLastPage
                                          ? 0
                                          : 1), // Add 1 for the loading indicator if not the last page
                                  itemBuilder: (context, index) {
                                    if (index == events.length) {
                                      // Show a loading indicator at the bottom of the list when loading more
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
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
                              RefreshIndicator(
                                onRefresh:
                                    _refreshData, // Function to refresh the events
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller:
                                      _scrollController, // Ensure _scrollController is properly set up
                                  itemCount: events.length +
                                      (isLastPage
                                          ? 0
                                          : 1), // Add 1 for the loading indicator if not the last page
                                  itemBuilder: (context, index) {
                                    if (index == events.length) {
                                      // Show a loading indicator at the bottom of the list when loading more
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
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
                              RefreshIndicator(
                                onRefresh:
                                    _refreshData, // Function to refresh the events
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller:
                                      _scrollController, // Ensure _scrollController is properly set up
                                  itemCount: events.length +
                                      (isLastPage
                                          ? 0
                                          : 1), // Add 1 for the loading indicator if not the last page
                                  itemBuilder: (context, index) {
                                    if (index == events.length) {
                                      // Show a loading indicator at the bottom of the list when loading more
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
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
                              RefreshIndicator(
                                onRefresh:
                                    _refreshData, // Function to refresh the events
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller:
                                      _scrollController, // Ensure _scrollController is properly set up
                                  itemCount: events.length +
                                      (isLastPage
                                          ? 0
                                          : 1), // Add 1 for the loading indicator if not the last page
                                  itemBuilder: (context, index) {
                                    if (index == events.length) {
                                      // Show a loading indicator at the bottom of the list when loading more
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
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
                              RefreshIndicator(
                                onRefresh:
                                    _refreshData, // Function to refresh the events
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller:
                                      _scrollController, // Ensure _scrollController is properly set up
                                  itemCount: events.length +
                                      (isLastPage
                                          ? 0
                                          : 1), // Add 1 for the loading indicator if not the last page
                                  itemBuilder: (context, index) {
                                    if (index == events.length) {
                                      // Show a loading indicator at the bottom of the list when loading more
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
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
                              RefreshIndicator(
                                onRefresh:
                                    _refreshData, // Function to refresh the events
                                color: Theme.of(context).colorScheme.onSurface,
                                child: ListView.builder(
                                  controller:
                                      _scrollController, // Ensure _scrollController is properly set up
                                  itemCount: events.length +
                                      (isLastPage
                                          ? 0
                                          : 1), // Add 1 for the loading indicator if not the last page
                                  itemBuilder: (context, index) {
                                    if (index == events.length) {
                                      // Show a loading indicator at the bottom of the list when loading more
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                    return cryptoCard(events[index]);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ]
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
            _buildCurvedTab('Airdrops', ''),
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
                height: 16,
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
        Uri.parse('https://signal.payguru.com.ng/api/vote'),
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
                          height: MediaQuery.of(context).size.height * 0.02,
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
                  color: isDarkMode
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.5),
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
                contentPadding: const EdgeInsets.only(
                    left: 20, right: 20, bottom: 20, top: 0),
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
        height: (160 / MediaQuery.of(context).size.height) *
            MediaQuery.of(context).size.height,
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
                contentPadding: const EdgeInsets.only(
                    left: 20, right: 20, bottom: 20, top: 0),
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

  Widget _buildTab(String name) {
    return Tab(
      child: Text(name),
    );
  }
}
