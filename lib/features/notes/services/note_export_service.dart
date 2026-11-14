import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import 'frontmatter_service.dart';

/// Reusable service for note exporting, formatting, PDF generation, and clipboard operations.
class NoteExportService {
  NoteExportService._();

  /// Formats note title and content as structured Markdown.
  /// Preserves YAML frontmatter (`--- ... ---`) at line 0 when present (`03` §7 P1).
  static String formatMarkdown({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    final parsed = FrontmatterService.parse(content);
    final buffer = StringBuffer();

    if (parsed.hasProperties) {
      final rawLines = content.split('\n');
      for (int i = 0; i < parsed.contentStartLineIndex && i < rawLines.length; i++) {
        buffer.writeln(rawLines[i]);
      }
      buffer.writeln();
    }

    final body = parsed.hasProperties ? parsed.bodyWithoutFrontmatter : content;
    final cleanTitle = title.trim();
    final startsWithSameH1 = cleanTitle.isNotEmpty &&
        body.trimLeft().startsWith('# ') &&
        body.trimLeft().split('\n').first.contains(cleanTitle);

    if (cleanTitle.isNotEmpty && !startsWithSameH1) {
      buffer.writeln('# $cleanTitle');
      buffer.writeln();
    }
    if (tags.isNotEmpty) {
      final missingTags = tags.where((t) => !body.contains('#$t')).toList();
      if (missingTags.isNotEmpty) {
        buffer.writeln(missingTags.map((t) => '#$t').join(' '));
        buffer.writeln();
      }
    }
    buffer.write(body);
    return buffer.toString();
  }

  /// Strips markdown syntax and checklist markers for clean plain text.
  static String formatPlainText({
    required String title,
    required String content,
  }) {
    final stripped = content
        .replaceAll(RegExp(r'[*#_~`>]'), '')
        .replaceAll(RegExp(r'\[[ xX]\]'), '•');
    if (title.trim().isEmpty) return stripped.trim();
    return '$title\n\n$stripped'.trim();
  }

  /// Copies formatted markdown string to clipboard.
  static Future<void> copyMarkdown({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final text = formatMarkdown(title: title, content: content, tags: tags);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copies stripped plain text string to clipboard.
  static Future<void> copyPlainText({
    required String title,
    required String content,
  }) async {
    final text = formatPlainText(title: title, content: content);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Shares note content using the system share sheet.
  static Future<void> shareNote({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final text = formatMarkdown(title: title, content: content, tags: tags);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: title.isNotEmpty ? title : 'Note from Tack',
      ),
    );
  }

  /// Generates a styled, multi-page stationery PDF document for a note.
  static Future<Uint8List> generatePdfBytes({
    required String title,
    required String content,
    List<String> tags = const [],
    String paletteId = 'amber',
  }) async {
    final doc = pw.Document(
      title: title.isEmpty ? 'Untitled Note' : title,
      author: 'Tack',
    );

    final palette = AppColors.getPaletteById(paletteId);
    final accentColor = PdfColor.fromInt(palette.lightColor.toARGB32());
    final textPrimary = PdfColor.fromInt(AppColors.lightTextPrimary.toARGB32());
    final textMuted = PdfColor.fromInt(AppColors.lightTextMuted.toARGB32());
    final borderColor = PdfColor.fromInt(AppColors.lightBorder.toARGB32());

    // Parse note content into structured PDF widgets
    final widgets = <pw.Widget>[];

    // Header banner
    widgets.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  title.trim().isEmpty ? 'Untitled Note' : title.trim(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              pw.Container(
                width: 14,
                height: 14,
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          // Accent stripe
          pw.Container(
            height: 3,
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.SizedBox(height: 8),
          // Tags
          if (tags.isNotEmpty)
            pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '#$tag',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                );
              }).toList(),
            ),
          pw.SizedBox(height: 16),
        ],
      ),
    );

