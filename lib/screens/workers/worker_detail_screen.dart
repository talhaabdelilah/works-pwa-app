import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:works_app/models/user_data.dart';
import 'package:works_app/models/worker.dart';
import 'package:works_app/models/accounting.dart';


class WorkerDetailScreen extends StatefulWidget {
  final String workerName;
  final UserData userData;
  final Function(UserData) onSave;

  const WorkerDetailScreen({super.key, required this.workerName, required this.userData, required this.onSave});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  static const _arMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  String _fmtWeek(String wk) {
    try {
      final sat = DateTime.parse(wk);
      final fri = sat.add(const Duration(days: 6));
      return '${sat.day} ${_arMonths[sat.month - 1]} - ${fri.day} ${_arMonths[fri.month - 1]}';
    } catch (_) {
      return wk;
    }
  }

  void _editExpenses(String weekKey, Worker worker) {
    final ctrl = TextEditingController(text: worker.weeklyExpenses > 0 ? worker.weeklyExpenses.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل المصروفات'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'المصروفات الأسبوعية'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                worker.weeklyExpenses = double.tryParse(ctrl.text.trim()) ?? 0;
                _updateWorker(weekKey, worker);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _editWage(String weekKey, Worker worker) {
    final ctrl = TextEditingController(text: worker.dailyWage.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تعديل أجر ${worker.name}'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'الأجر اليومي'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                worker.dailyWage = double.tryParse(ctrl.text.trim()) ?? 0;
                _updateWorker(weekKey, worker);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateWorker(String weekKey, Worker updatedWorker) {
    final up = Map<String, List<Worker>>.from(widget.userData.workersByWeek);
    final workers = up[weekKey] ?? [];
    final idx = workers.indexWhere((w) => w.id == updatedWorker.id);
    if (idx >= 0) {
      workers[idx] = updatedWorker;
      up[weekKey] = workers;
    }

    if (widget.userData.autoSync) {
      final accRows = widget.userData.accounting.rows.where((r) => r.source != 'worker').toList();
      for (final ws in up.values) {
        for (final w in ws) {
          if (w.name == widget.workerName && w.weeklyExpenses > 0) {
            accRows.add(AccountingRow(
              expense: w.weeklyExpenses,
              note: 'عامل ${w.name}',
              source: 'worker',
            ));
          }
        }
      }
      widget.onSave(UserData(
        customers: widget.userData.customers,
        workersByWeek: up,
        accounting: AccountingData(rows: accRows, history: widget.userData.accounting.history, partnerName: widget.userData.accounting.partnerName),
        partnerAccounting: widget.userData.partnerAccounting,
        lastBackupDate: widget.userData.lastBackupDate,
      ));
    } else {
      widget.onSave(UserData(
        customers: widget.userData.customers,
        workersByWeek: up,
        accounting: widget.userData.accounting,
        partnerAccounting: widget.userData.partnerAccounting,
        lastBackupDate: widget.userData.lastBackupDate,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final weeks = <String, Worker>{};
    for (final entry in widget.userData.workersByWeek.entries) {
      for (final w in entry.value) {
        if (w.name == widget.workerName) {
          weeks[entry.key] = w;
        }
      }
    }
    final sortedWeeks = weeks.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    int totalDays = 0;
    double totalDues = 0, totalExpenses = 0, totalNet = 0;

    for (final e in sortedWeeks) {
      final w = e.value;
      final days = w.weekDays.values.where((d) => d.present).length;
      totalDays += days;
      totalDues += days * w.dailyWage;
      totalExpenses += w.weeklyExpenses;
    }
    totalNet = totalDues - totalExpenses;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.workerName)),
        body: sortedWeeks.isEmpty
            ? const Center(child: Text('لا توجد بيانات'))
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Row(children: [
                    Expanded(child: _statCard('المستحقات', '${totalDues.toStringAsFixed(0)}', Colors.green, Icons.monetization_on)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('أيام العمل', '$totalDays', Colors.blue, Icons.calendar_today)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('المصروفات', '${totalExpenses.toStringAsFixed(0)}', Colors.red, Icons.money_off)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('الصافي', '${totalNet.toStringAsFixed(0)}', totalNet >= 0 ? Colors.teal : Colors.red, Icons.balance)),
                  ]),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoChip('عدد الأسابيع', '${sortedWeeks.length}'),
                          _infoChip('متوسط الأيام/أسبوع', '${(totalDays / sortedWeeks.length).toStringAsFixed(1)}'),
                          _infoChip('متوسط الدخل/أسبوع', '${(totalDues / sortedWeeks.length).toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('أسابيع العمل', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...sortedWeeks.map((e) {
                    final w = e.value;
                    final wk = e.key;
                    final days = w.weekDays.values.where((d) => d.present).length;
                    final wages = days * w.dailyWage;
                    final net = wages - w.weeklyExpenses;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.date_range, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Text(_fmtWeek(wk), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('$days أيام', style: TextStyle(fontSize: 11, color: Colors.green[700], fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _detailChip('الأجر', '${w.dailyWage.toStringAsFixed(0)} د.ل', Colors.blue, () => _editWage(wk, w)),
                                const SizedBox(width: 6),
                                _detailChip('المستحق', '${wages.toStringAsFixed(0)} د.ل', Colors.green, null),
                                const SizedBox(width: 6),
                                _detailChip('مصروفات', '${w.weeklyExpenses.toStringAsFixed(0)} د.ل', Colors.red, () => _editExpenses(wk, w)),
                                const SizedBox(width: 6),
                                _detailChip('الصافي', '${net.toStringAsFixed(0)} د.ل', Colors.teal, null),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Total row
                  Card(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.summarize, size: 16),
                          const SizedBox(width: 6),
                          const Text('المجموع الكلي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Text('${totalDues.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[700])),
                          const SizedBox(width: 4),
                          Text('|', style: TextStyle(color: Colors.grey[400])),
                          const SizedBox(width: 4),
                          Text('${totalExpenses.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700])),
                          const SizedBox(width: 4),
                          Text('|', style: TextStyle(color: Colors.grey[400])),
                          const SizedBox(width: 4),
                          Text('${totalNet.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal[700])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _detailChip(String label, String value, Color color, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: onTap != null ? color.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: onTap != null ? Border.all(color: color.withValues(alpha: 0.2)) : null,
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }
}
