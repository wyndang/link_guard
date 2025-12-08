/// QR Code scanner screen using mobile_scanner
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Real-time QR code scanner using mobile_scanner plugin
class RealQRScannerScreen extends StatefulWidget {
  const RealQRScannerScreen({super.key});

  @override
  State<RealQRScannerScreen> createState() => _RealQRScannerScreenState();
}

class _RealQRScannerScreenState extends State<RealQRScannerScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
        backgroundColor: Colors.black,
      ),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          returnImage: false,
        ),
        onDetect: (capture) {
          // Prevent multiple scans
          if (_scanned) return;

          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            _scanned = true;

            // Defer navigation to next frame to avoid locking issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pop(context, code);
              }
            });
          }
        },
      ),
    );
  }
}
