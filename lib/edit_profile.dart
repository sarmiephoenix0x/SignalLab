import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signal_app/main_app.dart';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';

class EditProfile extends StatefulWidget {
  final String profileImgUrl;

  const EditProfile({
    super.key,
    required this.profileImgUrl,
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

    // Check if name is empty or profile image is not selected
    if (name.isEmpty || _profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Make sure you've selected an image and filled in a name"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final String? accessToken = await storage.read(key: 'accessToken');
      File imageFile = File(_profileImage);
      var stream =
      http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
      var length = await imageFile.length();

      if (accessToken == null) {
        throw Exception("No access token found.");
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://script.teendev.dev/signal/api/update-profile'),
      );

      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['name'] = name;

      // Add profile image to the request
      request.files.add(http.MultipartFile('profile_photo', stream, length,
          filename: path.basename(imageFile.path)));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to the main app
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainApp(key: UniqueKey())),
        );
      } else {
        // Parse error message from the response
        final Map<String, dynamic> errorResponse = jsonDecode(responseData.body);
        throw Exception(errorResponse['message'] ?? 'Unknown error occurred');
      }
    } catch (e) {
      // Handle any exceptions and display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Always stop the loading indicator, even if an error occurs
      setState(() {
        isLoading = false;
      });
    }
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
                          if (_profileImage.isEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(55),
                              child: Container(
                                width:
                                    (111 / MediaQuery.of(context).size.width) *
                                        MediaQuery.of(context).size.width,
                                height:
                                    (111 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                color: Colors.grey,
                                child: Image.asset(
                                  'images/Pexels Photo by 3Motional Studio.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(55),
                              child: Container(
                                width:
                                    (111 / MediaQuery.of(context).size.width) *
                                        MediaQuery.of(context).size.width,
                                height:
                                    (111 / MediaQuery.of(context).size.height) *
                                        MediaQuery.of(context).size.height,
                                color: Colors.grey,
                                child: Image.file(
                                  File(_profileImage),
                                  fit: BoxFit.cover,
                                ),
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
