import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PackagesPageState createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
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
    //Put the method to call here
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
              child: SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.1),
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
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            const Text(
                              'Packages',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                                color: Colors.black,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      Expanded(
                        child: ListView(
                          children: [
                            packages(
                                'Basic',
                                '50.00',
                                '5-7 Signals send daily',
                                '85% Success rate',
                                'Entry take profit & stop loss',
                                'Amount to risk per trade',
                                'Risk reward ratio'),
                            packages(
                                'Golden',
                                '59.00',
                                '3-5 Signals send daily',
                                '55% Success rate',
                                'Entry take profit & stop loss',
                                'Amount to risk per trade',
                                'Risk reward ratio'),
                            packages(
                                'Silver',
                                '70.00',
                                '30-50 Signals send daily',
                                '99.99% Success rate',
                                'Entry take profit & stop loss',
                                'Amount to risk per trade',
                                'Risk reward ratio'),
                            packages(
                                'Platinum',
                                '99.00',
                                '5-15 Signals send daily',
                                '70% Success rate',
                                'Entry take profit & stop loss',
                                'Amount to risk per trade',
                                'Risk reward ratio'),
                            packages(
                                'Advance',
                                '100.00',
                                '5-10 Signals send daily',
                                '90% Success rate',
                                'Entry take profit & stop loss',
                                'Amount to risk per trade',
                                'Risk reward ratio'),
                            packages(
                                'Premium',
                                '150.00',
                                '30-50 Signals send daily',
                                '95% Success rate',
                                'Entry take profit & stop loss',
                                'Amount to risk per trade',
                                'Risk reward ratio'),
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

  Widget packages(String name, String amount, String text1, String text2,
      String text3, String text4, String text5) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, left: 20, right: 20),
      child: IntrinsicHeight(
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
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '\$$amount',
                style: const TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Image.asset(
                    'images/mdi_tick-decagram.png',
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Text(
                    text1,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Image.asset(
                    'images/mdi_tick-decagram.png',
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Text(
                    text2,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Image.asset(
                    'images/mdi_tick-decagram.png',
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Text(
                    text3,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Image.asset(
                    'images/mdi_tick-decagram.png',
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Text(
                    text4,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Row(
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  Image.asset(
                    'images/mdi_tick-decagram.png',
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                  Text(
                    text5,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Container(
                width: double.infinity,
                height: (60 / MediaQuery.of(context).size.height) *
                    MediaQuery.of(context).size.height,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.white;
                        }
                        return Colors.black;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.black;
                        }
                        return Colors.white;
                      },
                    ),
                    elevation: WidgetStateProperty.all<double>(4.0),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                    ),
                  ),
                  child: const Text(
                    'Choose Package',
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
    );
  }
}
