import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String email = '';
  String password = '';
  String otp = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                    ? () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            await _authService.sendFirebaseOtp(email);
                            setState(() => otpSent = true);
                            startCountdown();

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("OTP sent to $email")),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error sending OTP: $e")),
                            );
                          }
                        }
                      }
                    : null,
                child: Text(canResendOtp
                    ? "Send OTP"
                    : "Resend OTP in $countdownSeconds s"),
              ),
              const SizedBox(height: 10),
              if (otpSent && !otpVerified)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final isValid = await _authService.verifyOtp(email, otp);
                      if (!isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invalid OTP")),
                        );
                        return;
                      }

                      setState(() => otpVerified = true);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("OTP Verified!")),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error verifying OTP: $e")),
                      );
                    }
                  },
                  child: const Text("Verify OTP"),
                ),
              if (otpVerified)
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _authService.registerUser(email, password);

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Registered Successfully")),
                      );

                      Navigator.pushReplacementNamed(context, '/home');
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },
                  child: const Text("Register"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
