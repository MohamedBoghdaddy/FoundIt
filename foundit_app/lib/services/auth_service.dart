import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 Send OTP by storing in Firestore
  Future<void> sendFirebaseOtp(String email) async {
    final otp = _generateOtp();

    await _firestore.collection('otp_codes').doc(email).set({
      'otp': otp,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // DEV: Show in console
    print('Generated OTP for $email: $otp');

    // PRODUCTION: Trigger backend email service or Firebase Function
  }

  /// 📩 Verify OTP stored in Firestore
  Future<bool> verifyOtp(String email, String inputOtp) async {
    final doc = await _firestore.collection('otp_codes').doc(email).get();
    if (!doc.exists) return false;

    final savedOtp = doc.data()!['otp'];
    return savedOtp == inputOtp;
  }

  /// ✅ Register user and store role flags
  Future<void> registerUser(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'roles': {'finder': true, 'seeker': true},
      'createdAt': Timestamp.now(),
    });
  }

  /// 🔁 Generate 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
    /// 🔓 Login user with email and password
  Future<void> loginUser(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
Future<void> logoutUser() async {
  await _auth.signOut();
}

}



