import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';// for face detection (optional)

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  File? _loginImage;

  Future<void> _pickLoginImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _loginImage = File(pickedFile.path);
      }
    });
  }

  Future<void> _loginWithImage() async {
    if (_loginImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    try {
      // Step 1: Optionally perform face detection to ensure it is a valid face image
      bool faceDetected = await _detectFaceInImage(_loginImage!);
      if (!faceDetected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No face detected in the image')),
        );
        return;
      }

      // Step 2: Upload image to Firebase Storage and get the URL
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      UploadTask uploadTask = FirebaseStorage.instance
          .ref()
          .child('login_images')
          .child(fileName)
          .putFile(_loginImage!);

      TaskSnapshot snapshot = await uploadTask;
      String uploadedImageUrl = await snapshot.ref.getDownloadURL();

      // Step 3: Compare uploaded image URL with user's stored profile image URL in Firestore
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      bool loginSuccess = false;

      for (var doc in usersSnapshot.docs) {
        String storedImageUrl = doc['profile_image'];
        if (await _compareImages(storedImageUrl, uploadedImageUrl)) {
          loginSuccess = true;
          break;
        }
      }

      if (loginSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful')),
        );
        // Navigate to your home screen or dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: Image does not match')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: $e')),
      );
    }
  }

  // Optional: Face detection function using mlkit_face_detection
  Future<bool> _detectFaceInImage(File image) async {
    // Assuming ML Kit is used for face detection
    // Implement face detection logic here
    // Return true if a face is detected, else return false
    return true;
  }

  // Example image comparison (you can replace it with more sophisticated logic)
  Future<bool> _compareImages(String imageUrl1, String imageUrl2) async {
    // Simple comparison based on URLs (for demonstration purposes)
    // Ideally, you'd use an API or more advanced logic to compare the actual image data
    return imageUrl1 == imageUrl2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login with Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _loginImage == null
                ? Text('No image selected.')
                : Image.file(_loginImage!),
            ElevatedButton(
              onPressed: _pickLoginImage,
              child: Text('Pick Login Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginWithImage,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
