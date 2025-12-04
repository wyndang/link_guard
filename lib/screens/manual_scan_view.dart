/// Manual URL scanning screen (manual, QR, gallery)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/models.dart';
import '../config/theme.dart';
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
        widget.onScan(result, AppSource.qr);
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

      final controller = MobileScannerController();
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? code = capture.barcodes.first.rawValue;
        if (code != null) {
          widget.onScan(code, AppSource.image);
        } else {
          _showError("QR Code found but empty.");
        }
      } else {
        _showError("No QR Code found in this image.");
      }
      controller.dispose();
    } on MissingPluginException {
      _showRestartWarning();
    } catch (e) {
      _showError("Error analyzing image: $e");
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
          if (_urlController.text.isNotEmpty) {
            widget.onScan(_urlController.text, AppSource.manual);
            _urlController.clear();
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
