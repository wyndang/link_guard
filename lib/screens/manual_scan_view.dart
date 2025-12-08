/// Manual URL scanning screen (manual, QR, gallery)
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as mlkit;
import '../models/models.dart';
import '../config/theme.dart';
import '../services/url_scan_service.dart';
import 'qr_scanner_screen.dart';

/// View for manual URL scanning with QR and gallery options
class ManualScanView extends StatefulWidget {
  final Function(String, AppSource) onScan;
  final bool isWide;

  const ManualScanView({
    super.key,
    required this.onScan,
    required this.isWide,
  });

  @override
  State<ManualScanView> createState() => _ManualScanViewState();
}

class _ManualScanViewState extends State<ManualScanView> {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Open QR code scanner screen
  Future<void> _openQRScanner() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RealQRScannerScreen()),
      );

      if (result != null && result is String) {
        // Check if QR code output is a valid link
        String? link = UrlScanService.detectAndNormalizeLink(result);
        if (link != null) {
          widget.onScan(link, AppSource.qr);
        } else {
          _showError("QR Code doesn't contain a valid URL.\nContent: $result");
        }
      }
    } on MissingPluginException {
      _showRestartWarning();
    } catch (e) {
      _showError("Scanner Error: $e");
    }
  }

  /// Pick image from gallery and extract QR code
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      _showError("Processing image...");

      // Use Google MLKit for reliable QR decoding
      final barcodeScanner = mlkit.BarcodeScanner(
        formats: [mlkit.BarcodeFormat.qrCode],
      );
      final inputImage = mlkit.InputImage.fromFilePath(image.path);

      try {
        final barcodes = await barcodeScanner.processImage(inputImage);

        if (barcodes.isNotEmpty) {
          // Get first QR code detected
          final qrCode = barcodes.first.displayValue;

          if (qrCode != null && qrCode.isNotEmpty) {
            // Check if QR code output is a valid link
            final link = UrlScanService.detectAndNormalizeLink(qrCode);
            if (link != null) {
              widget.onScan(link, AppSource.image);
            } else {
              _showError("QR Code doesn't contain a valid URL.\nContent: $qrCode");
            }
          } else {
            _showError("QR code is empty.");
          }
        } else {
          _showError("No QR code found in this image.");
        }

        await barcodeScanner.close();
      } catch (e) {
        _showError("Failed to decode QR: $e");
        await barcodeScanner.close();
      }
    } on MissingPluginException {
      _showRestartWarning();
    } catch (e) {
      _showError("Error processing image: $e");
    }
  }

  void _showRestartWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Native Plugin Error: Please restart the app (Hot Restart doesn't load new plugins).",
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: Colors.white24,
          ),
          const SizedBox(height: 20),
          const Text(
            "MANUAL SCAN",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const Text(
            "Enter URL, Scan QR or Import Image",
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 40),
          _buildUrlInput(),
          const SizedBox(height: 20),
          _buildCheckButton(),
          const SizedBox(height: 20),
          _buildScanButtons(),
        ],
      ),
    );
  }

  Widget _buildUrlInput() {
    return TextField(
      controller: _urlController,
      style: const TextStyle(color: AppTheme.textLight),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        hintText: "Enter URL (https://...)",
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        prefixIcon: const Icon(Icons.link, color: AppTheme.textSecondary),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppDimensions.smallBorderRadius),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: widget.isWide ? 300 : double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_urlController.text.isEmpty) {
            _showError("Please enter a URL");
            return;
          }

          // Detect and normalize the link from input
          String? link =
              UrlScanService.detectAndNormalizeLink(_urlController.text);
          if (link != null) {
            widget.onScan(link, AppSource.manual);
            _urlController.clear();
          } else {
            _showError(
                "Invalid URL format. Please enter a valid link.");
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          "CHECK NOW",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildScanButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openQRScanner,
            icon: const Icon(Icons.camera_alt),
            label: const Text("SCAN QR"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.white30),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.image),
            label: const Text("GALLERY"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.white30),
            ),
          ),
        ),
      ],
    );
  }
}
