class WorkerDay {
  bool present;
  double expenses;
  WorkerDay({this.present = false, this.expenses = 0});

  Map<String, dynamic> toJson() => {'present': present, 'expenses': expenses};
  factory WorkerDay.fromJson(Map<String, dynamic> json) => WorkerDay(
    present: json['present'] ?? false,
    expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
  );
}

class Worker {
  final int id;
  String name;
  double dailyWage;
  Map<String, WorkerDay> weekDays;
  double weeklyExpenses;
  String weeklyExpensesStr;
  Worker({
    required this.id,
    required this.name,
    this.dailyWage = 0,
    Map<String, WorkerDay>? weekDays,
    this.weeklyExpenses = 0,
    this.weeklyExpensesStr = '',
  }) : weekDays = weekDays ?? {};

  double get weeklyTotal {
    final wages = weekDays.values.where((d) => d.present).length * dailyWage;
    return wages - weeklyExpenses;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'dailyWage': dailyWage,
    'weekDays': weekDays.map((k, v) => MapEntry(k, v.toJson())),
    'weeklyExpenses': weeklyExpenses,
    'weeklyExpensesStr': weeklyExpensesStr,
  };

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    name: json['name'] ?? '',
    dailyWage: (json['dailyWage'] as num?)?.toDouble() ?? 0,
    weekDays: (json['weekDays'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, WorkerDay.fromJson(v))
    ) ?? {},
    weeklyExpenses: (json['weeklyExpenses'] as num?)?.toDouble() ?? 0,
    weeklyExpensesStr: json['weeklyExpensesStr'] as String? ?? '',
  );
}
