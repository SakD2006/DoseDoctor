import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../patient/scan_patient_screen.dart'; // Replace with your actual QR scanner screen implementation.
import '../auth/login_screen.dart'; // Ensure this path is correct

class HomeScreen extends StatelessWidget {
  final String doctorName;
  final String doctorId;

  const HomeScreen({Key? key, required this.doctorName, required this.doctorId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello, $doctorName! 👨🏽‍⚕️',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Sign out the user
                await FirebaseAuth.instance.signOut();
                // Navigate to the LoginScreen after sign out
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
      // Floating button aligned to lower right for QR scanning.
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QrScannerScreen(doctorName: doctorName),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
