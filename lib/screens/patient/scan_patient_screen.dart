import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'patient_details_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final String doctorName;
  const QrScannerScreen({super.key, required this.doctorName});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanned = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double scannerSize = screenSize.width * 0.3;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _isProcessing ? null : _toggleFlash,
              tooltip: 'Toggle Flash',
            ),
          ),
        ],
        title: const Text(
          "Scan Patient QR Code",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(150, 0, 0, 0),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // QR Scanner View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blue,
              borderRadius: 20,
              borderLength: 40,
              borderWidth: 10,
              cutOutSize: scannerSize,
              overlayColor: const Color.fromRGBO(0, 0, 0, 0.7),
            ),
          ),

          // Stylish Scan Line Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScanLinePainter(
                    progress: _scanAnimation.value,
                    cutOutSize: scannerSize,
                    screenSize: screenSize,
                  ),
                );
              },
            ),
          ),

          // Bottom controls panel with glass effect
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ).withOpacity(0.1),
                            const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ).withOpacity(0.1),
                            const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 4,
                            width: 60,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Doctor",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromARGB(
                                            179,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        widget.doctorName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(
                                            255,
                                            255,
                                            255,
                                            255,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                icon: Icons.pause_circle_outline,
                                label: "Pause",
                                color: const Color.fromARGB(255, 255, 255, 255),
                                onPressed: _isProcessing ? null : _pauseCamera,
                              ),
                              _buildActionButton(
                                icon: Icons.cancel_outlined,
                                label: "Cancel",
                                color: const Color.fromARGB(255, 255, 0, 0),
                                onPressed:
                                    _isProcessing
                                        ? null
                                        : () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading indicator with stylish design
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (context, double value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  strokeWidth: 6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade400,
                                  ),
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Processing...",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Accessing patient data",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: color.withOpacity(0.2),
            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!_isScanned && scanData.code != null) {
        _isScanned = true;
        setState(() {
          _isProcessing = true;
        });

        // Provide haptic feedback
        HapticFeedback.mediumImpact();

        final String scannedPatientId = scanData.code!;
        debugPrint('Scanned QR code data: $scannedPatientId');

        // Query Firestore to check if the patient exists
        try {
          final DocumentSnapshot patientDoc =
              await FirebaseFirestore.instance
                  .collection('patients')
                  .doc(scannedPatientId)
                  .get();

          setState(() {
            _isProcessing = false;
          });

          if (!patientDoc.exists) {
            _showNoPatientFoundDialog();
          } else {
            // Navigate to patient_details_screen with the patient data
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
        } catch (e) {
          setState(() {
            _isProcessing = false;
          });
          _showErrorDialog('Error accessing database: ${e.toString()}');
        }
      }
    });
  }

  void _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    }
  }

  void _pauseCamera() async {
    if (controller != null) {
      await controller!.pauseCamera();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => _buildStylishDialog(
              title: "Scanner Paused",
              content: "The QR scanner has been paused.",
              icon: Icons.pause_circle_outlined,
              iconColor: Colors.amber,
              actions: [
                TextButton(
                  onPressed: () {
                    controller!.resumeCamera();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Resume Scanning"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
      );
    }
  }

  void _showNoPatientFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _buildStylishDialog(
            title: "Patient Not Found",
            content: "No patient record was found with the scanned QR code.",
            icon: Icons.person_off,
            iconColor: Colors.red,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isScanned = false;
                  });
                },
                child: const Text("Try Again"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _buildStylishDialog(
            title: "Error",
            content: message,
            icon: Icons.error_outline,
            iconColor: Colors.red,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _isScanned = false;
                  });
                },
                child: const Text("OK"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildStylishDialog({
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required List<Widget> actions,
  }) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (context, double value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: iconColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller?.dispose();
    super.dispose();
  }
}

// Advanced scan line animation
class ScanLinePainter extends CustomPainter {
  final double progress;
  final double cutOutSize;
  final Size screenSize;

  ScanLinePainter({
    required this.progress,
    required this.cutOutSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scanLineWidth = cutOutSize - 20;
    final scanLineHeight = 4.0;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    final startY = centerY - cutOutSize / 2 + 10;
    final endY = centerY + cutOutSize / 2 - 10;
    final currentY = startY + (endY - startY) * progress;

    // Gradient line with glow effect
    final paint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.blue.shade200,
              Colors.blue.shade400,
              Colors.blue.shade200,
              Colors.transparent,
            ],
            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
          ).createShader(
            Rect.fromLTWH(
              centerX - scanLineWidth / 2,
              currentY,
              scanLineWidth,
              scanLineHeight,
            ),
          );

