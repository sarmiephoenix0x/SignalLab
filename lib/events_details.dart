import 'package:flutter/material.dart';

class EventsDetails extends StatefulWidget {
  const EventsDetails({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EventsDetailsState createState() => _EventsDetailsState();
}

class _EventsDetailsState extends State<EventsDetails> {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
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
                        const Spacer(),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(
                        top: 12.0, bottom: 12.0, left: 20, right: 20),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Binance Expands Account Statement Function',
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 22.0,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Image.asset(
                            'images/NewsPost.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Text(
                          "Binance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function.\nBinance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function. \nBinance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function. \nBinance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function. \nBinance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function. \nBinance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function",
                          style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
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
}
