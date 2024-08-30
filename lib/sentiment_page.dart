import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signal_app/events_details.dart';
import 'package:signal_app/sentiment_page_view_coin.dart';

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
  TabController? tabController;
  Color _indicatorColor = const Color(0xFFFF0000);
  bool tabTapped = false;
  String trendImg = 'images/lets-icons_up-white.png';
  String todayImg = 'images/wpf_today-black.png';
  String resultImg = 'images/carbon_result-new.png';
  late List<ValueNotifier<List<ValueNotifier<bool>>>> tabStateNotifiers;
  OverlayEntry? _overlayEntry;
  ValueNotifier<bool> varNameNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> varNameNotifier2 = ValueNotifier<bool>(false);
  ValueNotifier<bool> varNameNotifier3 = ValueNotifier<bool>(false);
  ValueNotifier<bool> varNameNotifier4 = ValueNotifier<bool>(false);
  ValueNotifier<bool> varNameNotifier5 = ValueNotifier<bool>(false);
  ValueNotifier<bool> varNameNotifier6 = ValueNotifier<bool>(false);
  ValueNotifier<bool> varNameNotifier7 = ValueNotifier<bool>(false);
  ValueNotifier<bool> varNameNotifier8 = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 6, vsync: this);
    tabController!.addListener(_handleTabSelection);
    tabStateNotifiers = List.generate(
      6,
      (tabIndex) => ValueNotifier<List<ValueNotifier<bool>>>(
        List.generate(10, (index) => ValueNotifier<bool>(false)),
      ),
    );
  }

  @override
  void dispose() {
    tabController?.dispose();
    for (final notifier in tabStateNotifiers) {
      for (final item in notifier.value) {
        item.dispose();
      }
      notifier.dispose();
    }
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      switch (tabController!.index) {
        case 0:
          _indicatorColor = const Color(0xFFFF0000);
          trendImg = 'images/lets-icons_up-white.png';
          todayImg = 'images/wpf_today-black.png';
          resultImg = 'images/carbon_result-new.png';
          break;
        case 1:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          todayImg = 'images/wpf_today-black.png';
          resultImg = 'images/carbon_result-new.png';
          break;
        case 2:
          _indicatorColor = Colors.black;
          todayImg = 'images/wpf_today.png';
          resultImg = 'images/carbon_result-new.png';
          break;
        case 5:
          _indicatorColor = Colors.black;
          resultImg = 'images/carbon_result-new-white.png';
          todayImg = 'images/wpf_today-black.png';
          break;
        default:
          _indicatorColor = Colors.black;
          trendImg = 'images/lets-icons_up.png';
          todayImg = 'images/wpf_today-black.png';
          resultImg = 'images/carbon_result-new.png';
      }
    });
  }

  void _showFilterOverlay() {
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => SafeArea(
        child: GestureDetector(
          onTap: _removeOverlay, // Close the overlay on tap outside
          child: Material(
            color: Colors.black.withOpacity(0.5), // Semi-transparent background
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Do nothing on tap inside this widget
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 30), // Margin to limit width
                  padding: const EdgeInsets.only(
                      left: 12.0, right: 12.0, top: 20.0, bottom: 20.0),
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize
                          .min, // Makes container adjust height based on content
                      children: [
                        const Text(
                          'Filter',
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontFamily: 'Inconsolata',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 10,
                                  child: filterContents2(
                                      'Dates', varNameNotifier)),
                              const Spacer(),
                              Expanded(
                                  flex: 10,
                                  child: filterContents2(
                                      'Dates', varNameNotifier2)),
                            ],
                          ),
                        ),
                        filterContents('Keywords', varNameNotifier3),
                        filterContents('Select coins', varNameNotifier4),
                        filterContents('Exchanges - All', varNameNotifier5),
                        filterContents('Categories - All', varNameNotifier6),
                        filterContents('Sort by', varNameNotifier7),
                        filterContents('Show only', varNameNotifier8),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        Container(
                          width: double.infinity,
                          height: (60 / MediaQuery.of(context).size.height) *
                              MediaQuery.of(context).size.height,
                          padding: const EdgeInsets.symmetric(horizontal: 30.0),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return Colors.white;
                                  }
                                  return Colors.black;
                                },
                              ),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.pressed)) {
                                    return Colors.black;
                                  }
                                  return Colors.white;
                                },
                              ),
                              elevation: WidgetStateProperty.all<double>(4.0),
                              shape: WidgetStateProperty.all<
                                  RoundedRectangleBorder>(
                                const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Proceed',
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
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, dynamic result) {
            if (!didPop) {
              if (_overlayEntry != null) {
                _removeOverlay();
              } else {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                }
              }
            }
          },
          child: Scaffold(
            body: Center(
              child: SizedBox(
                height: orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.height
                    : MediaQuery.of(context).size.height * 1.5,
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
                            const Expanded(
                              flex: 10,
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
                            Image.asset('images/SearchButton.png'),
                            InkWell(
                              onTap: () {
                                _showFilterOverlay();
                              },
                              child: Image.asset('images/FilterButton.png'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03,
                      ),
                      _latestInfoTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: tabController,
                          children: List.generate(
                            6,
                            (tabIndex) => ValueListenableBuilder<
                                List<ValueNotifier<bool>>>(
                              valueListenable: tabStateNotifiers[tabIndex],
                              builder: (context, dropdownStates, child) {
                                return ListView.builder(
                                  itemCount: dropdownStates.length,
                                  itemBuilder: (context, index) {
                                    return cryptoCard(
                                      dropdownStateNotifier:
                                          dropdownStates[index],
                                      toggleDropDown: () {
                                        dropdownStates[index].value =
                                            !dropdownStates[index].value;
                                      },
                                      context: context,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
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

  Widget _latestInfoTabBar() {
    if (tabController != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: TabBar(
          indicator: BoxDecoration(
            color: _indicatorColor,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding:
              const EdgeInsets.only(left: 2.1, right: 2.1, bottom: 6.6, top: 5),
          dividerHeight: 0,
          tabAlignment: TabAlignment.start,
          controller: tabController!,
          isScrollable: true,
          splashBorderRadius: BorderRadius.circular(10),
          tabs: [
            _buildCurvedTab('Trending', trendImg),
            _buildCurvedTab('Significant', 'images/noto_crown.png'),
            _buildCurvedTab('Today', todayImg),
            _buildCurvedTab('This Week', ''),
            _buildCurvedTab('This Month', ''),
            _buildCurvedTab('Result', resultImg),
          ],
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildCurvedTab(String label, String img) {
    return Tab(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            if (img != '')
              Image.asset(
                img,
              ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.01),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cryptoCard({
    required ValueNotifier<bool> dropdownStateNotifier,
    required VoidCallback toggleDropDown,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return ValueListenableBuilder<bool>(
      valueListenable: dropdownStateNotifier,
      builder: (context, dropdownState, child) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenHeight * 0.01,
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SentimentViewCoin(key: UniqueKey()),
                ),
              );
            },
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
                      Image.asset(
                        'images/logos_bitcoin.png',
                        width: screenWidth * 0.10,
                        height: screenWidth * 0.10, // Maintain aspect ratio
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bitcoin (BTC)',
                              style: TextStyle(
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.05,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '18 August 2024',
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Text(
                                  '151MM Token Unlock ',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.black,
                                  ),
                                ),
                                Image.asset(
                                  'images/lets-icons_up.png',
                                  width: screenWidth * 0.04,
                                  height: screenWidth * 0.04,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Image.asset(
                                  'images/noto_fire.png',
                                  width: screenWidth * 0.04,
                                  height: screenWidth * 0.04,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Image.asset(
                                  'images/noto_crown.png',
                                  width: screenWidth * 0.04,
                                  height: screenWidth * 0.04,
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '95% | 20k votes ',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontSize: screenWidth * 0.04,
                                    color: Colors.black,
                                  ),
                                ),
                                Stack(
                                  children: [
                                    Container(
                                      width: screenWidth * 0.08,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0000FF),
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                    ),
                                    Container(
                                      width: screenWidth * 0.16,
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
                                  onTap: toggleDropDown,
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
                                  child: const Text(
                                    'Bitcoin (BTC) is the most traded cryptocurrency in the market giving it a high market cap, and also best to invest in.',
                                    softWrap: true,
                                    style: TextStyle(
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
                      Column(
                        children: [
                          Image.asset(
                            'images/Thumbs-up.png',
                            width: screenWidth * 0.07,
                            height: screenWidth * 0.07,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Image.asset(
                            'images/Thumbs-down.png',
                            width: screenWidth * 0.07,
                            height: screenWidth * 0.07,
                            fit: BoxFit.cover,
                          ),
                        ],
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

  Widget filterContents(String text, ValueNotifier<bool> notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, varName, _) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inconsolata',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        notifier.value = !notifier.value;
                      },
                      child: Image.asset(
                        varName
                            ? 'images/material-symbols_arrow-drop-down-upwards.png'
                            : 'images/material-symbols_arrow-drop-down.png',
                      ),
                    ),
                  ],
                ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget filterContents2(String text, ValueNotifier<bool> notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, varName, _) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          text,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inconsolata',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          notifier.value = !notifier.value;
                        },
                        child: Image.asset(
                          varName
                              ? 'images/material-symbols_arrow-drop-down-upwards.png'
                              : 'images/material-symbols_arrow-drop-down.png',
                        ),
                      ),
                    ],
                  ),
                ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (varName)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Empty List',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inconsolata',
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
