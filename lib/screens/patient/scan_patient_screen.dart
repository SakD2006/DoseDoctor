import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_details_screen.dart'; // Make sure this file is implemented

class QrScannerScreen extends StatefulWidget {
  final String doctorName;
  const QrScannerScreen({super.key, required this.doctorName});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanned = false; // Prevent multiple triggers

  @override
  void reassemble() {
    super.reassemble();
    // If the platform is Android, the camera should be paused/resumed properly.
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Patient QR Code")),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
        overlay: QrScannerOverlayShape(
          borderColor: const Color.fromARGB(255, 176, 255, 137),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 300,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!_isScanned && scanData.code != null) {
        _isScanned = true;
        final String scannedPatientId = scanData.code!;
        debugPrint('Scanned QR code data: $scannedPatientId');

        // Query Firestore to check if the patient exists.
        final DocumentSnapshot patientDoc =
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(scannedPatientId)
                .get();

        if (!patientDoc.exists) {
          _showNoPatientFoundDialog();
        } else {
          // Navigate to patient_details_screen with the patient data.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PatientDetailsScreen(
                    patientId: scannedPatientId,
                    patientData: patientDoc.data() as Map<String, dynamic>,
                    doctorName: widget.doctorName,
                  ),
            ),
          );
        }
      }
    });
  }

  void _showNoPatientFoundDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Patient Not Found"),
            content: const Text("No patient found with the current QR code."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog.
                  // Reset flag to allow scanning again.
                  setState(() {
                    _isScanned = false;
                  });
                },
                child: const Text("Rescan"),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
