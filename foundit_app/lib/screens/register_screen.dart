import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:foundit_app/features/auth/bloc/auth_cubit.dart';
import 'package:foundit_app/features/auth/bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String firstName = '';
  String lastName = '';
  String email = '';
  String password = '';
  String otp = '';

  File? _profileImageFile;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  bool otpSent = false;
  bool otpVerified = false;
  bool canResendOtp = true;

  Timer? countdownTimer;
  int countdownSeconds = 30;

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
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        _showImagePreviewDialog(imageBytes: bytes);
      } else {
        _showImagePreviewDialog(imageFile: File(image.path));
      }
    }
  }

  void _showImagePreviewDialog({File? imageFile, Uint8List? imageBytes}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Preview Profile Image"),
          content: SizedBox(
            height: 200,
            width: 200,
            child: imageFile != null
                ? Image.file(imageFile, fit: BoxFit.cover)
                : Image.memory(imageBytes!, fit: BoxFit.cover),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage();
              },
              child: const Text("Choose Another"),
            ),
            ElevatedButton(
              onPressed: () {
                if (imageFile != null) {
                  setState(() => _profileImageFile = imageFile);
                } else {
                  setState(() => _profileImageBytes = imageBytes);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Use This Image"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileImage() {
    if (kIsWeb && _profileImageBytes != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: MemoryImage(_profileImageBytes!),
      );
    } else if (!kIsWeb && _profileImageFile != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_profileImageFile!),
      );
    } else {
      return const CircleAvatar(
        radius: 50,
        child: Icon(Icons.camera_alt, size: 50),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
      ),
      errorStyle: const TextStyle(
        color: Colors.yellow,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        } else if (state is OtpSent) {
          Navigator.pop(context);
          setState(() => otpSent = true);
          startCountdown();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("OTP sent to $email")));
        } else if (state is OtpVerified) {
          Navigator.pop(context);
          setState(() => otpVerified = true);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("OTP Verified!")));
        } else if (state is AuthSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registered Successfully")));
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthError) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0C4DA1),
                    Color(0xFF1C5DB1),
                    Color(0xFF2979D1),
                    Color(0xFF4090E3),
                  ],
                ),
              ),
            ),

            // Form Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                child: Column(
                  children: [
                    Image.asset('assets/Images/MIULogo.png', height: 120)
                        .animate()
                        .fadeIn(),
                    const SizedBox(height: 20),
                    Text(
                      "Create Your Account",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 10),
                    Text(
                      "Use your official MIU email",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: _buildProfileImage(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration:
                                  _inputDecoration("First Name", Icons.person),
                              style: const TextStyle(color: Colors.white),
                              validator: (val) =>
                                  val != null && val.trim().isNotEmpty
                                      ? null
                                      : "Enter first name",
                              onChanged: (val) => firstName = val.trim(),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration: _inputDecoration(
                                  "Last Name", Icons.person_outline),
                              style: const TextStyle(color: Colors.white),
                              validator: (val) =>
                                  val != null && val.trim().isNotEmpty
                                      ? null
                                      : "Enter last name",
                              onChanged: (val) => lastName = val.trim(),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration:
                                  _inputDecoration("MIU Email", Icons.email),
                              style: const TextStyle(color: Colors.white),
                              validator: (val) => val != null &&
                                      val.endsWith('@miuegypt.edu.eg')
                                  ? null
                                  : "Enter a valid MIU email",
                              onChanged: (val) => email = val.trim(),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              obscureText: true,
                              decoration:
                                  _inputDecoration("Password", Icons.lock),
                              style: const TextStyle(color: Colors.white),
                              validator: (val) => val != null && val.length >= 6
                                  ? null
                                  : "Password must be at least 6 characters",
                              onChanged: (val) => password = val.trim(),
                            ),
                            const SizedBox(height: 20),
                            if (otpSent)
                              TextFormField(
                                decoration:
                                    _inputDecoration("Enter OTP", Icons.shield),
                                style: const TextStyle(color: Colors.white),
                                onChanged: (val) => otp = val.trim(),
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: canResendOtp
                                  ? () {
                                      if (_formKey.currentState!.validate()) {
                                        context
                                            .read<AuthCubit>()
                                            .sendOtp(email);
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C4DA1),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                              child: Text(
                                canResendOtp
                                    ? "Send OTP"
                                    : "Resend OTP in $countdownSeconds s",
                              ),
                            ),
                            if (otpSent && !otpVerified)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ElevatedButton(
                                  onPressed: () => context
                                      .read<AuthCubit>()
                                      .verifyOtp(email, otp),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6baed6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                  ),
                                  child: const Text("Verify OTP"),
                                ),
                              ),
                            if (otpVerified)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ElevatedButton(
                                  onPressed: () =>
                                      context.read<AuthCubit>().register(
                                            email: email,
                                            password: password,
                                            firstName: firstName,
                                            lastName: lastName,
                                            imageFile: _profileImageFile,
                                            imageBytes: _profileImageBytes,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                  ),
                                  child: const Text("Register"),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
