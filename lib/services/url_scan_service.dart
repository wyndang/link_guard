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
  static String? extractLink(String text) {
    RegExp exp = RegExp(
        r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    return exp.firstMatch(text)?.group(0);
  }
}
