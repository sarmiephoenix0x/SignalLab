import 'package:flutter/material.dart';
import 'package:signal_app/main_app.dart';
import 'package:signal_app/sign_up_page.dart';

class SignUpOTPPage extends StatefulWidget {
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;
  const SignUpOTPPage({super.key, required this.onToggleDarkMode, required this.isDarkMode});

  @override
  _SignUpOTPPageState createState() => _SignUpOTPPageState();
}

class _SignUpOTPPageState extends State<SignUpOTPPage> {
  final int _numberOfFields = 4;
  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];
  List<String> inputs = List.generate(4, (index) => '');

  @override
  void initState() {
    super.initState();
    controllers =
        List.generate(_numberOfFields, (index) => TextEditingController());
    focusNodes = List.generate(_numberOfFields, (index) => FocusNode());
    focusNodes[0].requestFocus(); // Focus on the first field initially

    // for (var i = 0; i < _numberOfFields; i++) {
    //   controllers[i].addListener(() => onKeyPressed(controllers[i].text, i));
    // }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void onKeyPressed(String value, int index) {
    setState(() {
      if (value.isEmpty) {
        // Handle backspace
        for (int i = inputs.length - 1; i >= 0; i--) {
          if (inputs[i].isNotEmpty) {
            inputs[i] = '';
            if (i > 0) {
              FocusScope.of(context).requestFocus(focusNodes[i - 1]);
            }
            controllers[i].selection =
                TextSelection.collapsed(offset: controllers[i].text.length);
            break;
          }
        }
      } else if (index != -1) {
        // Handle text input
        inputs[index] = value;
        controllers[index].selection =
            TextSelection.collapsed(offset: controllers[index].text.length);

        if (index < _numberOfFields - 1) {
          // Move focus to the next field
          FocusScope.of(context).requestFocus(focusNodes[index + 1]);
        }

        bool allFieldsFilled = inputs.every((element) => element.isNotEmpty);
        if (allFieldsFilled) {
          // Handle all fields filled case
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => CreateAccount_Profile_Page(
          //         key: UniqueKey(), isLoadedFromFirstPage: "false"),
          //   ),
          // );
        }
      }
    });
  }

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
                    .height
                    : MediaQuery
                    .of(context)
                    .size
                    .height * 1.5,
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
                            child: Image.asset('images/tabler_arrow-back.png',height:50,),
                          ),
                          const Spacer(),
                          Text(
                            'Sign up',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Theme.of(context).colorScheme.onSurface,
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
                        .height * 0.1),
                    Center(
                      child: Text(
                        'OTP Verification',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 22.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.03),
                    const Center(
                      child: Text(
                        "We just sent a 4 digit OTP Code",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.01),
                    const Center(
                      child: Text(
                        "Enter the OTP sent to your email",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_numberOfFields, (index) {
                        return SizedBox(
                          width: 50,
                          child: TextFormField(
                            controller: controllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            cursorColor: Theme.of(context).colorScheme.onSurface,
                            enabled: index == 0 ||
                                controllers[index - 1].text.isNotEmpty,
                            onChanged: (value) {
                              if (value.length == 1) {
                                onKeyPressed(value, index);
                              } else if (value.isEmpty) {
                                onKeyPressed(value, index);
                              }
                            },
                            onFieldSubmitted: (value) {
                              if (value.isNotEmpty) {
                                onKeyPressed(value, index);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.1),
                    const Center(
                      child: Text(
                        "Didn't receive code?",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.02),
                    Center(
                      child: Text(
                        "Resend it",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.1),
                    Container(
                      width: double.infinity,
                      height: (60 / MediaQuery
                          .of(context)
                          .size
                          .height) *
                          MediaQuery
                              .of(context)
                              .size
                              .height,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainApp(key: UniqueKey(), onToggleDarkMode: widget.onToggleDarkMode,
                                  isDarkMode: widget.isDarkMode),
                            ),
                          );
                        },
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
                          shape:
                          WidgetStateProperty.all<RoundedRectangleBorder>(
                            const RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(15)),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontFamily: 'Inter',
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
        );
      },
    );
  }
}
