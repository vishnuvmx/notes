import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';

/// Reusable service for note exporting, formatting, PDF generation, and clipboard operations.
class NoteExportService {
  NoteExportService._();

  /// Formats note title and content as structured Markdown.
  static String formatMarkdown({
    required String title,
    required String content,
    List<String> tags = const [],
  }) {
    final buffer = StringBuffer();
    if (title.trim().isNotEmpty) {
      buffer.writeln('# $title');
      buffer.writeln();
    }
    if (tags.isNotEmpty) {
      buffer.writeln(tags.map((t) => '#$t').join(' '));
      buffer.writeln();
    }
    buffer.write(content);
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
        // Strip images for PDF or render caption
        if (trimmed.startsWith('![') && trimmed.contains('](')) {
          final altMatch = RegExp(r'!\[(.*?)\]').firstMatch(trimmed);
          final altText = altMatch?.group(1) ?? 'Image Attachment';
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Row(
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
}
