import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:signal_app/main_app.dart';

class EditProfile extends StatefulWidget {
  final String profileImgUrl;
  final String name;

  const EditProfile({
    super.key,
    required this.profileImgUrl,
    required this.name,
  });

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
        CroppedFile? croppedImage = await cropper
            .cropImage(sourcePath: imageFile.path, aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
        ], uiSettings: [
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

    if (name.isEmpty && _profileImage.isEmpty) {
      _showCustomSnackBar(
        context,
        'Please provide a name or select a profile image.',
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
        Uri.parse('https://script.teendev.dev/signal/api/update-profile'),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add name to the request if it's provided
      if (name.isNotEmpty) {
        request.fields['name'] = name;
      }

      // Check if a profile image is provided
      if (_profileImage.isNotEmpty) {
        File imageFile = File(_profileImage);

        // Ensure the image file exists before adding it to the request
        if (await imageFile.exists()) {
          var stream = http.ByteStream(
            DelegatingStream.typed(imageFile.openRead()),
          );
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
                  builder: (context) => MainApp(key: UniqueKey())),
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
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 22.0,
                              color: Colors.black,
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
                            borderSide: const BorderSide(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        cursorColor: Colors.black,
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
