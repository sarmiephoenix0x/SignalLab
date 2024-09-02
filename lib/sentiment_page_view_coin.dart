import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  String _errorMessage = '';
  final storage = const FlutterSecureStorage();
  List<dynamic> sentiments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _fetchSentimentDetails(widget.sentimentId);
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchSentimentDetails(int id) async {
    setState(() {
      loading = true;
    });
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
        _errorMessage = 'Unauthorized. Please check your token.';
      });
      print(_errorMessage);
    } else if (response.statusCode == 422) {
      final errorResponse = jsonDecode(response.body);
      setState(() {
        loading = false;
        _errorMessage = 'Validation Error: ${errorResponse['message']}';
      });
      print(_errorMessage);
    } else {
      setState(() {
        loading = false;
        _errorMessage = 'Unexpected error occurred.';
      });
      print(_errorMessage);
    }
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
                            const Spacer(),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: Container(
                                width:
                                    (48 / MediaQuery.of(context).size.width) *
                                        MediaQuery.of(context).size.width,
                                height:
                                    (48 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                color: Colors.grey,
                                child: Image.network(
                                  widget.sentimentImg,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
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
                            Image.asset('images/NextButton.png'),
                          ],
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      _tabBar(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
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
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 20.0, right: 20.0, bottom: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 10,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                'images/ph_coin-duotone.png',
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.03),
                                              const Expanded(
                                                flex: 10,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Price',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$N/A',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$N/A',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Expanded(
                                          flex: 10,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                'images/oui_vis-pie.png',
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.03),
                                              const Expanded(
                                                flex: 10,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Market cap',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$N/A',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$N/A',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.03),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 10,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                'images/vaadin_coin-piles.png',
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.03),
                                              const Expanded(
                                                flex: 10,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Volume (24h)',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$N/A',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$N/A',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Expanded(
                                          flex: 10,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Image.asset(
                                                'images/clarity_block-line.png',
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.03),
                                              const Expanded(
                                                flex: 10,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Volume (24h)',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$ (Max)',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    Text(
                                                      '\$ (Available)',
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Inconsolata',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.03),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 20.0,
                                          right: 20.0,
                                          bottom: 20.0),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'Events are managed by official representatives',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Colors.black,
                                              ),
                                            ),
                                            WidgetSpan(
                                              child: Image.asset(
                                                'images/mdi_tick-decagram-green.png',
                                                width: 20,
                                                height: 20,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 20.0,
                                          right: 20.0,
                                          bottom: 20.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10.0,
                                              right: 10.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'images/streamline_web.png',
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03),
                                                const Text(
                                                  'Website',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10.0,
                                              right: 10.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'images/logos_telegram.png',
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03),
                                                const Text(
                                                  'Telegram',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 20.0,
                                          right: 20.0,
                                          bottom: 20.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10.0,
                                              right: 10.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'images/logos_reddit-icon.png',
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03),
                                                const Text(
                                                  'Reddit',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 10.0,
                                              right: 10.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'images/icon-park_github.png',
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03),
                                                const Text(
                                                  'Github',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Inconsolata',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 20.0,
                                          right: 20.0,
                                          bottom: 20.0),
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            left: 12.0,
                                            right: 12.0,
                                            bottom: 20.0,
                                            top: 20.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 3,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Statistics',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.03),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: (120 /
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width) *
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 3,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Image.asset(
                                                                'images/noto_fire.png',
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.01),
                                                              const Expanded(
                                                                child: Text(
                                                                  'Upcoming',
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Inconsolata',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.03),
                                                          const Text(
                                                            '1',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 30,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03),
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: (120 /
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width) *
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 3,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Image.asset(
                                                                'images/lets-icons_up.png',
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.01),
                                                              const Expanded(
                                                                child: Text(
                                                                  'Trending',
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Inconsolata',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.03),
                                                          const Text(
                                                            '#1',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 30,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.03),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: (120 /
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width) *
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 3,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Image.asset(
                                                                'images/noto_crown.png',
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.01),
                                                              const Expanded(
                                                                child: Text(
                                                                  'Significance',
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style:
                                                                      TextStyle(
                                                                    fontFamily:
                                                                        'Inconsolata',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.03),
                                                          const Text(
                                                            '1',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 30,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03),
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: (120 /
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width) *
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 3,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Image.asset(
                                                                'images/noto_fire.png',
                                                              ),
                                                              SizedBox(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.01),
                                                              const Text(
                                                                'Hot',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Inconsolata',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.03),
                                                          const Text(
                                                            '1',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 30,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 20.0,
                                          right: 20.0,
                                          bottom: 20.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              spreadRadius: 3,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            const Text(
                                              'Validation',
                                              style: TextStyle(
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.03),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: (120 /
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width) *
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 3,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          const Text(
                                                            'Confidence',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.03),
                                                          const Text(
                                                            '88%',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 30,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.03),
                                                    Image.asset(
                                                      'images/Thumbs-up.png',
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.03),
                                                Column(
                                                  children: [
                                                    Container(
                                                      width: (120 /
                                                              MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width) *
                                                          MediaQuery.of(context)
                                                              .size
                                                              .width,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(0),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.5),
                                                            spreadRadius: 3,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          const Text(
                                                            'Votes',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height *
                                                                  0.03),
                                                          const Text(
                                                            '76',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inconsolata',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 30,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.03),
                                                    Image.asset(
                                                      'images/Thumbs-down.png',
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (loading)
                            const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.black),
                            )
                          else
                            ListView.builder(
                              itemCount: sentiments.length,
                              itemBuilder: (context, index) {
                                return cryptoCard(ValueNotifier<bool>(false),
                                    sentiments[index]);
                              },
                            ),
                        ],
                      )),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _tabBar() {
    if (tabController != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.black),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            indicator: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(25),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            overlayColor: const WidgetStatePropertyAll(Colors.black),
            splashBorderRadius: BorderRadius.circular(25),
            dividerHeight: 0,
            controller: tabController!,
            tabs: [
              _buildCurvedTab('Infos'),
              _buildCurvedTab('Events'),
            ],
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
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

  Widget cryptoCard(ValueNotifier<bool> dropdownStateNotifier,
      Map<String, dynamic> sentiment) {
    int totalVotes =
        int.parse(sentiment['upvotes']) + int.parse(sentiment['downvotes']);
    double upvotePercentage =
        totalVotes > 0 ? int.parse(sentiment['upvotes']) / totalVotes : 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
          'id': sentiment['id'],
        }),
      );

      if (response.statusCode == 200) {
        // Handle success
        print("Successfully ${type == 'upvote' ? 'Upvoted' : 'Downvoted'}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully ${type == 'upvote' ? 'Upvoted' : 'Downvoted'}'),
          ),
        );
        await _fetchSentimentDetails(sentiment['id']);
      } else if (response.statusCode == 400) {
        // Handle bad request
        print("Something isn't right");
      } else if (response.statusCode == 401) {
        // Handle unauthorized
        print("Unauthorized");
      } else if (response.statusCode == 422) {
        // Handle validation errors
        print("Validation error: ${response.body}");
      }
    }

    return ValueListenableBuilder<bool>(
      valueListenable: dropdownStateNotifier,
      builder: (context, dropdownState, _) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenHeight * 0.01,
          ),
          child: InkWell(
            onTap: () {},
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
                            sentiment['image'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                            Text(
                              sentiment['created_at'],
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            // Row(
                            //   children: [
                            //     Text(
                            //       '151MM Token Unlock ',
                            //       style: TextStyle(
                            //         fontFamily: 'Inconsolata',
                            //         fontWeight: FontWeight.bold,
                            //         fontSize: screenWidth * 0.04,
                            //         color: Colors.black,
                            //       ),
                            //     ),
                            //     Image.asset(
                            //       'images/lets-icons_up.png',
                            //       width: screenWidth * 0.04,
                            //       height: screenWidth * 0.04,
                            //       fit: BoxFit.cover,
                            //     ),
                            //     SizedBox(width: screenWidth * 0.01),
                            //     Image.asset(
                            //       'images/noto_fire.png',
                            //       width: screenWidth * 0.04,
                            //       height: screenWidth * 0.04,
                            //       fit: BoxFit.cover,
                            //     ),
                            //     SizedBox(width: screenWidth * 0.01),
                            //     Image.asset(
                            //       'images/noto_crown.png',
                            //       width: screenWidth * 0.04,
                            //       height: screenWidth * 0.04,
                            //       fit: BoxFit.cover,
                            //     ),
                            //   ],
                            // ),
                            Text(
                              sentiment['sub_text'],
                              maxLines: 2, // Limits sub_text to two lines
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.04,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '${(upvotePercentage * 100).toStringAsFixed(1)}% | $totalVotes votes ',
                                  style: const TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
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
                                      width: MediaQuery.of(context).size.width *
                                          0.2,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 0.5, color: Colors.black),
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              children: [
                                Text(
                                  'Insight',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    dropdownStateNotifier.value =
                                        !dropdownStateNotifier.value;
                                  },
                                  child: Image.asset(
                                    dropdownState
                                        ? 'images/material-symbols_arrow-drop-down-upwards.png'
                                        : 'images/material-symbols_arrow-drop-down.png',
                                    width: screenWidth * 0.05,
                                    height: screenWidth * 0.05,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                            if (dropdownState)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Container(
                                  width: screenWidth * 0.8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    sentiment['insight'],
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inconsolata',
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
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
      },
    );
  }
}
