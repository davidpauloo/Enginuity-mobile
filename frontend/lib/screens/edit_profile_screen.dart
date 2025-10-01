// // lib/screens/edit_profile_screen.dart
// import 'dart:io'; // For File type
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // For picking images
// import 'package:fluttertoast/fluttertoast.dart'; // For showing toasts
// import 'package:chat_app/services/auth_service.dart'; // Import AuthService and CurrentUser from here

// class EditProfileScreen extends StatefulWidget {
//   final CurrentUser currentUser; // Passed from ProfileScreen

//   const EditProfileScreen({super.key, required this.currentUser});

//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final AuthService _authService = AuthService();
//   final TextEditingController _mobileNumberController = TextEditingController();
//   File? _imageFile; // Stores the newly selected image file
//   bool _isSaving = false; // To manage loading state during save

//   @override
//   void initState() {
//     super.initState();
//     // Initialize the mobile number text field with the current user's mobile number
//     _mobileNumberController.text = widget.currentUser.mobileNumber ?? '';
//   }

//   @override
//   void dispose() {
//     _mobileNumberController.dispose();
//     super.dispose();
//   }

//   // Function to pick an image from the gallery
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path); // Set the selected image file
//       });
//     }
//   }

//   // Function to handle saving profile changes
//   Future<void> _saveProfile() async {
//     setState(() {
//       _isSaving = true; // Show loading indicator
//     });

//     try {
//       // Call AuthService to update the profile
//       // It handles uploading the image file and sending mobile number to backend
//       final CurrentUser? updatedUser =
//           await _authService.updateCurrentUserProfile(
//         mobileNumber:
//             _mobileNumberController.text.trim(), // Get trimmed mobile number
//         profilePicFile:
//             _imageFile, // Pass the selected image file (can be null)
//       );

//       // Show success toast
//       Fluttertoast.showToast(
//         msg: 'Profile updated successfully!',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.green,
//         textColor: Colors.white,
//       );

//       // If the widget is still mounted and an updated user object is returned,
//       // pop this screen and pass the updated user data back to ProfileScreen.
//       if (mounted && updatedUser != null) {
//         Navigator.pop(context, updatedUser);
//       }
//     } catch (e) {
//       // Show error toast if saving fails
//       Fluttertoast.showToast(
//         msg: 'Failed to update profile: ${e.toString()}',
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     } finally {
//       setState(() {
//         _isSaving = false; // Hide loading indicator
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Profile Picture Display and Edit Button
//             Stack(
//               children: [
//                 CircleAvatar(
//                   radius: 70,
//                   backgroundColor: Colors.blue.shade100,
//                   // Display new image file if selected, otherwise current profile pic from network
//                   backgroundImage: _imageFile != null
//                       ? FileImage(_imageFile!)
//                           as ImageProvider<Object>? // Display new file
//                       : (widget.currentUser.profilePic != null &&
//                               widget.currentUser.profilePic!.isNotEmpty
//                           ? NetworkImage(widget.currentUser
//                               .profilePic!) // Display existing network image
//                           : null), // No image, fallback to default icon
//                   child: _imageFile == null &&
//                           (widget.currentUser.profilePic == null ||
//                               widget.currentUser.profilePic!.isEmpty)
//                       ? Icon(Icons.person,
//                           size: 70,
//                           color: Colors.blue.shade700) // Default person icon
//                       : null,
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: GestureDetector(
//                     onTap: _pickImage, // Call image picker on tap
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF412ad5),
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                       child: const Icon(Icons.camera_alt,
//                           color: Colors.white, size: 20),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 30),

//             // Mobile Number TextField
//             TextField(
//               controller: _mobileNumberController,
//               keyboardType: TextInputType.phone,
//               decoration: InputDecoration(
//                 labelText: 'Mobile Number',
//                 hintText: 'Enter your mobile number',
//                 prefixIcon: const Icon(Icons.call, color: Color(0xFF412ad5)),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide:
//                       const BorderSide(color: Color(0xFF412ad5), width: 2),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Save Button
//             ElevatedButton(
//               onPressed: _isSaving
//                   ? null
//                   : _saveProfile, // Disable button while saving
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 50),
//                 backgroundColor: const Color(0xFF412ad5),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               child: _isSaving
//                   ? const CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ) // Show loading spinner
//                   : const Text(
//                       'Save Changes',
//                       style: TextStyle(fontSize: 18),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
