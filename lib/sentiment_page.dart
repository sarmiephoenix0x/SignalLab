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
  int _btcSelectedValue = 0;
  int _ethSelectedValue = 0;

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
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                left: 25, top: 30, bottom: 30),
                            decoration: BoxDecoration(
                              // color: Colors.white,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'images/logos_bitcoin.png',
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'BTC',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Text(
                                          '5s',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.02,
                                        ),
                                        const Text(
                                          'Total Votes: 0',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4444CE),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSelectableFieldBTC(
                                        1, "Traders should buy"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 70.0),
                                      child: Text(
                                        'Votes 0 (0%)',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSelectableFieldBTC(
                                        2, "Traders shouldn't buy"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 70.0),
                                      child: Text(
                                        'Votes 0 (0%)',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.17),
                                    const SizedBox(
                                      height: 60,
                                      child: VerticalDivider(
                                        color: Colors.black,
                                        thickness: 3.0,
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    const Expanded(
                                      child: Text(
                                        'BTC is among the most populate Crypt current around, so, I suggest traders should invest a little of their income in it.',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.only(
                                left: 25, top: 30, bottom: 30),
                            decoration: BoxDecoration(
                              // color: Colors.white,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'images/cryptocurrency-color_usdt.png',
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ETH',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Text(
                                          '5s',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.02,
                                        ),
                                        const Text(
                                          'Total Votes: 0',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Inconsolata',
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4444CE),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSelectableFieldETH(
                                        1, "Traders should buy"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 70.0),
                                      child: Text(
                                        'Votes 0 (0%)',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSelectableFieldETH(
                                        2, "Traders shouldn't buy"),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 70.0),
                                      child: Text(
                                        'Votes 0 (0%)',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.17),
                                    const SizedBox(
                                      height: 60,
                                      child: VerticalDivider(
                                        color: Colors.black,
                                        thickness: 3.0,
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.02),
                                    const Expanded(
                                      child: Text(
                                        'ETH is among the most populate Crypt current around, so, I suggest traders should invest a little of their income in it.',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _buildSelectableFieldBTC(int value, String label) {
    bool isSelected = _btcSelectedValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _btcSelectedValue = value;
        });
      },
      child: Row(
        children: [
          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
          Radio<int>(
            value: value,
            groupValue: _btcSelectedValue,
            onChanged: isSelected
                ? (int? newValue) {
                    setState(() {
                      _btcSelectedValue = newValue!;
                    });
                  }
                : null,
            activeColor: Colors.black,
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16, top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(0),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.0,
                  fontFamily: 'Inconsolata',
                  color:
                      isSelected ? Colors.black : Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),

          // GestureDetector(
          //   onTap: () {
          //     setState(() {
          //       _selectedValue = value;
          //     });
          //   },
          //   child: Image.asset(
          //     isSelected
          //         ? 'assets/active_radio.png' // Path to the active radio button image
          //         : 'assets/inactive_radio.png', // Path to the inactive radio button image
          //     width: 24.0,
          //     height: 24.0,
          //   ),
          // ),
        ],
      ),
    );
  }


  Widget _buildSelectableFieldETH(int value, String label) {
    bool isSelected = _ethSelectedValue == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _ethSelectedValue = value;
        });
      },
      child: Row(
        children: [
          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
          Radio<int>(
            value: value,
            groupValue: _ethSelectedValue,
            onChanged: isSelected
                ? (int? newValue) {
                    setState(() {
                      _ethSelectedValue = newValue!;
                    });
                  }
                : null,
            activeColor: Colors.black,
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16, top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(0),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.0,
                  fontFamily: 'Inconsolata',
                  color:
                      isSelected ? Colors.black : Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),

          // GestureDetector(
          //   onTap: () {
          //     setState(() {
          //       _selectedValue = value;
          //     });
          //   },
          //   child: Image.asset(
          //     isSelected
          //         ? 'assets/active_radio.png' // Path to the active radio button image
          //         : 'assets/inactive_radio.png', // Path to the inactive radio button image
          //     width: 24.0,
          //     height: 24.0,
          //   ),
          // ),
        ],
      ),
    );
  }
}
