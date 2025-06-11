import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _cloudinaryUploadUrl =
      "https://api.cloudinary.com/v1_1/djl6rkmex/image/upload";
  final String _uploadPreset = "foundit_unsigned";

  /// 🔐 Send OTP by storing in Firestore
  Future<void> sendFirebaseOtp(String email) async {
    final otp = _generateOtp();

    await _firestore.collection('otp_codes').doc(email).set({
      'otp': otp,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print('Generated OTP for $email: $otp');
  }

  /// 📩 Verify OTP stored in Firestore
  Future<bool> verifyOtp(String email, String inputOtp) async {
    final doc = await _firestore.collection('otp_codes').doc(email).get();
    if (!doc.exists) return false;

    final savedOtp = doc.data()!['otp'];
    return savedOtp == inputOtp;
  }

  /// ✅ Upload profile image (Mobile)
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(_cloudinaryUploadUrl))
        ..fields['upload_preset'] = _uploadPreset
        ..fields['public_id'] = "profile_images/$userId"
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);

      if (response.statusCode != 200) throw data['error']['message'];
      return data['secure_url'];
    } catch (e) {
      print('Cloudinary file upload error: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  /// ✅ Upload profile image (Web)
  Future<String> uploadProfileBytes(Uint8List bytes, String userId) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(_cloudinaryUploadUrl))
            ..fields['upload_preset'] = _uploadPreset
            ..fields['public_id'] = "profile_images/$userId"
            ..files.add(http.MultipartFile.fromBytes('file', bytes,
                filename: '$userId.jpg'));

      final response = await request.send();
      final res = await http.Response.fromStream(response);
      final data = jsonDecode(res.body);

      if (response.statusCode != 200) throw data['error']['message'];
      return data['secure_url'];
    } catch (e) {
      print('Cloudinary byte upload error: $e');
      throw Exception('Image upload failed: $e');
    }
  }

  /// ✅ Register user and store profile in Firestore
  Future<void> registerUser(
    String email,
    String password,
    String firstName,
    String lastName, {
    String? imageUrl,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'roles': {'finder': true, 'seeker': true},
      'createdAt': Timestamp.now(),
      'firstName': firstName,
      'lastName': lastName,
      'imageUrl':
          imageUrl ?? 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
    });
  }

  /// 🔓 Login user
  Future<void> loginUser(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 🚪 Logout user
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  /// 📧 Reset password via email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 🔁 Generate 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}
