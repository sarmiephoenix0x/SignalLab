import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password.dart';

class AccountSettings extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;

  const AccountSettings(
      {super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  // ignore: library_private_types_in_public_api
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings>
    with WidgetsBindingObserver {
  bool _darkModeMoved = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  // Load the dark mode preference from SharedPreferences
  void _loadDarkModePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeMoved = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Toggle the dark mode and save it to SharedPreferences
  void _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeMoved = value;
    });
    await prefs.setBool('isDarkMode', value);
    widget.onToggleDarkMode(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                height: orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.height * 1
                    : MediaQuery.of(context).size.height * 1.8,
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
                            child: Image.asset(
                              'images/tabler_arrow-back.png',
                              height: 50,
                            ),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 10,
                            child: Text(
                              'Settings',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.1),
                          const Spacer(),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery.of(context).size.height) *
                            MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/streamline_user-profile-focus-black.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChangePassword(key: UniqueKey()),
                            ),
                          );
                        },
                        child: Container(
                          height: (50 / MediaQuery.of(context).size.height) *
                              MediaQuery.of(context).size.height,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[900] : Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                                spreadRadius: 3,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.02),
                              Image.asset(
                                'images/ep_edit-black.png',
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.04),
                              Text(
                                'Change Password',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery.of(context).size.height) *
                            MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/mdi_about.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'About',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery.of(context).size.height) *
                            MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/ic_baseline-privacy-tip.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'Privacy Policy',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery.of(context).size.height) *
                            MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/carbon_warning-hex.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery.of(context).size.height) *
                            MediaQuery.of(context).size.height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.02),
                            Image.asset(
                              'images/tabler_brightness-filled.png',
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.04),
                            Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _darkModeMoved,
                              onChanged: _toggleDarkMode,
                            ),
                          ],
                        ),
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
