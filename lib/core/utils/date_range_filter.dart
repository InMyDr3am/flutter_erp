class DateRangeFilter {
  const DateRangeFilter({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  bool get isActive => from != null && to != null;
}

DateRangeFilter defaultMonthToDateFilter() => DateRangeFilter(
      from: DateTime.now().subtract(const Duration(days: 30)),
      to: DateTime.now(),
    );

DateRangeFilter todayFilter() {
  final now = DateTime.now();
  return DateRangeFilter(
    from: DateTime(now.year, now.month, now.day),
    to: DateTime(now.year, now.month, now.day, 23, 59, 59),
  );
}
