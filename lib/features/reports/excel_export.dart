import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:share_plus/share_plus.dart';

import '../../core/utils/formatters.dart';
import '../sales/sale_model.dart';

Future<void> exportSalesToExcel(List<Sale> sales) async {
  final workbook = xls.Excel.createExcel();
  const sheetName = 'Laporan Penjualan';
  workbook.rename(workbook.getDefaultSheet()!, sheetName);
  final sheet = workbook[sheetName];

  sheet.appendRow([
    xls.TextCellValue('No'),
    xls.TextCellValue('Invoice'),
    xls.TextCellValue('Tanggal'),
    xls.TextCellValue('Pembeli'),
    xls.TextCellValue('Kasir'),
    xls.TextCellValue('Total'),
  ]);

  for (var i = 0; i < sales.length; i++) {
    final sale = sales[i];
    sheet.appendRow([
      xls.IntCellValue(i + 1),
      xls.TextCellValue(sale.invoiceNo),
      xls.TextCellValue(formatDateTime(sale.createdAt)),
      xls.TextCellValue(sale.customerName ?? 'Umum'),
      xls.TextCellValue(sale.cashierName ?? '-'),
      xls.DoubleCellValue(sale.total.toDouble()),
    ]);
  }

  final grandTotal = sales.fold<num>(0, (sum, sale) => sum + sale.total);
  sheet.appendRow([
    xls.TextCellValue(''),
    xls.TextCellValue(''),
    xls.TextCellValue(''),
    xls.TextCellValue(''),
    xls.TextCellValue('Total'),
    xls.DoubleCellValue(grandTotal.toDouble()),
  ]);

  final bytes = workbook.encode();
  if (bytes == null) return;

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          name: 'laporan-penjualan.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
    ),
  );
}
