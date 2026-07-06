import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/formatters.dart';
import 'sale_model.dart';

Future<Uint8List> buildReceiptPdf(Sale sale) async {
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                'MINI ERP',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(child: pw.Text('Struk Transaksi')),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.Text('No. Invoice: ${sale.invoiceNo}'),
            pw.Text('Tanggal: ${formatDateTime(sale.createdAt)}'),
            pw.Text('Kasir: ${sale.cashierName ?? '-'}'),
            pw.Text('Pembeli: ${sale.customerName ?? 'Umum'}'),
            pw.Divider(),
            for (final item in sale.items) ...[
              pw.Text(item.productName),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${item.qty} x ${formatRupiah(item.price)}'),
                  pw.Text(formatRupiah(item.subtotal)),
                ],
              ),
              pw.SizedBox(height: 4),
            ],
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(formatRupiah(sale.total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Center(child: pw.Text('Terima kasih')),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<void> showReceiptPreview(BuildContext context, Sale sale) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Struk ${sale.invoiceNo}')),
        body: PdfPreview(
          build: (format) => buildReceiptPdf(sale),
          initialPageFormat: PdfPageFormat.roll80,
          canChangePageFormat: true,
          canDebug: false,
        ),
      ),
    ),
  );
}
