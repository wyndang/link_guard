/// QR Code scanner screen using mobile_scanner
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Real-time QR code scanner using mobile_scanner plugin
class RealQRScannerScreen extends StatelessWidget {
  const RealQRScannerScreen({super.key});

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
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final String code = barcodes.first.rawValue!;
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
