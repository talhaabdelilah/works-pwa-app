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
            // Week navigation - like HTML card style
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _prevWeek,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.chevron_right, size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      children: [
                        Text(_formatWeek(_currentWeek), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        if (_isCurrentWeek) Text('الأسبوع الحالي', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _nextWeek,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(Icons.chevron_left, size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _copyToNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Text('نسخ', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            // Stats
            if (workers.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _statBox('👥', '${workers.length}', 'العمال'),
                    const SizedBox(width: 6),
                    _statBox('✅', '$presentToday', 'حضور اليوم'),
                    const SizedBox(width: 6),
                    _statBox('💰', '${totalWages.toStringAsFixed(0)}', 'المستحقات'),
                  ],
                ),
              ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: '🔍 بحث...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                  filled: true,
                  fillColor: Colors.white,
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
            // Table
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(_searchQuery.isNotEmpty ? Icons.search_off : Icons.engineering_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(_searchQuery.isNotEmpty ? 'لا توجد نتائج بحث' : 'لا يوجد عمال', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                      ]),
                    )
                  : Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 30,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 40,
                          columnSpacing: 0,
                          horizontalMargin: 2,
                          headingRowColor: WidgetStateProperty.all(const Color(0xFF1E293B)),
                          columns: [
                            const DataColumn(label: Text('#', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))),
                            DataColumn(label: Text('الاسم', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)), numeric: false),
                            ...List.generate(7, (i) => DataColumn(
                              label: Text(_dayShort[i], style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                            )),
                            const DataColumn(label: Text('الإجمالي', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))),
                            const DataColumn(label: Text('', style: TextStyle(fontSize: 8))),
                          ],
                          rows: List.generate(filtered.length, (i) {
                            final w = filtered[i];
                            return DataRow(cells: [
                              DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 9))),
                              DataCell(
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => WorkerDetailScreen(
                                      workerName: w.name,
                                      userData: widget.userData,
                                      onSave: widget.onSave,
                                    ),
                                  )),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: Color(0xFF3B82F6))),
                                  ),
                                ),
                              ),
                              ...List.generate(7, (j) {
                                final day = w.weekDays[dates[j]] ?? WorkerDay();
                                return DataCell(
                                  GestureDetector(
                                    onTap: () => _toggleDay(w, dates[j]),
                                    child: Container(
                                      width: 18, height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: day.present ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                      ),
                                      child: day.present ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                                    ),
                                  ),
                                );
                              }),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: w.weeklyTotal >= 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${w.weeklyTotal.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8, color: w.weeklyTotal >= 0 ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
                                ),
                              ),
                              DataCell(
                                GestureDetector(
                                  onTap: () {
                                    final workers = _getWorkers();
                                    widget.onSave(UserData(
                                      customers: widget.userData.customers,
                                      workersByWeek: Map<String, List<Worker>>.from(widget.userData.workersByWeek)..[_currentWeek] = workers.where((x) => x.id != w.id).toList(),
                                      accounting: widget.userData.accounting,
                                      partnerAccounting: widget.userData.partnerAccounting,
                                      lastBackupDate: widget.userData.lastBackupDate,
                                    ));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text('حذف', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ]);
                          }),
                        ),
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

  Widget _statBox(String icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
