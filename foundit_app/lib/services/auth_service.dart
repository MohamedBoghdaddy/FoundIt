import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    final storageRef = _storage.ref().child('profile_images/$userId.jpg');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  /// ✅ Upload profile image (Web)
  Future<String> uploadProfileBytes(Uint8List bytes, String userId) async {
    final ref = _storage.ref().child('profile_images/$userId.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
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
