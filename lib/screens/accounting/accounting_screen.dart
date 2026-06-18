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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showPartner = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _showPartner ? const Color(0xFFF1F5F9) : const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          widget.userData.accounting.partnerName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: _showPartner ? const Color(0xFF475569) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showPartner = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _showPartner ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          widget.userData.partnerAccounting.partnerName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: _showPartner ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _summaryItem('إيرادات', _data.totalRevenue, const Color(0xFF10B981)),
                  _summaryItem('مصروفات', _data.totalExpense, const Color(0xFFF87171)),
                  _summaryItem('صافي', _data.netProfit, _data.netProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFF87171)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _filterBtn('الكل', 'all'),
                  const SizedBox(width: 4),
                  _filterBtn('عمال', 'worker'),
                  const SizedBox(width: 4),
                  _filterBtn('مشاريع', 'project'),
                  const SizedBox(width: 4),
                  _filterBtn('يدوي', 'manual'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  _actionBtn(Icons.archive, 'أرشفة', _archiveBoth, const Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  _actionBtn(Icons.history, 'السجل', _showArchive, const Color(0xFF8B5CF6)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('لا توجد سجلات', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final row = filtered[i];
                        final realIdx = _data.rows.indexOf(row);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(labelText: 'إيراد', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
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
                                    decoration: const InputDecoration(labelText: 'مصروف', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
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
                                    decoration: const InputDecoration(labelText: 'ملاحظة', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
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
                                    _sourceBadge(row.source),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 16),
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
          child: const Icon(Icons.add, size: 22),
        ),
      ),
    );
  }

  Widget _sourceBadge(String source) {
    Color bg;
    Color fg;
    String label;
    switch (source) {
      case 'worker':
        bg = const Color(0xFFFEE2E2); fg = const Color(0xFF991B1B); label = 'عامل';
        break;
      case 'project':
        bg = const Color(0xFFD1FAE5); fg = const Color(0xFF065F46); label = 'مشروع';
        break;
      default:
        bg = const Color(0xFFE0E7FF); fg = const Color(0xFF3730A3); label = 'يدوي';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.bold)),
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 2),
          Text('${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF3B82F6) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: active ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
          )),
        ),
      ),
    );
  }
}
