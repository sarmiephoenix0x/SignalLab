import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:path/path.dart' as path;
import 'package:signal_app/main_app.dart';

class EditProfile extends StatefulWidget {
  final String profileImgUrl;
  final String name;
  final Function(bool) onToggleDarkMode;
  final bool isDarkMode;

  const EditProfile(
      {super.key,
      required this.profileImgUrl,
      required this.name,
      required this.onToggleDarkMode,
      required this.isDarkMode});

  @override
  // ignore: library_private_types_in_public_api
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> with WidgetsBindingObserver {
  final FocusNode _displayNameFocusNode = FocusNode();

  final TextEditingController displayNameController = TextEditingController();
  bool isLoading = false;
  String _profileImage = '';
  final storage = const FlutterSecureStorage();
  final double maxWidth = 360;
  final double maxHeight = 360;
  final ImagePicker _picker = ImagePicker();
  Country? _selectedCountry;
  String phoneNumber = '';
  bool dropDownTapped = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _profileImage = widget.profileImgUrl;
    displayNameController.text = widget.name;
    super.initState();
  }

  Future<void> _selectImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      final decodedImage =
          await decodeImageFromList(imageFile.readAsBytesSync());

      if (decodedImage.width > maxWidth || decodedImage.height > maxHeight) {
        var cropper = ImageCropper();
        CroppedFile? croppedImage = await cropper.cropImage(
            sourcePath: imageFile.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Image',
                toolbarColor: Colors.black,
                toolbarWidgetColor: Colors.white,
                lockAspectRatio: false,
              ),
              IOSUiSettings(
                minimumAspectRatio: 1.0,
              ),
            ]);

        if (croppedImage != null) {
          setState(() {
            _profileImage = croppedImage.path;
          });
        }
      } else {
        // Image is within the specified resolution, no need to crop
        setState(() {
          _profileImage = pickedFile.path;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    final String name = displayNameController.text.trim();
    if (name.isEmpty ||
        _selectedCountry == null ||
        phoneNumber.isEmpty ||
        _profileImage.isEmpty) {
      String errorMessage = '';

      if (name.isEmpty) {
        errorMessage += 'Please provide your name.\n';
      }
      if (_selectedCountry == null) {
        errorMessage += 'Please select your country.\n';
      }
      if (phoneNumber.isEmpty) {
        errorMessage += 'Please provide your phone number.\n';
      }
      if (_profileImage.isEmpty || _profileImage.startsWith('http')) {
        errorMessage += 'Please select a profile image.\n';
      }

      // Show combined error message
      _showCustomSnackBar(
        context,
        errorMessage.trim(),
        isError: true,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      // Show a message if validation fails
      _showCustomSnackBar(
        context,
        'Please provide a valid phone number.',
        isError: true,
      );
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      if (accessToken == null) {
        throw Exception("No access token found.");
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://signal.payguru.com.ng/api/update-profile'),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add name to the request if it's provided
      if (name.isNotEmpty) {
        request.fields['name'] = name;
      }

      // Check if _selectedCountry is not null and has a valid displayName
      if (_selectedCountry != null &&
          _selectedCountry!.displayName.isNotEmpty) {
        request.fields['country'] = _selectedCountry!.displayName;
      }

      // Check if phoneNumber is not empty
      if (phoneNumber.isNotEmpty) {
        request.fields['phone_number'] = phoneNumber;
      }

      // Check if _profileImage is an HTTP URL, and only upload the image if it's from a local file
      if (_profileImage.isNotEmpty && !_profileImage.startsWith('http')) {
        File imageFile = File(_profileImage);

        // Ensure the image file exists before adding it to the request
        if (await imageFile.exists()) {
          var stream =
              http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
          var length = await imageFile.length();
          request.files.add(http.MultipartFile(
            'profile_photo',
            stream,
            length,
            filename: path.basename(imageFile.path),
          ));
        } else {
          print('Image file not found. Skipping image upload.');
        }
      } else {
        print(
            'Skipping image upload as the profile image is from an HTTP source.');
      }

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      if (response.statusCode == 200) {
        // Attempt to parse the response only if it's not empty
        if (responseData.body.isNotEmpty) {
          try {
            final Map<String, dynamic> responseBody =
                jsonDecode(responseData.body);

            _showCustomSnackBar(
              context,
              'Profile updated successfully.',
              isError: false,
            );

            // Navigate back to the main app
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => MainApp(
                      key: UniqueKey(),
                      onToggleDarkMode: widget.onToggleDarkMode,
                      isDarkMode: widget.isDarkMode)),
            );
          } catch (e) {
            print('Error parsing JSON: $e');
            print('Raw response: ${responseData.body}');
            throw FormatException("Invalid response format");
          }
        } else {
          throw FormatException("Empty response received");
        }
      } else {
        // Handle non-200 responses
        final String responseBody = responseData.body;
        if (responseBody.isNotEmpty) {
          final Map<String, dynamic> errorResponse = jsonDecode(responseBody);
          throw Exception(errorResponse['message'] ?? 'Unknown error occurred');
        } else {
          throw Exception('Unknown error occurred');
        }
      }
    } catch (e) {
      String errorMessage = 'Something went wrong. Please try again.';

      // Handle specific errors
      if (e is FormatException) {
        errorMessage = 'Invalid response from server.';
      } else if (e is http.ClientException) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e is SocketException) {
        errorMessage =
            'Unable to connect to the server. Please try again later.';
      }

      // Log the exact error for debugging
      print('Something went wrong. Error details: $e');

      // Show a professional error message to the user
      _showCustomSnackBar(
        context,
        errorMessage,
        isError: true,
      );
    } finally {
      // Stop the loading indicator
      setState(() {
        isLoading = false;
      });
    }
  }

// Custom SnackBar for better styling
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
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        print('Selected country: ${country.displayName}');
        // Store the selected country
        setState(() {
          _selectedCountry = country;
        });
      },
      countryListTheme: CountryListThemeData(
        borderRadius: BorderRadius.circular(40),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
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
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.1),
                          const Spacer(),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Center(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(55),
                            child: Container(
                              width: (111 / MediaQuery.of(context).size.width) *
                                  MediaQuery.of(context).size.width,
                              height:
                                  (111 / MediaQuery.of(context).size.height) *
                                      MediaQuery.of(context).size.height,
                              color: Colors.grey,
                              child: _profileImage.isEmpty
                                  ? Image.asset(
                                      'images/Pexels Photo by 3Motional Studio.png',
                                      fit: BoxFit.cover,
                                    )
                                  : (_profileImage.startsWith('http')
                                      ? Image.network(
                                          _profileImage,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons
                                                .error); // Show an error icon if image fails to load
                                          },
                                        )
                                      : Image.file(
                                          File(_profileImage),
                                          fit: BoxFit.cover,
                                        )),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () {
                                _selectImage();
                              },
                              child: Image.asset(
                                height: 40,
                                'images/profile_edit.png',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextFormField(
                        controller: displayNameController,
                        focusNode: _displayNameFocusNode,
                        style: const TextStyle(
                          fontSize: 16.0,
                          decoration: TextDecoration.none,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Inter',
                            fontSize: 12.0,
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        cursorColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.flag_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: const Text(
                        'Select a country',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => _showCountryPicker(context),
                    ),
                    if (_selectedCountry != null)
                      ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                        ),
                        title: Text(
                          _selectedCountry!.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: IntlPhoneField(
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                counterText: '',
                              ),
                              initialCountryCode: 'NG',
                              // Set initial country code
                              onChanged: (phone) {
                                setState(() {
                                  phoneNumber = phone
                                      .completeNumber; // Store the phone number
                                });
                              },
                              onCountryChanged: (country) {
                                print('Country changed to: ${country.name}');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    Container(
                      width: double.infinity,
                      height: (60 / MediaQuery.of(context).size.height) *
                          MediaQuery.of(context).size.height,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLoading == false) {
                            _updateProfile();
                          }
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
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
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
