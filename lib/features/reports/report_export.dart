import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/formatters.dart';

Future<void> exportTableToExcel({
  required String sheetName,
  required String fileName,
  required List<String> headers,
  required List<List<Object?>> rows,
}) async {
  final workbook = xls.Excel.createExcel();
  workbook.rename(workbook.getDefaultSheet()!, sheetName);
  final sheet = workbook[sheetName];

  sheet.appendRow(headers.map((h) => xls.TextCellValue(h)).toList());

  for (final row in rows) {
    sheet.appendRow(row.map((cell) {
      if (cell is num) return xls.DoubleCellValue(cell.toDouble());
      return xls.TextCellValue(cell?.toString() ?? '');
    }).toList());
  }

  final bytes = workbook.encode();
  if (bytes == null) return;

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: fileName,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
    ),
  );
}

Future<Uint8List> buildTablePdf({
  required String title,
  DateTimeRange? range,
  required List<String> headers,
  required List<List<String>> rows,
  String? footerLabel,
  String? footerValue,
}) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        if (range != null)
          pw.Text('Periode: ${formatDate(range.start)} - ${formatDate(range.end)}'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        if (footerLabel != null) ...[
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '$footerLabel: $footerValue',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}

Future<void> showTablePdfPreview(
  BuildContext context, {
  required String previewTitle,
  required Future<Uint8List> Function() build,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(previewTitle)),
        body: PdfPreview(build: (format) => build(), initialPageFormat: PdfPageFormat.a4),
      ),
    ),
  );
}
