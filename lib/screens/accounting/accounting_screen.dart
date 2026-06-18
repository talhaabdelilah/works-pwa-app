import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:works_app/models/user_data.dart';
import 'package:works_app/models/accounting.dart';

class AccountingScreen extends StatefulWidget {
  final UserData userData;
  final Function(UserData) onSave;

  const AccountingScreen({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  bool _showPartner = false;
  String _filter = 'all';

  AccountingData get _data => _showPartner ? widget.userData.partnerAccounting : widget.userData.accounting;

  List<AccountingRow> get _filteredRows {
    final rows = _data.rows;
    if (_filter == 'all') return rows;
    return rows.where((r) => r.source == _filter).toList();
  }

  void _saveData(AccountingData updated) {
    widget.onSave(UserData(
      customers: widget.userData.customers,
      workersByWeek: widget.userData.workersByWeek,
      accounting: _showPartner ? widget.userData.accounting : updated,
      partnerAccounting: _showPartner ? updated : widget.userData.partnerAccounting,
      lastBackupDate: widget.userData.lastBackupDate,
    ));
  }

  void _addRow() {
    final revenueCtrl = TextEditingController();
    final expenseCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة سطر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: revenueCtrl,
                decoration: const InputDecoration(labelText: 'الإيرادات'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expenseCtrl,
                decoration: const InputDecoration(labelText: 'المصروفات'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'ملاحظة'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final row = AccountingRow(
                  revenue: double.tryParse(revenueCtrl.text.trim()) ?? 0,
                  expense: double.tryParse(expenseCtrl.text.trim()) ?? 0,
                  note: noteCtrl.text.trim(),
                  source: 'manual',
                );
                final updated = AccountingData(
                  rows: [row, ..._data.rows],
                  history: _data.history,
                  partnerName: _data.partnerName,
                );
                _saveData(updated);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRow(int index) {
    final rows = List<AccountingRow>.from(_data.rows)..removeAt(index);
    final updated = AccountingData(rows: rows, history: _data.history, partnerName: _data.partnerName);
    _saveData(updated);
  }

  void _updateRow(int index, AccountingRow row) {
    final rows = List<AccountingRow>.from(_data.rows);
    rows[index] = row;
    final updated = AccountingData(rows: rows, history: _data.history, partnerName: _data.partnerName);
    _saveData(updated);
  }

  void _archiveBoth() {
    final data1 = widget.userData.accounting;
    final data2 = widget.userData.partnerAccounting;
    final now = DateTime.now();
    final date = intl.DateFormat('yyyy-MM-dd').format(now);
    final time = intl.DateFormat('HH:mm').format(now);

    final entry1 = ArchiveEntry(
      id: now.millisecondsSinceEpoch,
      date: date, time: time,
      rows: List.from(data1.rows),
      summary: {'totalRevenue': data1.totalRevenue, 'totalExpense': data1.totalExpense, 'netProfit': data1.netProfit},
      rowCount: data1.rows.length,
    );
    final entry2 = ArchiveEntry(
      id: now.millisecondsSinceEpoch + 1,
      date: date, time: time,
      rows: List.from(data2.rows),
      summary: {'totalRevenue': data2.totalRevenue, 'totalExpense': data2.totalExpense, 'netProfit': data2.netProfit},
      rowCount: data2.rows.length,
    );

    if (data1.rows.isEmpty && data2.rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات للأرشفة')),
      );
      return;
    }

    widget.onSave(UserData(
      customers: widget.userData.customers,
      workersByWeek: widget.userData.workersByWeek,
      accounting: AccountingData(rows: [], history: [...data1.history, entry1], partnerName: data1.partnerName),
      partnerAccounting: AccountingData(rows: [], history: [...data2.history, entry2], partnerName: data2.partnerName),
      lastBackupDate: widget.userData.lastBackupDate,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت الأرشفة لكلا الطرفين')),
    );
  }

  void _showArchive() {
    final allHistory = _data.history;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('سجل أرشفة ${_data.partnerName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: allHistory.isEmpty
                ? const Center(child: Text('لا توجد أرشفة'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: allHistory.length,
                    itemBuilder: (_, i) {
                      final entry = allHistory[i];
                      return Card(
                        child: ExpansionTile(
                          title: Text('${entry.date} ${entry.time}  •  ${entry.rowCount} سطور'),
                          subtitle: Text('صافي الربح: ${(entry.summary['netProfit'] ?? 0).toStringAsFixed(0)} د.ل'),
                          children: [
                            ...entry.rows.map((r) => ListTile(
                                  dense: true,
                                  title: Text('${r.revenue > 0 ? 'إيراد: ${r.revenue.toStringAsFixed(0)}' : ''}${r.expense > 0 ? '  مصروف: ${r.expense.toStringAsFixed(0)}' : ''}'),
                                  subtitle: r.note.isNotEmpty ? Text(r.note) : null,
                                )),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(children: [
                                Text('الإيرادات: ${(entry.summary['totalRevenue'] ?? 0).toStringAsFixed(0)}'),
                                const SizedBox(width: 12),
                                Text('المصروفات: ${(entry.summary['totalExpense'] ?? 0).toStringAsFixed(0)}'),
                                const SizedBox(width: 12),
                                Text('الصافي: ${(entry.summary['netProfit'] ?? 0).toStringAsFixed(0)}'),
                              ]),
                            ),
                            TextButton(
                              onPressed: () {
                                final restored = AccountingData(
                                  rows: [..._data.rows, ...entry.rows],
                                  history: _data.history.where((h) => h.id != entry.id).toList(),
                                  partnerName: _data.partnerName,
                                );
                                _saveData(restored);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تمت الاستعادة')),
                                );
                              },
                              child: const Text('استعادة'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRows;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(widget.userData.accounting.partnerName.isNotEmpty ? widget.userData.accounting.partnerName : 'الشريك الأول')),
                      ButtonSegment(value: true, label: Text(widget.userData.partnerAccounting.partnerName.isNotEmpty ? widget.userData.partnerAccounting.partnerName : 'الشريك الثاني')),
                    ],
                    selected: {_showPartner},
                    onSelectionChanged: (v) => setState(() => _showPartner = v.first),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _filterBtn('الكل', 'all'),
                      const SizedBox(width: 4),
                      _filterBtn('العمال', 'worker'),
                      const SizedBox(width: 4),
                      _filterBtn('المشاريع', 'project'),
                      const SizedBox(width: 4),
                      _filterBtn('يدوي', 'manual'),
                    ],
                  ),
                ],
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryRow('إجمالي الإيرادات', _data.totalRevenue, Colors.green),
                    const Divider(),
                    _summaryRow('إجمالي المصروفات', _data.totalExpense, Colors.red),
                    const Divider(),
                    _summaryRow('صافي الربح', _data.netProfit, _data.netProfit >= 0 ? Colors.green : Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _archiveBoth,
                  icon: const Icon(Icons.archive, size: 16),
                  label: const Text('أرشفة الكل', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _showArchive,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('سجل الأرشفة', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('لا توجد سجلات', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final row = filtered[i];
                        final realIdx = _data.rows.indexOf(row);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: 'إيراد', isDense: true),
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(
                                      text: row.revenue > 0 ? row.revenue.toStringAsFixed(0) : '',
                                    ),
                                    onChanged: (v) {
                                      row.revenue = double.tryParse(v) ?? 0;
                                      _updateRow(realIdx, row);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: 'مصروف', isDense: true),
                                    keyboardType: TextInputType.number,
                                    controller: TextEditingController(
                                      text: row.expense > 0 ? row.expense.toStringAsFixed(0) : '',
                                    ),
                                    onChanged: (v) {
                                      row.expense = double.tryParse(v) ?? 0;
                                      _updateRow(realIdx, row);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: 'ملاحظة', isDense: true),
                                    controller: TextEditingController(text: row.note),
                                    onChanged: (v) {
                                      row.note = v;
                                      _updateRow(realIdx, row);
                                    },
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (row.source == 'worker')
                                      Icon(Icons.engineering, size: 12, color: Colors.blue[300])
                                    else if (row.source == 'project')
                                      Icon(Icons.build, size: 12, color: Colors.green[300])
                                    else if (row.source == 'manual')
                                      Icon(Icons.edit, size: 12, color: Colors.orange[300]),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      onPressed: () => _deleteRow(realIdx),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addRow,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _filterBtn(String label, String value) {
    final active = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey[700],
          )),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, Color color) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(0)} د.ل',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
