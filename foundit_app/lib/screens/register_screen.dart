import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Please wait...")));
        } else if (state is OtpSent) {
          setState(() => otpSent = true);
          startCountdown();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("OTP sent to $email")));
        } else if (state is OtpVerified) {
          setState(() => otpVerified = true);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("OTP Verified!")));
        } else if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registered Successfully")));
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFeff3ff),
        appBar: AppBar(
          title: const Text("Register"),
          centerTitle: true,
          backgroundColor: const Color(0xFF3182bd),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: _buildProfileImage(),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "First Name"),
                      validator: (val) =>
                          val != null && val.trim().isNotEmpty ? null : "Enter first name",
                      onChanged: (val) => firstName = val.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Last Name"),
                      validator: (val) =>
                          val != null && val.trim().isNotEmpty ? null : "Enter last name",
                      onChanged: (val) => lastName = val.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "MIU Email"),
                      validator: (val) =>
                          val != null && val.endsWith('@miuegypt.edu.eg')
                              ? null
                              : "Enter a valid MIU email",
                      onChanged: (val) => email = val.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      validator: (val) => val != null && val.length >= 6
                          ? null
                          : "Password must be at least 6 characters",
                      onChanged: (val) => password = val.trim(),
                    ),
                    const SizedBox(height: 20),
                    if (otpSent)
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Enter OTP"),
                        onChanged: (val) => otp = val.trim(),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: canResendOtp
                          ? () {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthCubit>().sendOtp(email);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3182bd),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: Text(
                        canResendOtp
                            ? "Send OTP"
                            : "Resend OTP in $countdownSeconds s",
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (otpSent && !otpVerified)
                      ElevatedButton(
                        onPressed: () =>
                            context.read<AuthCubit>().verifyOtp(email, otp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6baed6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text("Verify OTP"),
                      ),
                    if (otpVerified)
                      ElevatedButton(
                        onPressed: () => context.read<AuthCubit>().register(
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text("Register"),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
