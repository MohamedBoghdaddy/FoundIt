import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeff3ff),
      appBar: AppBar(
        title: const Text(
          "Welcome to FoundIt",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF3182bd),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            child: const Text("Home", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {}, // TODO: Navigate to About screen
            child: const Text("About", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {}, // TODO: Navigate to Contact screen
            child: const Text("Contact", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 600 ? 600 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded,
                        size: 100, color: Color(0xFF3182bd)),
                    const SizedBox(height: 20),
                    const Text(
                      "Welcome to FoundIt!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2A49),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Helping the MIU community find lost items quickly & efficiently.",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        icon: const Icon(Icons.login),
                        label: const Text("Login"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3182bd),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        icon: const Icon(Icons.app_registration_rounded),
                        label: const Text("Register"),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3182bd)),
                          foregroundColor: Color(0xFF3182bd),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    const Divider(),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Who We Are",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2A49),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "FoundIt is a community-driven app built by students for students. We are a team of MIU developers passionate about solving real-life campus problems.",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "What is FoundIt?",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B2A49),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "FoundIt allows you to post about lost or found items around campus. By using smart questionnaires and matching logic, we increase the chances of finding your lost belongings or reuniting found ones with their owners.",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 60),
                    const Divider(),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: const [
                          Text("© 2025 FoundIt App - MIU",
                              style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.email, size: 16, color: Colors.grey),
                              SizedBox(width: 6),
                              Text("contact@foundit.app",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
