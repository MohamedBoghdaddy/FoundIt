import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  String email = '';
  String password = '';

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                validator: (val) =>
                    val != null && val.length >= 6 ? null : "Invalid password",
                onChanged: (val) => password = val.trim(),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => isLoading = true);
                          try {
                            await _authService.loginUser(email, password);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Login Successful")),
                            );

                            Navigator.pushReplacementNamed(context, '/home');
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Login Failed: $e")),
                            );
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        }
                      },
                      child: const Text("Login"),
                    ),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text("Don’t have an account? Register here."),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
