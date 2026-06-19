import 'customer.dart';
import 'worker.dart';
import 'accounting.dart';

class UserData {
  List<Customer> customers;
  Map<String, List<Worker>> workersByWeek;
  AccountingData accounting;
  AccountingData partnerAccounting;
  String? lastBackupDate;
  String? lastDailyBackup;
  String? lastWeeklyBackup;
  bool autoSync;

  UserData({
    List<Customer>? customers,
    Map<String, List<Worker>>? workersByWeek,
    AccountingData? accounting,
    AccountingData? partnerAccounting,
    this.lastBackupDate,
    this.lastDailyBackup,
    this.lastWeeklyBackup,
    this.autoSync = false,
  }) : customers = customers ?? [],
       workersByWeek = workersByWeek ?? {},
       accounting = accounting ?? AccountingData(),
       partnerAccounting = partnerAccounting ?? AccountingData(partnerName: 'الشريك');

  Map<String, dynamic> toJson() => {
    'customers': customers.map((c) => c.toJson()).toList(),
    'workersByWeek': workersByWeek.map((k, v) => MapEntry(k, v.map((w) => w.toJson()).toList())),
    'accounting': accounting.toJson(),
    'partnerAccounting': partnerAccounting.toJson(),
    'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    'autoSync': autoSync,
    'lastBackupDate': lastBackupDate,
    'lastDailyBackup': lastDailyBackup,
    'lastWeeklyBackup': lastWeeklyBackup,
  };

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    customers: (json['customers'] as List?)?.map((c) => Customer.fromJson(Map<String, dynamic>.from(c))).toList() ?? [],
    workersByWeek: ((json['workersByWeek'] as Map<String, dynamic>?) ?? <String, dynamic>{}).map(
      (k, v) => MapEntry(k, (v as List).map((w) => Worker.fromJson(Map<String, dynamic>.from(w))).toList())
    ),
    accounting: AccountingData.fromJson(Map<String, dynamic>.from(json['accounting'] ?? {})),
    partnerAccounting: AccountingData.fromJson(Map<String, dynamic>.from(json['partnerAccounting'] ?? {})),
    lastBackupDate: json['lastBackupDate'] as String?,
    lastDailyBackup: json['lastDailyBackup'] as String?,
    lastWeeklyBackup: json['lastWeeklyBackup'] as String?,
    autoSync: json['autoSync'] as bool? ?? false,
  );
}
