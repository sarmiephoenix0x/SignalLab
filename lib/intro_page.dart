import 'package:flutter/material.dart' hide CarouselController;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:signal_app/sign_in_page.dart';
import 'package:signal_app/sign_up_page.dart';
import 'package:flutter/services.dart';

class IntroPage extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;
  const IntroPage(
      {super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  // ignore: library_private_types_in_public_api
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  List<String> imagePaths = [
    "images/IntroImg.png",
    "images/IntroImg2.png",
    "images/IntroImg3.png",
  ];

  List<String> imageHeaders = [
    "Grasp the markets with SignalLab",
    "Get started in only a few minutes",
    "Maximize your daily profit",
  ];

  List<String> imageSubheadings = [
    "Nostrum facilis voluptatum voluptates sunt facere, distinctio ullam aspernatur cumque autem a esse non unde, nemo iusto!",
    "Nostrum facilis voluptatum voluptates sunt facere, distinctio ullam aspernatur cumque autem a esse non unde, nemo iusto!",
    "Sign up today and enjoy the first month of premium benefits on us.",
  ];

  int _current = 0;

  // Use the fully qualified CarouselController from the carousel_slider package
  final CarouselController _controller = CarouselController();
  DateTime? currentBackPressTime;

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
    return OrientationBuilder(
      builder: (context, orientation) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, dynamic result) {
            if (!didPop) {
              DateTime now = DateTime.now();
              if (currentBackPressTime == null ||
                  now.difference(currentBackPressTime!) >
                      const Duration(seconds: 2)) {
                currentBackPressTime = now;
                _showCustomSnackBar(
                  context,
                  'Press back again to exit',
                  isError: true,
                );
              } else {
                SystemChannels.platform.invokeMethod('SystemNavigator.pop');
              }
            }
          },
          child: Scaffold(
            body: Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    CarouselSlider(
                      options: CarouselOptions(
                        enlargeCenterPage: false,
                        height: MediaQuery.of(context).size.height,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: true,
                        initialPage: 0,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index;
                          });
                        },
                      ),
                      carouselController: _controller,
                      items: imagePaths.map((item) {
                        return SingleChildScrollView(
                          child: SizedBox(
                            height: orientation == Orientation.portrait
                                ? MediaQuery.of(context).size.height
                                : MediaQuery.of(context).size.height * 2.6,
                            child: Column(
                              children: [
                                Image.asset(
                                  item,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                                const Spacer(),
                                Text(
                                  imageHeaders[_current],
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontFamily: 'Inconsolata',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.02),
                                if (_current != 2)
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: Text(
                                      imageSubheadings[_current],
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontFamily: 'Inconsolata',
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                if (_current == 2) const Spacer(),
                                if (_current == 2)
                                  Container(
                                    width: double.infinity,
                                    height: (60 /
                                            MediaQuery.of(context)
                                                .size
                                                .height) *
                                        MediaQuery.of(context).size.height,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SignUpPage(
                                                key: UniqueKey(),
                                                onToggleDarkMode:
                                                    widget.onToggleDarkMode,
                                                isDarkMode: widget.isDarkMode),
                                          ),
                                        );
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty
                                            .resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(
                                                WidgetState.pressed)) {
                                              return Colors.white;
                                            }
                                            return Colors.black;
                                          },
                                        ),
                                        foregroundColor: WidgetStateProperty
                                            .resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(
                                                WidgetState.pressed)) {
                                              return Colors.black;
                                            }
                                            return Colors.white;
                                          },
                                        ),
                                        elevation:
                                            WidgetStateProperty.all<double>(
                                                4.0),
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                          const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(15)),
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_current == 2)
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.05),
                                if (_current == 2)
                                  Container(
                                    width: double.infinity,
                                    height: (60 /
                                            MediaQuery.of(context)
                                                .size
                                                .height) *
                                        MediaQuery.of(context).size.height,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SignInPage(
                                                key: UniqueKey(),
                                                onToggleDarkMode:
                                                    widget.onToggleDarkMode,
                                                isDarkMode: widget.isDarkMode),
                                          ),
                                        );
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty
                                            .resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(
                                                WidgetState.pressed)) {
                                              return Colors.black;
                                            }
                                            return Colors.white;
                                          },
                                        ),
                                        foregroundColor: WidgetStateProperty
                                            .resolveWith<Color>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(
                                                WidgetState.pressed)) {
                                              return Colors.white;
                                            }
                                            return Colors.black;
                                          },
                                        ),
                                        elevation:
                                            WidgetStateProperty.all<double>(
                                                4.0),
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                          const RoundedRectangleBorder(
                                            side: BorderSide(width: 1),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(15)),
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Sign in',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_current != 2)
                      Positioned(
                        bottom: MediaQuery.of(context).padding.bottom + 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            imagePaths.length,
                            (index) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Image.asset(
                                _current == index
                                    ? "images/Active.png"
                                    : "images/Inactive.png",
                                width:
                                    (10 / MediaQuery.of(context).size.width) *
                                        MediaQuery.of(context).size.width,
                                height:
                                    (10 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_current != 2)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Row(
                              children: [
                                const Spacer(),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _controller.animateToPage(2);
                                      _current = 2;
                                    });
                                  },
                                  child: Text(
                                    'Skip',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