    // Body content parsing
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      // Checklists: - [ ] or - [x]
      if (trimmed.startsWith('- [ ]') || trimmed.startsWith('- [x]') || trimmed.startsWith('- [X]')) {
        final isChecked = trimmed.startsWith('- [x]') || trimmed.startsWith('- [X]');
        final text = trimmed.substring(5).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 12,
                  height: 12,
                  margin: const pw.EdgeInsets.only(top: 2, right: 8),
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(2),
                    border: pw.Border.all(
                      color: isChecked ? accentColor : borderColor,
                      width: 1.5,
                    ),
                    color: isChecked ? accentColor : null,
                  ),
                  child: isChecked
                      ? pw.Center(
                          child: pw.Container(
                            width: 5,
                            height: 5,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: isChecked ? textMuted : textPrimary,
                      decoration: isChecked ? pw.TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Headings
      else if (trimmed.startsWith('### ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
            child: pw.Text(
              trimmed.substring(4),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textPrimary),
            ),
          ),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
            child: pw.Text(
              trimmed.substring(3),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textPrimary),
            ),
          ),
        );
      } else if (trimmed.startsWith('# ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
            child: pw.Text(
              trimmed.substring(2),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: textPrimary),
            ),
          ),
        );
      }
      // Bullet list: - or *
      else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  margin: const pw.EdgeInsets.only(top: 5, right: 8),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: accentColor,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    trimmed.substring(2),
                    style: pw.TextStyle(fontSize: 11, color: textPrimary, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Blockquote: >
      else if (trimmed.startsWith('> ')) {
        widgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
            padding: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(left: pw.BorderSide(color: accentColor, width: 3)),
              color: PdfColors.grey100,
            ),
            child: pw.Text(
              trimmed.substring(2),
              style: pw.TextStyle(
                fontSize: 10.5,
                fontStyle: pw.FontStyle.italic,
                color: textPrimary,
              ),
            ),
          ),
        );
      }
      // Standard paragraph
      else {
        // Render embedded images or fallback caption for PDF
        if (trimmed.startsWith('![') && trimmed.contains('](')) {
          final match = RegExp(r'!\[(.*?)\]\((.*?)\)').firstMatch(trimmed);
          final altText = match?.group(1) ?? 'Image Attachment';
          final imgPath = match?.group(2) ?? '';
          pw.Widget? imgWidget;

          if (imgPath.isNotEmpty) {
            try {
              final file = File(imgPath);
              if (file.existsSync()) {
                final bytes = file.readAsBytesSync();
                imgWidget = pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    height: 180,
                    fit: pw.BoxFit.contain,
                  ),
                );
              }
            } catch (_) {}
          }

          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderColor),
              ),
              child: imgWidget ??
                  pw.Row(
                    children: [
                      pw.Text('📷 ', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text(altText, style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: textMuted)),
                    ],
                  ),
            ),
          );
        } else {
          // Clean standard markdown tokens
          final cleanText = trimmed
              .replaceAll('**', '')
              .replaceAll('__', '')
              .replaceAll('~~', '')
              .replaceAll('`', '');
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                cleanText,
                style: pw.TextStyle(fontSize: 11, color: textPrimary, height: 1.4),
              ),
            ),
          );
        }
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          alignment: pw.Alignment.topRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'TACK NOTE',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Exported from Tack Notes',
                style: pw.TextStyle(fontSize: 8.5, color: textMuted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 8.5, color: textMuted),
              ),
            ],
          ),
        ),
        build: (context) => widgets,
      ),
    );

    return doc.save();
  }

  /// Exports and shares note as a PDF document.
  static Future<void> exportPdf({
    required String title,
    required String content,
    List<String> tags = const [],
    String paletteId = 'amber',
  }) async {
    final pdfBytes = await generatePdfBytes(
      title: title,
      content: content,
      tags: tags,
      paletteId: paletteId,
    );
    final safeName = (title.trim().isEmpty ? 'note' : title.trim())
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$safeName.pdf',
    );
  }

  /// Opens the native Android Print / Save to PDF preview sheet.
  static Future<void> printPdf({
    required String title,
    required String content,
    List<String> tags = const [],
    String paletteId = 'amber',
  }) async {
    final safeName = (title.trim().isEmpty ? 'note' : title.trim())
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await Printing.layoutPdf(
      onLayout: (format) => generatePdfBytes(
        title: title,
        content: content,
        tags: tags,
        paletteId: paletteId,
      ),
      name: '$safeName.pdf',
    );
  }

  /// Generates high-resolution PNG image bytes of a sticky note or standard note.
  static Future<Uint8List> generateImageBytes({
    required String title,
    required String content,
    List<String> tags = const [],
    String paletteId = 'amber',
    bool isSticky = false,
    bool isDark = false,
  }) async {
    const double cardWidth = 600.0;
    const double padding = 36.0;
    const double contentWidth = cardWidth - (padding * 2);

    final palette = AppColors.getPaletteById(paletteId);

    // Color definitions
    final Color bgColor = isSticky
        ? (isDark ? palette.darkColor : palette.lightColor)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface);

    final Color titleColor = isSticky
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final Color bodyColor = isSticky
        ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    final Color tagColor = palette.indexColor;

    // 1. Prepare Title Painter
    final displayTitle = title.trim().isEmpty
        ? (isSticky ? 'Sticky Note' : 'Untitled Note')
        : title.trim();

    final titlePainter = TextPainter(
      text: TextSpan(
        text: displayTitle,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: isSticky ? 24 : 26,
          fontWeight: FontWeight.w800,
          color: titleColor,
          letterSpacing: -0.5,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '...',
    )..layout(maxWidth: contentWidth);

    // 2. Prepare Content (clean basic markdown tokens for plain text display)
    final cleanContent = content
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '[Image]')
        .replaceAll(RegExp(r'\[[ xX]\]'), '•')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '')
        .trim();

    final contentPainter = TextPainter(
      text: TextSpan(
        text: cleanContent.isEmpty ? '(No content)' : cleanContent,
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: isSticky ? 16 : 15,
          fontWeight: FontWeight.w500,
          color: bodyColor,
          letterSpacing: -0.2,
          height: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: contentWidth);

    // 3. Compute Card Height
    double totalHeight = padding; // Top padding
    if (isSticky) {
      totalHeight += 24; // Extra space for top tape pin
    } else {
      totalHeight += 12; // Top accent bar
    }

    totalHeight += titlePainter.height + 14;

    if (tags.isNotEmpty && !isSticky) {
      totalHeight += 32; // Tag chips row
    }

    totalHeight += contentPainter.height + 28;
    totalHeight += 32; // Footer row
    totalHeight += padding; // Bottom padding

    // Enforce reasonable minimum bounds
    final minHeight = isSticky ? 440.0 : 380.0;
    totalHeight = math.max(totalHeight, minHeight);

    // 4. Paint to Canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, cardWidth, totalHeight));

    // Outer Background / Card Shape
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, cardWidth, totalHeight),
      const Radius.circular(24),
    );

    // Card Fill
    final bgPaint = Paint()..color = bgColor..style = PaintingStyle.fill;
    canvas.drawRRect(cardRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = isSticky
          ? (isDark ? Colors.white24 : AppColors.lightTextPrimary.withValues(alpha: 0.15))
          : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(cardRect, borderPaint);

    double currentY = padding;

    // Header decorations
    if (isSticky) {
      // Tape / Pin at top center
      final tapePaint = Paint()
        ..color = (isDark ? Colors.white.withValues(alpha: 0.25) : AppColors.lightTextPrimary.withValues(alpha: 0.18))
        ..style = PaintingStyle.fill;
      final tapeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cardWidth / 2, currentY), width: 72, height: 16),
        const Radius.circular(5),
      );
      canvas.drawRRect(tapeRect, tapePaint);
      currentY += 20;
    } else {
      // Top accent bar
      final accentPaint = Paint()..color = tagColor..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(padding, currentY, 48, 5),
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
          bottomLeft: const Radius.circular(3),
          bottomRight: const Radius.circular(3),
        ),
        accentPaint,
      );
      currentY += 16;
    }

    // Draw Title
    titlePainter.paint(canvas, Offset(padding, currentY));
    currentY += titlePainter.height + 14;

    // Draw Tags (if regular note)
    if (tags.isNotEmpty && !isSticky) {
      double tagX = padding;
      for (final tag in tags.take(4)) {
        final tagText = tag.startsWith('#') ? tag : '#$tag';
        final tagPainter = TextPainter(
          text: TextSpan(
            text: tagText,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tagColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final tagBgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(tagX, currentY, tagPainter.width + 16, 24),
          const Radius.circular(8),
        );
        final tagBgPaint = Paint()
          ..color = tagColor.withValues(alpha: 0.16)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(tagBgRect, tagBgPaint);
        tagPainter.paint(canvas, Offset(tagX + 8, currentY + 4));
        tagX += tagPainter.width + 24;
      }
      currentY += 32;
    }

    // Draw Content
    contentPainter.paint(canvas, Offset(padding, currentY));

    // Draw Footer at bottom
    final footerY = totalHeight - padding - 16;
    final dateStr = DateFormatter.formatTimestamp(DateTime.now());
    final footerPainter = TextPainter(
      text: TextSpan(
        text: '$dateStr  •  Tack ${isSticky ? "Sticky Note" : "Notes"}',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: bodyColor.withValues(alpha: 0.65),
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    footerPainter.paint(canvas, Offset(padding, footerY));

    // End Recording & Export to PNG Bytes
    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), totalHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to generate PNG image bytes');
    }
    return byteData.buffer.asUint8List();
  }

  /// Exports note or sticky note as a PNG image and opens the system share sheet.
  static Future<void> exportImage({
    required String title,
    required String content,
    List<String> tags = const [],
    String paletteId = 'amber',
    bool isSticky = false,
    bool isDark = false,
  }) async {
    final imageBytes = await generateImageBytes(
      title: title,
      content: content,
      tags: tags,
      paletteId: paletteId,
      isSticky: isSticky,
      isDark: isDark,
    );

    final tempDir = await getTemporaryDirectory();
    final safeName = (title.trim().isEmpty ? (isSticky ? 'sticky_note' : 'note') : title.trim())
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${tempDir.path}/tack_${safeName}_$timestamp.png';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: title.trim().isNotEmpty ? title : 'Exported from Tack',
      ),
    );
  }
}
