import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signal_app/card_details.dart';
import 'package:signal_app/events_page.dart';
import 'package:signal_app/news_details.dart';
import 'package:signal_app/notification_page.dart';
import 'package:signal_app/packages_page.dart';
import 'package:signal_app/sentiment_page.dart';
import 'package:signal_app/transaction_history.dart';

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  DateTime? currentBackPressTime;
  int _currentBottomIndex = 0;
  TabController? homeTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _dropDownKey = GlobalKey();
  bool usdtCurrentPriceDropDownActive = false;
  bool btcCurrentPriceDropDownActive = false;

  @override
  void initState() {
    super.initState();
    homeTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    homeTab?.dispose();
    super.dispose();
  }

  void _showPopupMenu(BuildContext context) async {
    final RenderBox renderBox =
        _dropDownKey.currentContext!.findRenderObject() as RenderBox;
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
    // final posts = Provider.of<PostProvider>(context).posts;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          DateTime now = DateTime.now();
          if (currentBackPressTime == null ||
              now.difference(currentBackPressTime!) >
                  const Duration(seconds: 2)) {
            currentBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Signal Lab',
            style: TextStyle(
              fontSize: 25,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        drawer: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
          child: Drawer(
            child: Container(
              color: Colors.black, // Set your desired background color here
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.black, // Set your desired header color here
                    ),
                    padding: const EdgeInsets.fromLTRB(16.0, 36.0, 16.0, 8.0),
                    child: Row(children: [
                      Image.asset(
                        'images/ProfileImg.png',
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                      const Text(
                        'Maryland, Simone',
                        style: TextStyle(
                          fontFamily: 'GolosText',
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ]),
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/ic_round-add-card.png',
                    ),
                    title: const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Navigate to home or any action you want
                    },
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/carbon_event.png',
                    ),
                    title: const Text(
                      'Events',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventsPage(key: UniqueKey()),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/fluent-mdl2_sentiment-analysis.png',
                    ),
                    title: const Text(
                      'Sentiment',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SentimentPage(key: UniqueKey()),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/Packages-dollarsign.png',
                    ),
                    title: const Text(
                      'Packages',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PackagesPage(key: UniqueKey()),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/Referrals.png',
                    ),
                    title: const Text(
                      'Referrals',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Navigate to home or any action you want
                    },
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/solar_settings-outline.png',
                    ),
                    title: const Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Navigate to home or any action you want
                    },
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/grommet-icons_transaction.png',
                    ),
                    title: const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionHistory(key: UniqueKey()),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Image.asset(
                      'images/fluent_person-support-16-regular.png',
                    ),
                    title: const Text(
                      'Customer Support',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Navigate to home or any action you want
                    },
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(top: 16, left: 16),
                    leading: Image.asset(
                      'images/material-symbols-light_logout-sharp.png',
                    ),
                    title: const Text(
                      'Log out',
                      style: TextStyle(
                        fontFamily: 'GolosText',
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // Navigate to home or any action you want
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _tabBarView(_currentBottomIndex),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 5,
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentBottomIndex,
              selectedItemColor: Colors.black,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  _currentBottomIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/ion_home.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/ion_home_active.png'),
                    color: Colors.black,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/mingcute_signal-fill.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/mingcute_signal-fill.png'),
                    color: Colors.black,
                  ),
                  label: 'Signal',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/iconamoon_news-thin.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/iconamoon_news-thin_active.png'),
                    color: Colors.black,
                  ),
                  label: 'News',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/fluent-mdl2_publish-course.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/fluent-mdl2_publish-course_active.png'),
                    color: Colors.black,
                  ),
                  label: 'Course',
                ),
                BottomNavigationBarItem(
                  icon: ImageIcon(
                    AssetImage('images/majesticons_user-line.png'),
                    color: Colors.grey,
                  ),
                  activeIcon: ImageIcon(
                    AssetImage('images/majesticons_user-line_active.png'),
                    color: Colors.black,
                  ),
                  label: 'User',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBarView(int bottomIndex) {
    List<Widget> tabBarViewChildren = [];
    if (bottomIndex == 0) {
      tabBarViewChildren.add(
        Expanded(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                _scaffoldKey.currentState?.openDrawer();
                              },
                              child: Image.asset(
                                'images/tabler_menu_button.png',
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              'images/tabler_help.png',
                            ),
                            Image.asset(
                              'images/tabler_search.png',
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        NotificationPage(key: UniqueKey()),
                                  ),
                                );
                              },
                              child: Image.asset(
                                'images/tabler_no_notification.png',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        Row(children: [
                          Image.asset(
                            'images/ProfileImg.png',
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),
                          const Text(
                            'Maryland, Simone',
                            style: TextStyle(
                              fontFamily: 'GolosText',
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        Container(
                          height: (130 / MediaQuery.of(context).size.height) *
                              MediaQuery.of(context).size.height,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(width: 0, color: Colors.grey),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Image.asset(
                                'images/Balance.png',
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              const VerticalDivider(
                                color: Colors.grey,
                                thickness: 1.0,
                                width: 20.0,
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Balance',
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    const Text(
                                      "\$0.00",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        Container(
                          height: (130 / MediaQuery.of(context).size.height) *
                              MediaQuery.of(context).size.height,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(width: 0, color: Colors.grey),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Image.asset(
                                'images/Package.png',
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              const VerticalDivider(
                                color: Colors.grey,
                                thickness: 1.0,
                                width: 20.0,
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Package',
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    const Text(
                                      "N/A (validity)",
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        Container(
                          height: (130 / MediaQuery.of(context).size.height) *
                              MediaQuery.of(context).size.height,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(width: 0, color: Colors.grey),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Image.asset(
                                'images/Signals.png',
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              const VerticalDivider(
                                color: Colors.grey,
                                thickness: 1.0,
                                width: 20.0,
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Signals',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.02),
                                    const Text(
                                      "0",
                                      style: TextStyle(
                                        fontFamily: 'Inconsolata',
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05),
                        const Row(
                          children: [
                            Text(
                              "Educational Content",
                              style: TextStyle(
                                fontFamily: 'Golos Text',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Spacer(),
                            Text(
                              "See More",
                              style: TextStyle(
                                fontFamily: 'Golos Text',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03),
                        TabBar(
                          tabAlignment: TabAlignment.start,
                          controller: homeTab,
                          isScrollable: true,
                          tabs: [
                            _buildTab('News'),
                            _buildTab('Courses'),
                          ],
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Golos Text',
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Golos Text',
                          ),
                          labelPadding: EdgeInsets.zero,
                          indicator: const BoxDecoration(),
                          indicatorSize: TabBarIndicatorSize.label,
                          indicatorColor: Colors.orange,
                          indicatorPadding:
                              const EdgeInsets.only(left: 16.0, right: 16.0),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03),
                        SizedBox(
                          height: (400 / MediaQuery.of(context).size.height) *
                              MediaQuery.of(context).size.height,
                          child: TabBarView(
                            controller: homeTab,
                            children: [
                              GridView.count(
                                crossAxisCount: 1,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CardDetails(key: UniqueKey()),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      shadowColor: Colors.grey,
                                      margin: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Image.asset(
                                              'images/Pexels Photo by Tima Miroshnichenko.png',
                                              width: double.infinity,
                                              height:
                                                  160, // Adjust the height to leave space for text
                                              fit: BoxFit
                                                  .cover, // Ensure the image covers the space well
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'What is Forex Trading about?',
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 17.0,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                      ),
                                                      const Text(
                                                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        softWrap: true,
                                                        maxLines: 3,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                            'images/Pexels Photo by Pixabay.png',
                                                          ),
                                                          SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.01,
                                                          ),
                                                          const Expanded(
                                                            child: Text(
                                                              '[Article Writer’s Name]',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontFamily:
                                                                    'Inter',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          const Text(
                                                            '37 minutes ago',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inter',
                                                              fontSize:
                                                                  16.0, // Reduced font size to fit content
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
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
                              GridView.count(
                                crossAxisCount: 1,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CardDetails(key: UniqueKey()),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      shadowColor: Colors.grey,
                                      margin: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Image.asset(
                                              'images/Pexels Photo by Tima Miroshnichenko.png',
                                              width: double.infinity,
                                              height:
                                                  160, // Adjust the height to leave space for text
                                              fit: BoxFit
                                                  .cover, // Ensure the image covers the space well
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'What is Forex Trading about?',
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 17.0,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                      ),
                                                      const Text(
                                                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        softWrap: true,
                                                        maxLines: 3,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.01,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                            'images/Pexels Photo by Pixabay.png',
                                                          ),
                                                          SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.01,
                                                          ),
                                                          const Expanded(
                                                            child: Text(
                                                              '[Article Writer’s Name]',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontFamily:
                                                                    'Inter',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          const Text(
                                                            '37 minutes ago',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Inter',
                                                              fontSize:
                                                                  16.0, // Reduced font size to fit content
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (bottomIndex == 1) {
      tabBarViewChildren.add(
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        const Text(
                          'Signal',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 22.0,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: const Text(
                            'Results',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Container(
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
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Trades last 7 days: ----',
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Text(
                                'Win rate: ----',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Trades last 14 days: ----',
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Text(
                                'Win rate: ----',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Trades last 30 days: ----',
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Text(
                                'Win rate: ----',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Container(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
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
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Opened',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Expanded(
                                child: Text(
                                  'Jan-18, 1:40 PM',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              Image.asset(
                                'images/cryptocurrency-color_usdt.png',
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.03),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    width: 0,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: const Text(
                                  'LONG',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Inconsolata',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              const SizedBox(
                                height: 35,
                                child: VerticalDivider(
                                  color: Colors.black,
                                  thickness: 2.0,
                                ),
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              const Text(
                                'USDT',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Spacer(),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      width: 0,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'In progress',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontFamily: 'Inconsolata',
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        'images/carbon_in-progress.png',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Entry price',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Expanded(
                                child: Text(
                                  '0.14',
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Stop Loss 40.0%',
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Spacer(),
                              Expanded(
                                child: Text(
                                  '0.1',
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontFamily: 'Inconsolata',
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Current Price',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Expanded(
                                      child: Text(
                                        '0.0903',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Expanded(
                                      child: Text(
                                        '-35.5%',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inconsolata',
                                          color: Color(0xFFFF0000),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.03),
                                    if (usdtCurrentPriceDropDownActive == false)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            usdtCurrentPriceDropDownActive =
                                                true;
                                          });
                                        },
                                        child: Image.asset(
                                          'images/gridicons_dropdown.png',
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            usdtCurrentPriceDropDownActive =
                                                false;
                                          });
                                        },
                                        child: Image.asset(
                                          'images/gridicons_dropdown-upwards.png',
                                        ),
                                      ),
                                  ],
                                ),
                                if (usdtCurrentPriceDropDownActive == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          width: 0,
                                        ),
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
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Target 1',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            child: Text(
                                              '0.15',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            child: Text(
                                              '6.67%',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Color(0xFFFF0000),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (usdtCurrentPriceDropDownActive == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          width: 0,
                                        ),
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
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Target 2',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            child: Text(
                                              '0.15',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            child: Text(
                                              '6.67%',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Color(0xFFFF0000),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (usdtCurrentPriceDropDownActive == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          width: 0,
                                        ),
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
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Target 3',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            child: Text(
                                              '0.15',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Spacer(),
                                          Expanded(
                                            child: Text(
                                              '6.67%',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inconsolata',
                                                color: Color(0xFFFF0000),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      width: 0,
                                    ),
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
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'View Steps',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inconsolata',
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        'images/gridicons_dropdown.png',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      width: 0,
                                    ),
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
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'View Charts',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inconsolata',
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        'images/material-symbols_pie-chart.png',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  Container(
                    padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
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
                    child: Column(children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Opened',
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Text(
                                'Jan-18, 1:40 PM',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Image.asset(
                              'images/logos_bitcoin.png',
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.03),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 0,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: const Text(
                                'LONG',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Inconsolata',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            const SizedBox(
                              height: 35,
                              child: VerticalDivider(
                                color: Colors.black,
                                thickness: 2.0,
                              ),
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            const Text(
                              'BTC',
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Inconsolata',
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    width: 0,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'In progress',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'images/carbon_in-progress.png',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Entry price',
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Text(
                                '0.14',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Stop Loss 40.0%',
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Text(
                                '0.1',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontFamily: 'Inconsolata',
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 3,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Current Price',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inconsolata',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Expanded(
                                    child: Text(
                                      '0.0903',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inconsolata',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Expanded(
                                    child: Text(
                                      '-35.5%',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inconsolata',
                                        color: Color(0xFFFF0000),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.03),
                                  if (btcCurrentPriceDropDownActive == false)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          btcCurrentPriceDropDownActive = true;
                                        });
                                      },
                                      child: Image.asset(
                                        'images/gridicons_dropdown.png',
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          btcCurrentPriceDropDownActive = false;
                                        });
                                      },
                                      child: Image.asset(
                                        'images/gridicons_dropdown-upwards.png',
                                      ),
                                    ),
                                ],
                              ),
                              if (btcCurrentPriceDropDownActive == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        width: 0,
                                      ),
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
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Target 1',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Expanded(
                                          child: Text(
                                            '0.15',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Expanded(
                                          child: Text(
                                            '6.67%',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Color(0xFFFF0000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (btcCurrentPriceDropDownActive == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        width: 0,
                                      ),
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
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Target 2',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Expanded(
                                          child: Text(
                                            '0.15',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Expanded(
                                          child: Text(
                                            '6.67%',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Color(0xFFFF0000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (btcCurrentPriceDropDownActive == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        width: 0,
                                      ),
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
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Target 3',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Expanded(
                                          child: Text(
                                            '0.15',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Spacer(),
                                        Expanded(
                                          child: Text(
                                            '6.67%',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inconsolata',
                                              color: Color(0xFFFF0000),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    width: 0,
                                  ),
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
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'View Steps',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'images/gridicons_dropdown.png',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    width: 0,
                                  ),
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
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'View Charts',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inconsolata',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'images/material-symbols_pie-chart.png',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (bottomIndex == 2) {
      tabBarViewChildren.add(
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'News',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 20, bottom: 20.0, left: 20, right: 20),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'images/NewsProfileImg.png',
                                    ),
                                    Expanded(
                                      child: Column(
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
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01,
                                          ),
                                          const Text(
                                            'Satellites',
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
                                        key: _dropDownKey,
                                        width: 20,
                                        child: Image.asset(
                                          'images/MoreButton.png',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                const Text(
                                  "Binance Expands Account Statement Function. With our VIP and institutional clients in mind, we’ve upgraded the account statement function...",
                                  style: TextStyle(
                                      fontSize: 16, fontFamily: 'Inter'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NewsDetails(key: UniqueKey()),
                                        ),
                                      );
                                    },
                                    child: Image.asset(
                                      'images/NewsPost.png',
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Image.asset(
                                      'images/heart-line.png',
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.03,
                                    ),
                                    Image.asset(
                                      'images/message-2-line.png',
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.03,
                                    ),
                                    Image.asset(
                                      'images/share-forward-box-fill.png',
                                    ),
                                    const Spacer(),
                                    Image.asset(
                                      'images/add-circle-line.png',
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                const Text(
                                  "Liked by Huoge and others 1,900",
                                  style: TextStyle(
                                      fontSize: 16, fontFamily: 'Inter'),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Image.asset(
                                            'images/Component 1.png',
                                          ),
                                          Positioned(
                                            left: MediaQuery.of(context)
                                                    .padding
                                                    .left +
                                                20,
                                            child: Image.asset(
                                              'images/Component 2.png',
                                            ),
                                          ),
                                          Positioned(
                                            left: MediaQuery.of(context)
                                                    .padding
                                                    .left +
                                                40,
                                            child: Image.asset(
                                              'images/Component 3.png',
                                            ),
                                          ),
                                          Positioned(
                                            left: MediaQuery.of(context)
                                                    .padding
                                                    .left +
                                                60,
                                            child: Image.asset(
                                              'images/Component 4.png',
                                            ),
                                          ),
                                          Positioned(
                                            left: MediaQuery.of(context)
                                                    .padding
                                                    .left +
                                                80,
                                            child: Image.asset(
                                              'images/Component 5.png',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      child: const Text(
                                        '150 Responses',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Inter',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (bottomIndex == 3) {
      tabBarViewChildren.add(
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Courses',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: GridView.count(
                    crossAxisCount: 1,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CardDetails(key: UniqueKey()),
                            ),
                          );
                        },
                        child: Card(
                          shadowColor: Colors.grey,
                          margin: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'images/Pexels Photo by Tima Miroshnichenko.png',
                                  width: double.infinity,
                                  height:
                                      160, // Adjust the height to leave space for text
                                  fit: BoxFit
                                      .cover, // Ensure the image covers the space well
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.01,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'What is Forex Trading about?',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17.0,
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01,
                                          ),
                                          const Text(
                                            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            maxLines: 3,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.01,
                                          ),
                                          Row(
                                            children: [
                                              Image.asset(
                                                'images/Pexels Photo by Pixabay.png',
                                              ),
                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.01,
                                              ),
                                              const Expanded(
                                                child: Text(
                                                  '[Article Writer’s Name]',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              const Text(
                                                '37 minutes ago',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize:
                                                      16.0, // Reduced font size to fit content
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
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
                ),
              ),
            ],
          ),
        ),
      );
    } else if (bottomIndex == 4) {
      tabBarViewChildren.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset('images/tabler_arrow-back.png'),
                      ),
                      const Spacer(),
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 22.0,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  const Center(
                    child: Text(
                      'Maryland, Simone',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'images/weui_location-outlined.png',
                      ),
                      const Text(
                        'Address Here',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Container(
                    height: (50 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 0, color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        Image.asset(
                          'images/ep_edit-black.png',
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Container(
                    height: (50 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 0, color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        Image.asset(
                          'images/ic_round-add-card-black.png',
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Container(
                    height: (50 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 0, color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        Image.asset(
                          'images/streamline_user-profile-focus-black.png',
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Container(
                    height: (50 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 0, color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        Image.asset(
                          'images/fluent_person-support-16-regular-black.png',
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        const Text(
                          'Customer Support',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Container(
                    height: (50 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 0, color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        Image.asset(
                          'images/solar_settings-outline-black.png',
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Container(
                    height: (50 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 0, color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        Image.asset(
                          'images/Packages-dollarsign-black.png',
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        const Text(
                          'Packages',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  Container(
                    height: (50 / MediaQuery.of(context).size.height) *
                        MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(width: 0, color: Colors.black),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02),
                        Image.asset(
                          'images/material-symbols-light_logout-sharp-black.png',
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.04),
                        const Text(
                          'Log out',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tabBarViewChildren,
      ),
    );
  }

  Widget _buildTab(String name) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(name),
      ),
    );
  }
}
