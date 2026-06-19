class AccountingRow {
  double revenue;
  double expense;
  String note;
  String source;

  AccountingRow({this.revenue = 0, this.expense = 0, this.note = '', this.source = 'manual'});

  Map<String, dynamic> toJson() => {
    'revenue': revenue, 'expense': expense, 'note': note, 'source': source,
  };

  factory AccountingRow.fromJson(Map<String, dynamic> json) => AccountingRow(
    revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    expense: (json['expense'] as num?)?.toDouble() ?? 0,
    note: json['note'] ?? '',
    source: json['source'] ?? 'manual',
  );
}

class ArchiveEntry {
  final int id;
  String date;
  String time;
  List<AccountingRow> rows;
  Map<String, double> summary;
  int rowCount;

  ArchiveEntry({
    required this.id, required this.date, required this.time,
    required this.rows, required this.summary, required this.rowCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date, 'time': time,
    'rows': rows.map((r) => r.toJson()).toList(),
    'summary': summary, 'rowCount': rowCount,
  };

  factory ArchiveEntry.fromJson(Map<String, dynamic> json) => ArchiveEntry(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    date: json['date'] ?? '', time: json['time'] ?? '',
    rows: (json['rows'] as List?)?.map((r) => AccountingRow.fromJson(Map<String, dynamic>.from(r))).toList() ?? [],
    summary: Map<String, double>.from((json['summary'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble())
    ) ?? {}),
    rowCount: json['rowCount'] ?? 0,
  );
}

class AccountingData {
  List<AccountingRow> rows;
  List<ArchiveEntry> history;
  String partnerName;

  AccountingData({List<AccountingRow>? rows, List<ArchiveEntry>? history, this.partnerName = 'الشريك'})
      : rows = rows ?? [], history = history ?? [];

  double get totalRevenue => rows.fold(0, (s, r) => s + r.revenue);
  double get totalExpense => rows.fold(0, (s, r) => s + r.expense);
  double get netProfit => totalRevenue - totalExpense;

  Map<String, dynamic> toJson() => {
    'rows': rows.map((r) => r.toJson()).toList(),
    'history': history.map((h) => h.toJson()).toList(),
    'partnerName': partnerName,
  };

  factory AccountingData.fromJson(Map<String, dynamic> json) => AccountingData(
    rows: (json['rows'] as List?)?.map((r) => AccountingRow.fromJson(Map<String, dynamic>.from(r))).toList() ?? [],
    history: (json['history'] as List?)?.map((h) => ArchiveEntry.fromJson(Map<String, dynamic>.from(h))).toList() ?? [],
    partnerName: json['partnerName'] ?? 'الشريك',
  );
}
