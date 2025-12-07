/// URL scanning service using Google Safe Browsing API
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class UrlScanService {
  static const String _apiKey = "AIzaSyCblqIrEpozkWbxDj9emCqGbiPe1Oe0MG8";
  static const String _endpoint =
      'https://safebrowsing.googleapis.com/v4/threatMatches:find';

  /// Check URL with Google Safe Browsing API
  /// Returns [ScanStatus] indicating if URL is safe, malicious, or unknown
  static Future<ScanStatus> checkUrl(String url) async {
    // Validate that URL is actually a URL before checking
    if (!isValidUrl(url)) {
      print("Invalid URL format: $url");
      return ScanStatus.unknown;
    }

    final endpoint = Uri.parse('$_endpoint?key=$_apiKey');

    final body = jsonEncode({
      "client": {"clientId": "LinkGuard", "clientVersion": "1.0"},
      "threatInfo": {
        "threatTypes": [
          "MALWARE",
          "SOCIAL_ENGINEERING",
          "UNWANTED_SOFTWARE",
          "POTENTIALLY_HARMFUL_APPLICATION"
        ],
        "platformTypes": ["ANY_PLATFORM"],
        "threatEntryTypes": ["URL"],
        "threatEntries": [
          {"url": url}
        ]
      }
    });

    try {
      final response = await http.post(
        endpoint,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["matches"] == null ? ScanStatus.safe : ScanStatus.malicious;
      } else {
        print("GSB API Error: ${response.statusCode} ${response.body}");
        return ScanStatus.unknown;
      }
    } catch (e) {
      print("GSB Exception: $e");
      return ScanStatus.unknown;
    }
  }

  /// Extract link from text using regex pattern
  /// Supports URLs with or without protocol
  static String? extractLink(String text) {
    // More comprehensive regex for URL detection
    RegExp exp = RegExp(
      r'(?:(?:https?|ftp):\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&/=]*)',
      caseSensitive: false,
    );
    return exp.firstMatch(text)?.group(0);
  }

  /// Check if string is a valid URL
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      // Must have a scheme (http, https, ftp, etc.) or look like a URL
      if (!url.contains('://') && !url.contains('.')) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Normalize URL by adding https:// if no scheme is present
  static String normalizeUrl(String url) {
    String trimmed = url.trim();
    if (!trimmed.contains('://')) {
      // Check if it looks like a URL (contains domain)
      if (trimmed.contains('.')) {
        return 'https://$trimmed';
      }
    }
    return trimmed;
  }

  /// Check if input is a link (either as-is or extractable from text)
  /// Returns normalized URL if it's a link, null otherwise
  static String? detectAndNormalizeLink(String input) {
    String trimmed = input.trim();

    // First, try to parse as direct URL
    if (isValidUrl(trimmed)) {
      return normalizeUrl(trimmed);
    }

    // If not, try to extract link from text
    String? extracted = extractLink(trimmed);
    if (extracted != null && extracted.isNotEmpty) {
      return normalizeUrl(extracted);
    }

    return null;
  }
}
