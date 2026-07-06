import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StockStatus { aman, menipis, kritis }

StockStatus stockStatusOf({required num stock, required num minStock}) {
  if (stock <= 0 || stock < minStock) return StockStatus.kritis;
  if (stock <= minStock * 1.2) return StockStatus.menipis;
  return StockStatus.aman;
}

extension StockStatusX on StockStatus {
  String get label => switch (this) {
        StockStatus.aman => 'Stok Aman',
        StockStatus.menipis => 'Stok Menipis',
        StockStatus.kritis => 'Stok Kritis',
      };

  Color get color => switch (this) {
        StockStatus.aman => AppColors.stokAman,
        StockStatus.menipis => AppColors.stokMenipis,
        StockStatus.kritis => AppColors.stokKritis,
      };
}

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status, this.dense = false});

  final StockStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 10,
        vertical: dense ? 2 : 5,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: dense ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
