import 'package:flutter/material.dart';
import 'package:signal_app/events_details.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> with TickerProviderStateMixin {
  TabController? tabController;
  Color _indicatorColor = const Color(0xFFFF0000);
  bool tabTapped = false;
  String trendImg = 'images/lets-icons_up-white.png';

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 8, vsync: this);
    tabController!.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      switch (tabController!.index) {
        case 0:
          _indicatorColor = const Color(0xFFFF0000);
          trendImg = 'images/lets-icons_up-white.png';
          break;
        case 1:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          break;
        case 2:
          _indicatorColor = const Color(0xFFB65C18);
          trendImg = 'images/lets-icons_up.png';
          break;
        default:
          _indicatorColor = Colors.black;
          trendImg = 'images/lets-icons_up.png';
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
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
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.02),
                          const Text(
                            'Events',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          Image.asset('images/PlusButton.png'),
                          Image.asset('images/SearchButton.png'),
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
                        children: [
                          ListView(
                            children: [
                              cryptoCard(),
                            ],
                          ),
                          ListView(
                            children: [
                              cryptoCard(),
                            ],
                          ),
                          ListView(
                            children: [
                              cryptoCard(),
                            ],
                          ),
                          ListView(
                            children: [
                              cryptoCard(),
                            ],
                          ),
                          ListView(
                            children: [
                              cryptoCard(),
                            ],
                          ),
                          ListView(
                            children: [
                              cryptoCard(),
                            ],
                          ),
                          ListView(
                            children: [
                              cryptoCard(),
                            ],
                          ),
                          ListView(
                            children: [
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
            _buildCurvedTab('Hot', 'images/noto_fire.png'),
            _buildCurvedTab('Significant', 'images/noto_crown.png'),
            _buildCurvedTab('Top 100 coins', ''),
            _buildCurvedTab('Top 300 coins', ''),
            _buildCurvedTab('Top 500 coins', ''),
            _buildCurvedTab('Major categories', ''),
            _buildCurvedTab('Next 10 days', ''),
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

  Widget cryptoCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventsDetails(key: UniqueKey()),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12.0),
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
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'images/logos_bitcoin.png',
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bitcoin (BTC)',
                        style: TextStyle(
                          fontFamily: 'Inconsolata',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        '18 August 2024',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inconsolata',
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      Row(
                        children: [
                          const Text(
                            '151MM Token Unlock ',
                            style: TextStyle(
                              fontFamily: 'Inconsolata',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          Image.asset(
                            'images/lets-icons_up.png',
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01),
                          Image.asset(
                            'images/noto_fire.png',
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.01),
                          Image.asset(
                            'images/noto_crown.png',
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '95% | 20k votes ',
                            style: TextStyle(
                              fontFamily: 'Inconsolata',
                              fontSize: 15,
                              color: Colors.black,
                            ),
                          ),
                          Stack(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.1,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0000FF),
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.2,
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
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                    child: Column(
                      children: [
                        Image.asset(
                          'images/Thumbs-up.png',
                        ),
                        const Spacer(),
                        Image.asset(
                          'images/Thumbs-down.png',
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
  }
}
