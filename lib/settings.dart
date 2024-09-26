import 'package:flutter/material.dart';
import 'change_password.dart';

class AccountSettings extends StatefulWidget {

  const AccountSettings({
    super.key,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings>
    with WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                height: orientation == Orientation.portrait
                    ? MediaQuery
                    .of(context)
                    .size
                    .height * 1
                    : MediaQuery
                    .of(context)
                    .size
                    .height * 1.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Image.asset(
                              'images/tabler_arrow-back.png',height:50,
                            ),
                          ),
                          const Spacer(),
                          const Expanded(
                            flex: 10,
                            child: Text(
                              'Account Settings',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width * 0.1),
                          const Spacer(),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery
                            .of(context)
                            .size
                            .height) *
                            MediaQuery
                                .of(context)
                                .size
                                .height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.02),
                            Image.asset(
                              'images/streamline_user-profile-focus-black.png',
                            ),
                            SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.04),
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
                    ),
                    SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.05),
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
                          height: (50 / MediaQuery
                              .of(context)
                              .size
                              .height) *
                              MediaQuery
                                  .of(context)
                                  .size
                                  .height,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width *
                                      0.02),
                              Image.asset(
                                'images/ep_edit-black.png',
                              ),
                              SizedBox(
                                  width: MediaQuery
                                      .of(context)
                                      .size
                                      .width *
                                      0.04),
                              const Text(
                                'Change Password',
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
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery
                            .of(context)
                            .size
                            .height) *
                            MediaQuery
                                .of(context)
                                .size
                                .height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.02),
                            Image.asset(
                              'images/mdi_about.png',
                            ),
                            SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.04),
                            const Text(
                              'About',
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
                    ),
                    SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery
                            .of(context)
                            .size
                            .height) *
                            MediaQuery
                                .of(context)
                                .size
                                .height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.02),
                            Image.asset(
                              'images/ic_baseline-privacy-tip.png',
                            ),
                            SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.04),
                            const Text(
                              'Privacy Policy',
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
                    ),
                    SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        height: (50 / MediaQuery
                            .of(context)
                            .size
                            .height) *
                            MediaQuery
                                .of(context)
                                .size
                                .height,
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.02),
                            Image.asset(
                              'images/carbon_warning-hex.png',
                            ),
                            SizedBox(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width *
                                    0.04),
                            const Text(
                              'Terms and Conditions',
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
