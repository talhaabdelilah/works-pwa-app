class Worker {
  final int id;
  String name;
  String phone;
  double price;
  String expenseText;
  Map<String, int> days;

  static const dayKeys = ['sat','sun','mon','tue','wed','thu','fri'];

  Worker({
    required this.id,
    required this.name,
    this.phone = '',
    this.price = 0,
    this.expenseText = '',
    Map<String, int>? days,
  }) : days = days ?? {};

  double get weeklyTotal {
    final present = dayKeys.fold(0, (s, d) => s + (days[d] == 1 ? 1 : 0));
    return present * price - (double.tryParse(expenseText) ?? 0);
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'price': price,
    'expenseText': expenseText, 'days': days,
  };

  factory Worker.fromJson(Map<String, dynamic> json) => Worker(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    price: (json['price'] ?? json['dailyWage'] ?? 0).toDouble(),
    expenseText: json['expenseText'] ?? json['weeklyExpensesStr'] ?? '',
    days: Map<String, int>.from(
      (json['days'] ?? json['weekDays'] ?? {}).map(
        (k, v) => MapEntry(k.toString(), v is int ? v : ((v is Map && v['present'] == true) ? 1 : 0))
      )
    ),
  );
}
