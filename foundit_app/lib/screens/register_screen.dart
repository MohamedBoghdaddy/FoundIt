import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String otp = '';

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  bool otpSent = false;
  bool otpVerified = false;
  bool canResendOtp = true;

  Timer? countdownTimer;
  int countdownSeconds = 30;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  void startCountdown() {
    setState(() => canResendOtp = false);
    countdownSeconds = 30;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdownSeconds > 0) {
          countdownSeconds--;
        } else {
          canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Widget _buildTextField({
    required String label,
    required Function(String) onChanged,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        obscureText: obscure,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Register"),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? IconButton(
                              icon: const Icon(Icons.camera_alt, size: 40),
                              onPressed: _pickImage,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: "First Name",
                  onChanged: (val) => firstName = val.trim(),
                  validator: (val) =>
                      val != null && val.trim().isNotEmpty ? null : "Required",
                ),
                _buildTextField(
                  label: "Last Name",
                  onChanged: (val) => lastName = val.trim(),
                  validator: (val) =>
                      val != null && val.trim().isNotEmpty ? null : "Required",
                ),
                _buildTextField(
                  label: "MIU Email",
                  onChanged: (val) => email = val.trim(),
                  validator: (val) =>
                      val != null && val.endsWith('@miuegypt.edu.eg')
                          ? null
                          : "Use MIU email",
                ),
                _buildTextField(
                  label: "Password",
                  obscure: true,
                  onChanged: (val) => password = val.trim(),
                  validator: (val) => val != null && val.length >= 6
                      ? null
                      : "Min 6 characters",
                ),
                if (otpSent)
                  _buildTextField(
                    label: "Enter OTP",
                    onChanged: (val) => otp = val.trim(),
                  ),
                const SizedBox(height: 10),
                if (otpSent)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.verified),
                    label: Text(canResendOtp
                        ? "Send OTP"
                        : "Resend in $countdownSeconds s"),
                    onPressed: canResendOtp
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              await _authService.sendFirebaseOtp(email);
                              setState(() => otpSent = true);
                              startCountdown();
                            }
                          }
                        : null,
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _authService.sendFirebaseOtp(email);
                        setState(() => otpSent = true);
                        startCountdown();
                      }
                    },
                    child: const Text("Send OTP"),
                  ),
                const SizedBox(height: 10),
                if (otpSent && !otpVerified)
                  ElevatedButton(
                    onPressed: () async {
                      final valid = await _authService.verifyOtp(email, otp);
                      if (valid) {
                        setState(() => otpVerified = true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid OTP")),
                        );
                      }
                    },
                    child: const Text("Verify OTP"),
                  ),
                const SizedBox(height: 10),
                if (otpVerified)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("Register"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          String? imageUrl;
                          if (_profileImage != null) {
                            imageUrl = await _authService.uploadProfileImage(
                                _profileImage!, email);
                          }
                          await _authService.registerUser(
                            email,
                            password,
                            firstName,
                            lastName,
                            imageUrl: imageUrl,
                          );
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, '/home');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
