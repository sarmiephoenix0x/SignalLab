import 'package:flutter/material.dart';

class SentimentPage extends StatefulWidget {
  const SentimentPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SentimentPageState createState() => _SentimentPageState();
}

class _SentimentPageState extends State<SentimentPage> {
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Image.asset('images/tabler_arrow-back.png'),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        const Expanded(
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
                      ],
                    ),
                    Expanded(
                      child: ListView(
                        children: [],
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
}
