import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'signal_page.dart';
import 'events_page.dart';
import 'news_page.dart';
import 'course_page.dart';
import 'profile_page.dart';

class MainApp extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;

  const MainApp(
      {super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  DateTime? currentBackPressTime;
  bool _isLoading = true;

  void _onHomePageLoaded() {
    setState(() {
      _isLoading = false; // Update loading state
    });
  }

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
        body: Stack(
          children: [
            SafeArea(
              child: IndexedStack(
                index: _selectedIndex, // Keep the state of the selected index
                children: [
                  HomePage(
                    onToggleDarkMode: widget.onToggleDarkMode,
                    isDarkMode: widget.isDarkMode,
                    onLoaded: _onHomePageLoaded,
                  ),
                  const SignalPage(),
                  const EventsPage(),
                  const NewsPage(),
                  const CoursePage(),
                  UserPage(
                      onToggleDarkMode: widget.onToggleDarkMode,
                      isDarkMode: widget.isDarkMode),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const ImageIcon(AssetImage('images/ion_home.png'),
                  color: Colors.grey),
              activeIcon: ImageIcon(
                  const AssetImage('images/ion_home_active.png'),
                  color: Theme.of(context).colorScheme.onSurface),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const ImageIcon(
                  AssetImage('images/mingcute_signal-fill.png'),
                  color: Colors.grey),
              activeIcon: ImageIcon(
                  const AssetImage('images/mingcute_signal-fill_active.png'),
                  color: Theme.of(context).colorScheme.onSurface),
              label: 'Signal',
            ),
            BottomNavigationBarItem(
              icon: const ImageIcon(AssetImage('images/carbon_event.png'),
                  color: Colors.grey),
              activeIcon: ImageIcon(const AssetImage('images/carbon_event.png'),
                  color: Theme.of(context).colorScheme.onSurface),
              label: 'Events',
            ),
            BottomNavigationBarItem(
              icon: const ImageIcon(
                  AssetImage('images/iconamoon_news-thin.png'),
                  color: Colors.grey),
              activeIcon: ImageIcon(
                  const AssetImage('images/iconamoon_news-thin_active.png'),
                  color: Theme.of(context).colorScheme.onSurface),
              label: 'News',
            ),
            BottomNavigationBarItem(
              icon: const ImageIcon(
                  AssetImage('images/fluent-mdl2_publish-course.png'),
                  color: Colors.grey),
              activeIcon: ImageIcon(
                  const AssetImage(
                      'images/fluent-mdl2_publish-course_active.png'),
                  color: Theme.of(context).colorScheme.onSurface),
              label: 'Course',
            ),
            BottomNavigationBarItem(
              icon: const ImageIcon(
                  AssetImage('images/majesticons_user-line.png'),
                  color: Colors.grey),
              activeIcon: ImageIcon(
                  const AssetImage('images/majesticons_user-line_active.png'),
                  color: Theme.of(context).colorScheme.onSurface),
              label: 'User ',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.onSurface,
          onTap: (index) {
            if (_isLoading == false) {
              if (index != _selectedIndex) {
                setState(() {
                  _selectedIndex = index; // Update the selected index
                });
              }
            }
          },
        ),
      ),
    );
  }
}
