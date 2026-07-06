import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/formatters.dart';
import '../sales/sale_model.dart';

Future<Uint8List> buildSalesReportPdf(List<Sale> sales, {DateTimeRange? range}) async {
  final doc = pw.Document();
  final grandTotal = sales.fold<num>(0, (sum, sale) => sum + sale.total);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Text('Laporan Penjualan', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        if (range != null)
          pw.Text('Periode: ${formatDate(range.start)} - ${formatDate(range.end)}'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['No', 'Invoice', 'Tanggal', 'Pembeli', 'Kasir', 'Total'],
          data: [
            for (var i = 0; i < sales.length; i++)
              [
                '${i + 1}',
                sales[i].invoiceNo,
                formatDateTime(sales[i].createdAt),
                sales[i].customerName ?? 'Umum',
                sales[i].cashierName ?? '-',
                formatRupiah(sales[i].total),
              ],
          ],
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total: ${formatRupiah(grandTotal)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

Future<void> showSalesReportPdfPreview(
  BuildContext context,
  List<Sale> sales, {
  DateTimeRange? range,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Laporan Penjualan')),
        body: PdfPreview(
          build: (format) => buildSalesReportPdf(sales, range: range),
          initialPageFormat: PdfPageFormat.a4,
        ),
      ),
    ),
  );
}
