import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:works_app/models/user_data.dart';
import 'package:works_app/models/worker.dart';
import 'package:works_app/screens/workers/worker_detail_screen.dart';

class WorkersScreen extends StatefulWidget {
  final UserData userData;
  final Function(UserData) onSave;

  const WorkersScreen({super.key, required this.userData, required this.onSave});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  late String _currentWeek;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _dayNames = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  static const _dayShort = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
  static const _arMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  @override
  void initState() {
    super.initState();
    _currentWeek = _getWeekKey(DateTime.now());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _getWeekKey(DateTime d) {
    final sat = d.subtract(Duration(days: (d.weekday + 1) % 7));
    return intl.DateFormat('yyyy-MM-dd').format(sat);
  }

  List<String> _getDates(String wk) {
    final p = DateTime.parse(wk);
    return List.generate(7, (i) => intl.DateFormat('yyyy-MM-dd').format(p.add(Duration(days: i))));
  }

  String _formatWeek(String wk) {
    try {
      final sat = DateTime.parse(wk);
      final fri = sat.add(const Duration(days: 6));
      return '${sat.day} ${_arMonths[sat.month - 1]} - ${fri.day} ${_arMonths[fri.month - 1]} ${sat.year}';
    } catch (_) {
      return wk;
    }
  }

  bool get _isCurrentWeek => _currentWeek == _getWeekKey(DateTime.now());

  void _prevWeek() {
    setState(() => _currentWeek = _getWeekKey(DateTime.parse(_currentWeek).subtract(const Duration(days: 7))));
  }

  void _nextWeek() {
    setState(() => _currentWeek = _getWeekKey(DateTime.parse(_currentWeek).add(const Duration(days: 7))));
  }

  void _copyToNext() {
    final nextKey = _getWeekKey(DateTime.parse(_currentWeek).add(const Duration(days: 7)));
    final cur = _getWorkers();
    final copied = cur.map((w) => Worker(
      id: DateTime.now().millisecondsSinceEpoch + w.id,
      name: w.name, dailyWage: w.dailyWage,
    )).toList();

    final up = Map<String, List<Worker>>.from(widget.userData.workersByWeek);
    final existing = up[nextKey] ?? [];
    up[nextKey] = [...existing, ...copied];
    widget.onSave(UserData(
      customers: widget.userData.customers, workersByWeek: up,
      accounting: widget.userData.accounting,
      partnerAccounting: widget.userData.partnerAccounting,
      lastBackupDate: widget.userData.lastBackupDate,
    ));
    setState(() => _currentWeek = nextKey);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ للأسبوع القادم'), duration: Duration(seconds: 1)),
    );
  }

  List<Worker> _getWorkers() => widget.userData.workersByWeek[_currentWeek] ?? [];

  List<Worker> _getFilteredWorkers() {
    final workers = _getWorkers();
    if (_searchQuery.isEmpty) return workers;
    return workers.where((w) => w.name.contains(_searchQuery)).toList();
  }

  void _save(List<Worker> workers) {
    final up = Map<String, List<Worker>>.from(widget.userData.workersByWeek);
    up[_currentWeek] = workers;
    widget.onSave(UserData(
      customers: widget.userData.customers, workersByWeek: up,
      accounting: widget.userData.accounting,
      partnerAccounting: widget.userData.partnerAccounting,
      lastBackupDate: widget.userData.lastBackupDate,
    ));
  }

  void _addWorker() {
    final nc = TextEditingController();
    final wc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة عامل'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nc, decoration: const InputDecoration(labelText: 'اسم العامل')),
            const SizedBox(height: 12),
            TextField(controller: wc, decoration: const InputDecoration(labelText: 'الأجر اليومي'), keyboardType: TextInputType.number),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nc.text.trim().isEmpty) return;
                _save([Worker(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: nc.text.trim(),
                  dailyWage: double.tryParse(wc.text.trim()) ?? 0,
                ), ..._getWorkers()]);
                Navigator.pop(ctx);
              }, child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDay(Worker w, String date) {
    final day = w.weekDays[date] ?? WorkerDay();
    day.present = !day.present;
    w.weekDays[date] = day;
    _save(_getWorkers());
  }

  @override
  Widget build(BuildContext context) {
    final workers = _getWorkers();
    final filtered = _getFilteredWorkers();
    final dates = _getDates(_currentWeek);
    final todayStr = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
    final presentToday = workers.where((w) => (w.weekDays[todayStr] ?? WorkerDay()).present).length;
    final totalWages = workers.fold(0.0, (s, w) => s + w.weekDays.values.where((d) => d.present).length * w.dailyWage);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_right, size: 28), onPressed: _prevWeek, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  Expanded(
                    child: Column(
                      children: [
                        Text(_formatWeek(_currentWeek), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (_isCurrentWeek) Text('الأسبوع الحالي', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: _nextWeek, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _copyToNext,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: const Text('نسخ', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
            if (workers.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _statBox('👥', '${workers.length}', 'العمال', Colors.blue),
                    const SizedBox(width: 8),
                    _statBox('✅', '$presentToday', 'حضور اليوم', Colors.green),
                    const SizedBox(width: 8),
                    _statBox('💰', '${totalWages.toStringAsFixed(0)}', 'المستحقات', Colors.orange),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: '🔍 بحث...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                      : null,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_searchQuery.isNotEmpty ? Icons.search_off : Icons.engineering_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(_searchQuery.isNotEmpty ? 'لا توجد نتائج بحث' : 'لا يوجد عمال', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                      ]),
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        headingRowHeight: 36,
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 52,
                        columnSpacing: 4,
                        horizontalMargin: 6,
                        columns: [
                          const DataColumn(label: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('الاسم', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          ...List.generate(7, (i) => DataColumn(
                            label: Text(_dayShort[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          )),
                          const DataColumn(label: Text('الإجمالي', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                          const DataColumn(label: Text('', style: TextStyle(fontSize: 10))),
                        ],
                        rows: List.generate(filtered.length, (i) {
                          final w = filtered[i];
                          return DataRow(cells: [
                            DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 11))),
                            DataCell(
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => WorkerDetailScreen(
                                    workerName: w.name,
                                    userData: widget.userData,
                                    onSave: widget.onSave,
                                  ),
                                )),
                                child: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, decoration: TextDecoration.underline, color: Colors.blue)),
                              ),
                            ),
                            ...List.generate(7, (j) {
                              final day = w.weekDays[dates[j]] ?? WorkerDay();
                              return DataCell(
                                GestureDetector(
                                  onTap: () => _toggleDay(w, dates[j]),
                                  child: Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: day.present ? Colors.green : Colors.grey[300],
                                    ),
                                    child: day.present ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                  ),
                                ),
                              );
                            }),
                            DataCell(Text('${w.weeklyTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            DataCell(
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[300]),
                                onPressed: () => _save(workers.where((x) => x.id != w.id).toList()),
                                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                              ),
                            ),
                          ]);
                        }),
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addWorker,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _statBox(String icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
