import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SignalAuthorPage extends StatefulWidget {
  final String authorId;
  final String authorName;

  const SignalAuthorPage({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  @override
  SignalAuthorPageState createState() => SignalAuthorPageState();
}

class SignalAuthorPageState extends State<SignalAuthorPage> {
  double upvotePercentage = 60;
  double downvotePercentage = 40;
  final storage = const FlutterSecureStorage();
  bool loading = true;
  Map<String, dynamic>? authorDetails;

  @override
  void initState() {
    super.initState();
    _loadAuthorDetails();
  }

  Future<void> _loadAuthorDetails() async {
    final details = await fetchAuthorDetails(int.parse(widget.authorId));
    setState(() {
      authorDetails = details;
    });
  }

  Future<Map<String, dynamic>?> fetchAuthorDetails(int id) async {
    setState(() {
      loading = true;
    });
    final String? accessToken = await storage.read(key: 'accessToken');
    final url = 'https://signal.payguru.com.ng/api/signal/author?id=$id';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      setState(() {
        loading = false;
      });
      final author = jsonDecode(response.body);
      return author; // Return author details
    } else if (response.statusCode == 401) {
      setState(() {
        loading = false;
      });
      print('Unauthorized request');
    } else if (response.statusCode == 422) {
      setState(() {
        loading = false;
      });
      final responseBody = jsonDecode(response.body);
      print('Validation Error: ${responseBody['message']}');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: loading == true
              ? Center(
                  child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onSurface))
              : Center(
                  child: SizedBox(
                    height: orientation == Orientation.portrait
                        ? MediaQuery.of(context).size.height
                        : MediaQuery.of(context).size.height * 1.5,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
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
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Text(
                                      'Signal',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    Image.asset(
                                      "images/Active.png",
                                      width: (14 /
                                              MediaQuery.of(context)
                                                  .size
                                                  .width) *
                                          MediaQuery.of(context).size.width,
                                      height: (14 /
                                              MediaQuery.of(context)
                                                  .size
                                                  .height) *
                                          MediaQuery.of(context).size.height,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    Text(
                                      authorDetails?['name'] ??
                                          'No name available',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Inconsolata',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.1),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20.0, right: 20.0, bottom: 20.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(55),
                                          child: Container(
                                              width: (111 /
                                                      MediaQuery.of(context)
                                                          .size
                                                          .width) *
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                              height: (111 /
                                                      MediaQuery.of(context)
                                                          .size
                                                          .height) *
                                                  MediaQuery.of(context)
                                                      .size
                                                      .height,
                                              color: Colors.grey,
                                              child: Image.network(
                                                authorDetails?[
                                                        'profile_picture'] ??
                                                    '',
                                                fit: BoxFit.cover,
                                              )),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.04),
                                        Text(
                                          "Total pips profit:",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01),
                                        Text(
                                          authorDetails?['signals']
                                                  .toString() ??
                                              '0',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    Expanded(
                                      flex: 10,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            authorDetails?['name'] ??
                                                'No name available',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'Inconsolata',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 25,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Text(
                                                "5.0 (0 reviews)",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'Inconsolata',
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.06),
                                              const Text(
                                                "Ranked",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'Inconsolata',
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.02),
                                          Text(
                                            "Normal target for traded asset is (100 pips), N.B - (25 pips) can be profitable in zero spread acc. (50 pips) is assured per-trade.",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Inconsolata',
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.02),
                                          _buildTag("forex"),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.02),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: upvotePercentage
                                                    .round(), // Green bar flex
                                                child: Container(
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Color(0xFF008000),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(5),
                                                      bottomLeft:
                                                          Radius.circular(5),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: downvotePercentage
                                                    .round(), // Red bar flex
                                                child: Container(
                                                  height: 10,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topRight:
                                                          Radius.circular(5),
                                                      bottomRight:
                                                          Radius.circular(5),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
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
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
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
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.05),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profit statistics:',
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    _buildTag("forex"),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment
                                        .center, // Center align the text and chart
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.5,
                                        child: const DonutChart(
                                          upvotePercentage: 60, // 60% upvotes
                                          downvotePercentage:
                                              40, // 40% downvotes
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              "Overall rating:",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'Inconsolata',
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.01),
                                            Text(
                                              '${upvotePercentage.round()}%', // Show green percentage in center
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(
                                                    0xFF008000), // Green color for the text
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: Text(
                                      'Signal history:',
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
                                  cryptoCard(),
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

  Widget _buildTag(String tags) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      // Padding around the tag
      decoration: BoxDecoration(
        color: Colors.grey,
        // Modern blue color
        borderRadius: BorderRadius.circular(30),
        // More rounded corners for a pill-like shape
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ], // Subtle shadow for depth
      ),
      child: Text(
        tags.trim(), // Display the tag text
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'Inter',
          color: Colors.black,
          // White text on blue background
          fontWeight: FontWeight.w600,
          // Slightly bolder font for emphasis
          letterSpacing: 0.5, // Slight letter spacing for better readability
        ),
      ),
    );
  }

  Widget cryptoCard() {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        const Row(children: [
          Expanded(
            flex: 10,
            child: Text(
              "Pair",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 10,
            child: Text(
              "Type",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 10,
            child: Text(
              "Entry",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 10,
            child: Text(
              "Stop Loss",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 10,
            child: Text(
              "Take Profit",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Spacer(),
          Expanded(
            flex: 10,
            child: Text(
              "Amount of Profit",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ]),
        // marketCap('images/logos_bitcoin.png', 'BTC', "Bitcoin", "53720.87",
        //     "1.07T", "18.35B", "43.4%", const Color(0xFF008000)),
      ]),
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
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
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
}

class DonutChart extends StatelessWidget {
  final double upvotePercentage; // Value from 0 to 100
  final double downvotePercentage; // Value from 0 to 100

  const DonutChart({
    Key? key,
    required this.upvotePercentage,
    required this.downvotePercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      height: MediaQuery.of(context).size.height * 0.5,
      child: CustomPaint(
        painter: DonutChartPainter(
          upvotePercentage: upvotePercentage,
          downvotePercentage: downvotePercentage,
        ),
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double upvotePercentage;
  final double downvotePercentage;

  DonutChartPainter({
    required this.upvotePercentage,
    required this.downvotePercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 20.0; // Thickness of the donut chart
    final double radius = (size.width / 2) - strokeWidth / 2;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: radius,
    );

    final Paint upvotePaint = Paint()
      ..color = const Color(0xFF008000) // Green color for upvotes
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint downvotePaint = Paint()
      ..color = Colors.red // Red color for downvotes
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double upvoteAngle = 2 * 3.141592653589793 * (upvotePercentage / 100);
    double downvoteAngle = 2 * 3.141592653589793 * (downvotePercentage / 100);

    // Draw upvote portion
    canvas.drawArc(
        rect, -3.141592653589793 / 2, downvoteAngle, false, downvotePaint);

    canvas.drawArc(rect, -3.141592653589793 / 2 + downvoteAngle, upvoteAngle,
        false, upvotePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