    // Draw scan line
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - scanLineWidth / 2,
        currentY,
        scanLineWidth,
        scanLineHeight,
      ),
      paint,
    );

    // Draw glow effect
    final glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.blue.shade400.withOpacity(0.5),
              Colors.blue.shade400.withOpacity(0.0),
            ],
          ).createShader(Rect.fromLTWH(centerX - 30, currentY - 30, 60, 60));

    canvas.drawCircle(Offset(centerX, currentY + 2), 30, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for corner effects
class ScannerEffectPainter extends CustomPainter {
  final double scanProgress;
  final double cutOutSize;
  final Size screenSize;
  final double rotate;

  ScannerEffectPainter({
    required this.scanProgress,
    required this.cutOutSize,
    required this.screenSize,
    required this.rotate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    final halfSize = cutOutSize / 2;

    // Calculate corner points
    final topLeft = Offset(centerX - halfSize, centerY - halfSize);
    final topRight = Offset(centerX + halfSize, centerY - halfSize);
    final bottomLeft = Offset(centerX - halfSize, centerY + halfSize);
    final bottomRight = Offset(centerX + halfSize, centerY + halfSize);

    // Corner length
    final cornerLength = cutOutSize * 0.25;

    // Create paint for corners
    final cornerPaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    // Draw animated corner effects
    _drawAnimatedCorner(canvas, topLeft, cornerLength, 0, cornerPaint);
    _drawAnimatedCorner(canvas, topRight, cornerLength, 1, cornerPaint);
    _drawAnimatedCorner(canvas, bottomRight, cornerLength, 2, cornerPaint);
    _drawAnimatedCorner(canvas, bottomLeft, cornerLength, 3, cornerPaint);

    // Draw pulsing circles at corners
    _drawPulsingCircle(canvas, topLeft, scanProgress);
    _drawPulsingCircle(canvas, topRight, (scanProgress + 0.25) % 1.0);
    _drawPulsingCircle(canvas, bottomRight, (scanProgress + 0.5) % 1.0);
    _drawPulsingCircle(canvas, bottomLeft, (scanProgress + 0.75) % 1.0);

    // Draw rotating corner indicators
    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(rotate);
    canvas.translate(-centerX, -centerY);

    final rotatingPaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final outerRadius = halfSize + 20;
    final arcLength = 3.14159 / 6; // 30 degrees in radians

    for (int i = 0; i < 4; i++) {
      final startAngle = i * 3.14159 / 2; // 90 degrees per corner
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: outerRadius * 2,
          height: outerRadius * 2,
        ),
        startAngle,
        arcLength,
        false,
        rotatingPaint,
      );
    }
    canvas.restore();
  }

  void _drawAnimatedCorner(
    Canvas canvas,
    Offset corner,
    double length,
    int cornerIndex,
    Paint paint,
  ) {
    // Stagger animation per corner
    final adjustedProgress = (scanProgress + (cornerIndex * 0.25)) % 1.0;
    final animatedPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.8),
              Colors.blue.withOpacity(0.5),
              Colors.blue.withOpacity(0.2),
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(Rect.fromLTWH(corner.dx, corner.dy, length, length))
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    // Draw horizontal line
    double hProgress = adjustedProgress < 0.5 ? adjustedProgress * 2 : 1.0;
    if (cornerIndex == 0 || cornerIndex == 3) {
      // Left corners
      canvas.drawLine(
        corner,
        Offset(corner.dx + (length * hProgress), corner.dy),
        animatedPaint,
      );
    } else {
      // Right corners
      canvas.drawLine(
        corner,
        Offset(corner.dx - (length * hProgress), corner.dy),
        animatedPaint,
      );
    }

    // Draw vertical line
    double vProgress =
        adjustedProgress >= 0.5 ? (adjustedProgress - 0.5) * 2 : 0.0;
    if (cornerIndex == 0 || cornerIndex == 1) {
      // Top corners
      canvas.drawLine(
        corner,
        Offset(corner.dx, corner.dy + (length * vProgress)),
        animatedPaint,
      );
    } else {
      // Bottom corners
      canvas.drawLine(
        corner,
        Offset(corner.dx, corner.dy - (length * vProgress)),
        animatedPaint,
      );
    }
  }

  void _drawPulsingCircle(Canvas canvas, Offset position, double progress) {
    if (progress < 0.4) {
      // Only show during part of the animation cycle
      final radius = progress * 12;
      final opacity = 0.8 - (progress * 2);

      final circlePaint =
          Paint()
            ..color = Colors.white.withOpacity(opacity > 0 ? opacity : 0)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(position, radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant ScannerEffectPainter oldDelegate) => true;
}
