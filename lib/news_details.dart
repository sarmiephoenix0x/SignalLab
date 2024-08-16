import 'package:flutter/material.dart';

class NewsDetails extends StatefulWidget {
  const NewsDetails({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _NewsDetailsState createState() => _NewsDetailsState();
}

class _NewsDetailsState extends State<NewsDetails> {
  final GlobalKey _key = GlobalKey();
  final FocusNode _commentFocusNode = FocusNode();

  final TextEditingController commentController = TextEditingController();

  void _showPopupMenu(BuildContext context) async {
    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx,
          position.dy + renderBox.size.height,
          position.dx + renderBox.size.width,
          position.dy),
      items: [
        PopupMenuItem<String>(
          value: 'Share',
          child: Row(
            children: [
              Image.asset(
                'images/share-box-line.png',
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.05,
              ),
              const Text(
                'Share',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Report',
          child: Row(
            children: [
              Image.asset(
                'images/feedback-line.png',
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.05,
              ),
              const Text(
                'Report',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Save',
          child: Row(
            children: [
              Image.asset(
                'images/save-line.png',
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.05,
              ),
              const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Open',
          child: Row(
            children: [
              Image.asset(
                'images/basketball-line.png',
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.05,
              ),
              const Text(
                'Open in browser',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
      elevation: 8.0,
    ).then((value) {
      if (value != null) {
        _handleMenuSelection(value);
      }
    });
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'Share':
        break;
      case 'Report':
        break;
      case 'Save':
        break;
      case 'Open':
        break;
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.1),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child:
                                    Image.asset('images/tabler_arrow-back.png'),
                              ),
                              const Spacer(),
                            ],
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.05),
                          Row(
                            children: [
                              Image.asset(
                                'images/NewsProfileImg.png',
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.01,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Zepenllin',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.01,
                                    ),
                                    const Text(
                                      '6m ago',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.lightBlue,
                                          fontSize: 16,
                                          fontFamily: 'Inter'),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  _showPopupMenu(context);
                                },
                                child: SizedBox(
                                  key: _key,
                                  width: 20,
                                  child: Image.asset(
                                    'images/MoreButton.png',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          const Text(
                            "Binance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function...",
                            style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Image.asset(
                              'images/NewsPost.png',
                            ),
                          ),
                          const Text(
                            "Featuring over 16 merchants and mini apps, Binance Marketplace is a one-stop shop for all your crypto payment needs and more. \n\nDiscover exclusive offers when you pay for hotel stays, rideshare services, shopping, dining, and more with Binance Pay via Binance Marketplace.",
                            style: TextStyle(fontSize: 16, fontFamily: 'Inter'),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.05),
                          const Center(
                            child: Text(
                              'What Can You Do on Marketplace? ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.05),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 76.0),
                            child: Text(
                              "On Binance Marketplace, you can make purchases, book hotel stays and experiences with crypto, participate in Binance Launchpad, and even earn rewards with Liquid Swap. You can also access the Binance DeFi Wallet, NFT Marketplace, and Binance Live via the Binance Marketplace. \n\nThere are also mini games within the app that you can play with friends and that offer you a chance to win prizes. Need to top up your phone credit? Do it from anywhere you please with the [Mobile Top-Up] feature on Binance Marketplace and earn cashback while you're at it. Looking for an easy way to spend your crypto? Check out Binance Marketplace today. With new merchants added each month, experience a whole new level of convenience!",
                              style:
                                  TextStyle(fontSize: 16, fontFamily: 'Inter'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: (80 / MediaQuery.of(context).size.height) *
                          MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(width: 0, color: Colors.black),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(children: [
                            Image.asset(
                              'images/camera-3-line.png',
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: SingleChildScrollView(
                                      child: TextFormField(
                                        keyboardType: TextInputType.multiline,
                                        maxLines: null,
                                        controller: commentController,
                                        focusNode: _commentFocusNode,
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          decoration: TextDecoration.none,
                                        ),
                                        decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.only(
                                              left: 20,
                                              right: 65,
                                              bottom: 20,
                                              top: 0),
                                          labelText: 'Write a comment',
                                          labelStyle: TextStyle(
                                            color: Colors.grey,
                                            fontFamily: 'Inter',
                                            fontSize: 16.0,
                                          ),
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.never,
                                          border: InputBorder.none,
                                        ),
                                        cursorColor: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: MediaQuery.of(context).padding.left +
                                        10,
                                    bottom: 0,
                                    child: Image.asset(
                                      'images/user-smile-line.png',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
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
