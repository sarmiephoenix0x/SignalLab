import 'package:flutter/material.dart';

class SentimentPage extends StatefulWidget {
  const SentimentPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SentimentPageState createState() => _SentimentPageState();
}

class _SentimentPageState extends State<SentimentPage>
    with TickerProviderStateMixin {
  int _btcSelectedValue = 0;
  int _ethSelectedValue = 0;
  int _bnbSelectedValue = 0;

  late AnimationController _btcController;
  late AnimationController _ethController;
  late AnimationController _bnbController;
  late Animation<double> _btcAnimation;
  late Animation<double> _ethAnimation;
  late Animation<double> _bnbAnimation;
  final double _fillPercentage = 0.1;
  List<int> _btcTapCounts = [0, 0, 0];
  List<int> _ethTapCounts = [0, 0, 0];
  List<int> _bnbTapCounts = [0, 0, 0];

  @override
  void initState() {
    super.initState();
    _btcController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _ethController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bnbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _btcAnimation =
        Tween<double>(begin: 0, end: _fillPercentage).animate(_btcController);
    _ethAnimation =
        Tween<double>(begin: 0, end: _fillPercentage).animate(_ethController);
    _bnbAnimation =
        Tween<double>(begin: 0, end: _fillPercentage).animate(_bnbController);
  }

  void _onBTCFieldTapped(int value) {
    setState(() {
      if (_btcSelectedValue == value) {
        _btcSelectedValue = -1;
        _btcTapCounts[value - 1] = 0;
        _btcController.reverse();
      } else {
        _btcSelectedValue = value;
        _btcTapCounts[_btcSelectedValue - 1]++;
        _btcController.forward(from: 0.0);
        for (int i = 0; i < _btcTapCounts.length; i++) {
          if (i != _btcSelectedValue - 1) {
            _btcTapCounts[i] = 0;
          }
        }
      }
    });
  }

  void _onETHFieldTapped(int value) {
    setState(() {
      if (_ethSelectedValue == value) {
        _ethSelectedValue = -1;
        _ethTapCounts[value - 1] = 0;
        _ethController.reverse();
      } else {
        _ethSelectedValue = value;
        _ethTapCounts[_ethSelectedValue - 1]++;
        _ethController.forward(from: 0.0);
        for (int i = 0; i < _ethTapCounts.length; i++) {
          if (i != _ethSelectedValue - 1) {
            _ethTapCounts[i] = 0;
          }
        }
      }
    });
  }

  void _onBNBFieldTapped(int value) {
    setState(() {
      if (_bnbSelectedValue == value) {
        _bnbSelectedValue = -1;
        _bnbTapCounts[value - 1] = 0;
        _bnbController.reverse();
      } else {
        _bnbSelectedValue = value;
        _bnbTapCounts[_bnbSelectedValue - 1]++;
        _bnbController.forward(from: 0.0);
        for (int i = 0; i < _bnbTapCounts.length; i++) {
          if (i != _bnbSelectedValue - 1) {
            _bnbTapCounts[i] = 0;
          }
        }
      }
    });
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
                                        Row(
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
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.05),
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFFF0000),
                                                  width: 1,
                                                ),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    'images/noto_fire.png',
                                                  ),
                                                  SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.03),
                                                  const Text(
                                                    '#1 Trending',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: 'Inconsolata',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFFF0000),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                                _buildSelectableFieldBTC(
                                    1, "Traders should buy"),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                _buildSelectableFieldBTC(
                                    2, "Traders shouldn't buy"),
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
                                _buildSelectableFieldETH(
                                    1, "Traders should buy"),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                _buildSelectableFieldETH(
                                    2, "Traders shouldn't buy"),
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
                                      'images/token-branded_binance-smart-chain.png',
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
                                          'BNB',
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
                                _buildSelectableFieldBNB(
                                    1, "Traders should buy"),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                _buildSelectableFieldBNB(
                                    2, "Traders shouldn't buy"),
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
                                        'BNB is among the most populate Crypt current around, so, I suggest traders should invest a little of their income in it.',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _onBTCFieldTapped(value);
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                GestureDetector(
                  onTap: () {
                    _onBTCFieldTapped(value);
                  },
                  child: Image.asset(
                    isSelected
                        ? 'images/voted.png' // Path to the voted image
                        : 'images/not_voted.png',
                    width: 30.0,
                    height: 24.0, // Path to the not voted image
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _btcAnimation,
                        builder: (context, child) {
                          return Container(
                            width: MediaQuery.of(context).size.width *
                                (isSelected ? _btcAnimation.value : 0),
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0000FF)
                                  : Colors
                                      .transparent, // Background color for the loading bar
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16, top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inconsolata',
                            color: isSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.01,
        ),
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.18),
          child: Text(
            'Votes ${_btcTapCounts[value - 1]} (${(isSelected ? _fillPercentage * 100 : 0).toStringAsFixed(0)}%)',
            softWrap: true,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inconsolata',
              color: isSelected ? const Color(0xFF0000FF) : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableFieldETH(int value, String label) {
    bool isSelected = _ethSelectedValue == value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _onETHFieldTapped(value);
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                GestureDetector(
                  onTap: () {
                    _onETHFieldTapped(value);
                  },
                  child: Image.asset(
                    isSelected
                        ? 'images/voted.png' // Path to the voted image
                        : 'images/not_voted.png',
                    width: 30.0,
                    height: 24.0, // Path to the not voted image
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _ethAnimation,
                        builder: (context, child) {
                          return Container(
                            width: MediaQuery.of(context).size.width *
                                (isSelected ? _ethAnimation.value : 0),
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0000FF)
                                  : Colors
                                      .transparent, // Background color for the loading bar
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16, top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inconsolata',
                            color: isSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.01,
        ),
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.18),
          child: Text(
            'Votes ${_ethTapCounts[value - 1]} (${(isSelected ? _fillPercentage * 100 : 0).toStringAsFixed(0)}%)',
            softWrap: true,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inconsolata',
              color: isSelected ? const Color(0xFF0000FF) : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableFieldBNB(int value, String label) {
    bool isSelected = _bnbSelectedValue == value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _onBNBFieldTapped(value);
          },
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                GestureDetector(
                  onTap: () {
                    _onBNBFieldTapped(value);
                  },
                  child: Image.asset(
                    isSelected
                        ? 'images/voted.png' // Path to the voted image
                        : 'images/not_voted.png',
                    width: 30.0,
                    height: 24.0, // Path to the not voted image
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _bnbAnimation,
                        builder: (context, child) {
                          return Container(
                            width: MediaQuery.of(context).size.width *
                                (isSelected ? _bnbAnimation.value : 0),
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0000FF)
                                  : Colors
                                      .transparent, // Background color for the loading bar
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16, top: 10, bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inconsolata',
                            color: isSelected ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.01,
        ),
        Padding(
          padding:
              EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.18),
          child: Text(
            'Votes ${_bnbTapCounts[value - 1]} (${(isSelected ? _fillPercentage * 100 : 0).toStringAsFixed(0)}%)',
            softWrap: true,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inconsolata',
              color: isSelected ? const Color(0xFF0000FF) : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
