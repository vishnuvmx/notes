import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reliable URL launcher with fallback to clipboard on error
class UrlLauncherHelper {
  UrlLauncherHelper._();

  static Future<void> openUrl(BuildContext context, String rawUrl) async {
    String url = rawUrl.trim();
    if (!url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('mailto:') &&
        !url.startsWith('tel:')) {
      url = 'https://$url';
    }

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    // Fallback if browser could not open
    await Clipboard.setData(ClipboardData(text: rawUrl));
    HapticFeedback.lightImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open browser. Link copied: $rawUrl'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
