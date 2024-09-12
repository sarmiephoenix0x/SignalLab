import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class TradingViewPage extends StatefulWidget {
  const TradingViewPage({super.key});

  @override
  TradingViewPageState createState() => TradingViewPageState();
}

class TradingViewPageState extends State<TradingViewPage> {
  final String coinSymbol = "BINANCE:BTCUSDT";
  late final WebViewController _controller;
  late final WebViewController _controller2;
  bool _isRefreshing = false; // Track the refreshing state
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
    // _controller = WebViewController()
    //   ..setJavaScriptMode(JavaScriptMode.unrestricted);
    //
    // String htmlString = '''
    //   <!DOCTYPE html>
    //   <html>
    //     <head>
    //       <meta name="viewport" content="width=device-width, initial-scale=1.0">
    //       <style>
    //         html, body {
    //           height: 100%;
    //           margin: 0;
    //           padding: 0;
    //         }
    //         .tradingview-widget-container {
    //           height: 100%;
    //           width: 100%;
    //         }
    //       </style>
    //     </head>
    //     <body>
    //       <div class="tradingview-widget-container">
    //         <div id="tradingview_5c88f" style="height: 100%; width: 100%;"></div>
    //         <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
    //         <script type="text/javascript">
    //         new TradingView.widget({
    //           "width": "100%",
    //           "height": "100%",
    //           "symbol": "$coinSymbol",
    //           "interval": "D",
    //           "timezone": "Etc/UTC",
    //           "theme": "light",
    //           "style": "1",
    //           "locale": "en",
    //           "toolbar_bg": "#f1f3f6",
    //           "enable_publishing": false,
    //           "withdateranges": true,
    //           "hide_side_toolbar": false,
    //           "allow_symbol_change": true,
    //           "details": true,
    //           "hotlist": true,
    //           "calendar": true,
    //           "studies": [
    //             "MACD@tv-basicstudies",
    //             "StochasticRSI@tv-basicstudies"
    //           ],
    //           "container_id": "tradingview_5c88f"
    //         });
    //         </script>
    //       </div>
    //     </body>
    //   </html>
    // ''';
    //
    // _controller.loadHtmlString(htmlString);

    _controller2 = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          'https://s.tradingview.com/widgetembed/?symbol=$coinSymbol&interval=D&hidesidetoolbar=1&symboledit=1&saveimage=1&toolbarbg=f1f3f6&studies=[]&theme=Dark&style=1&timezone=Etc/UTC&studies_overrides={}&overrides={}&enabled_features=[]&disabled_features=[]&locale=en'));
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        _showNoInternetDialog(context);
        setState(() {
          _isRefreshing = false;
        });
        return;
      }

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
    //Reload the WebView content
    // _controller.loadHtmlString('''
    //     <!DOCTYPE html>
    //     <html>
    //       <head>
    //         <meta name="viewport" content="width=device-width, initial-scale=1.0">
    //         <style>
    //           html, body {
    //             height: 100%;
    //             margin: 0;
    //             padding: 0;
    //           }
    //           .tradingview-widget-container {
    //             height: 100%;
    //             width: 100%;
    //           }
    //         </style>
    //       </head>
    //       <body>
    //         <div class="tradingview-widget-container">
    //           <div id="tradingview_5c88f" style="height: 100%; width: 100%;"></div>
    //           <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
    //           <script type="text/javascript">
    //           new TradingView.widget({
    //             "width": "100%",
    //             "height": "100%",
    //             "symbol": "$coinSymbol",
    //             "interval": "D",
    //             "timezone": "Etc/UTC",
    //             "theme": "light",
    //             "style": "1",
    //             "locale": "en",
    //             "toolbar_bg": "#f1f3f6",
    //             "enable_publishing": false,
    //             "withdateranges": true,
    //             "hide_side_toolbar": false,
    //             "allow_symbol_change": true,
    //             "details": true,
    //             "hotlist": true,
    //             "calendar": true,
    //             "studies": [
    //               "MACD@tv-basicstudies",
    //               "StochasticRSI@tv-basicstudies"
    //             ],
    //             "container_id": "tradingview_5c88f"
    //           });
    //           </script>
    //         </div>
    //       </body>
    //     </html>
    //   ''');

    _controller2.loadRequest(Uri.parse(
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
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (!didPop) {
          // Check if WebView can go back
          bool canGoBack = await _controller2.canGoBack();

          if (canGoBack) {
            // If WebView can go back, navigate back in WebView
            await _controller2.goBack();
          } else {
            DateTime now = DateTime.now();
            if (currentBackPressTime == null ||
                now.difference(currentBackPressTime!) >
                    const Duration(seconds: 2)) {
              currentBackPressTime = now;
              _showCustomSnackBar(
                context,
                'Press back again to exit the chart view',
                isError: true,
              );
            } else {
              Navigator.pop(context);
            }
          }
        }
      },
      child: Scaffold(
        body: Column(
          children: <Widget>[
            SizedBox(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      bool canGoBack = await _controller2.canGoBack();

                      if (canGoBack) {
                        // If WebView can go back, navigate back in WebView
                        await _controller2.goBack();
                      } else {
                        DateTime now = DateTime.now();
                        if (currentBackPressTime == null ||
                            now.difference(currentBackPressTime!) >
                                const Duration(seconds: 2)) {
                          currentBackPressTime = now;
                          _showCustomSnackBar(
                            context,
                            'Press back again to exit the chart view',
                            isError: true,
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      }
                      // Navigator.pop(context);
                    },
                    child: Image.asset('images/tabler_arrow-back.png'),
                  ),
                  const Spacer(),
                  const Expanded(
                    flex: 10,
                    child: Text(
                      'Live, Crypto, Forex and Stocks',
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
                  if (_isRefreshing)
                    const Center(
                        child: CircularProgressIndicator(color: Colors.black))
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refreshData,
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
            // Expanded(
            //   flex: 1,
            //   child: WebViewWidget(controller: _controller),
            // ),
            Expanded(
              flex: 1,
              child: WebViewWidget(controller: _controller2),
            ),
          ],
        ),
      ),
    );
  }
}
