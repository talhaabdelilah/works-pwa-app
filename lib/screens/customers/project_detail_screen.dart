import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:works_app/models/project.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  final Function(Project) onUpdate;
  final VoidCallback? onDelete;

  const ProjectDetailScreen({super.key, required this.project, required this.onUpdate, this.onDelete});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _nameCtrl = TextEditingController(text: _project.name);
    _priceCtrl = TextEditingController(text: _project.globalPricePerMeter.toString());
    _notesCtrl = TextEditingController(text: _project.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final price = double.tryParse(_priceCtrl.text.trim()) ?? _project.globalPricePerMeter;
    _project.name = _nameCtrl.text.trim();
    _project.globalPricePerMeter = price;
    _project.notes = _notesCtrl.text.trim();
    widget.onUpdate(_project);
  }

  Future<String?> _pickAndSaveImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'att_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = '${dir.path}/$fileName';
    await File(picked.path).copy(savedPath);
    return savedPath;
  }

  void _addAttachment(ImageSource source) async {
    final path = await _pickAndSaveImage(source);
    if (path == null) return;
    setState(() {
      _project.attachments.add(ProjectAttachment(
        id: DateTime.now().millisecondsSinceEpoch,
        name: path.split('/').last,
        path: path,
        type: 'image',
      ));
    });
    _save();
  }

  void _deleteAttachment(int index) {
    final att = _project.attachments[index];
    try { File(att.path).delete(); } catch (_) {}
    setState(() => _project.attachments.removeAt(index));
    _save();
  }

  Future<void> _viewAttachment(ProjectAttachment att) async {
    final file = File(att.path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الملف غير موجود')),
        );
      }
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(att.name),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.contain),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }

  void _addRoom() {
    showDialog(
      context: context,
      builder: (ctx) => _RoomDialog(
        pricePerMeter: _project.globalPricePerMeter,
        onSave: (room) {
          setState(() => _project.rooms.add(room));
          _save();
        },
      ),
    );
  }

  void _deleteRoom(Room room) {
    setState(() => _project.rooms.removeWhere((r) => r.id == room.id));
    _save();
  }

  void _updateRoom(Room room) {
    setState(() {
      final idx = _project.rooms.indexWhere((r) => r.id == room.id);
      if (idx >= 0) _project.rooms[idx] = room;
    });
    _save();
  }

  void _addPayment() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة دفعة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                        title: Text(intl.DateFormat('yyyy-MM-dd').format(selectedDate)),
                leading: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) selectedDate = picked;
                },
              ),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'المبلغ'),
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
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amount <= 0) return;
                setState(() {
                  _project.payments.insert(0, Payment(
                    date: intl.DateFormat('yyyy-MM-dd').format(selectedDate),
                    amount: amount,
                    note: noteCtrl.text.trim(),
                  ));
                });
                _save();
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePayment(int index) {
    setState(() => _project.payments.removeAt(index));
    _save();
  }

  void _showCalculator(Room room) {
    final ctrl = TextEditingController(text: room.totalCost.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل التكلفة'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'التكلفة الإجمالية'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(ctrl.text.trim()) ?? 0;
                if (room.meterValue > 0) {
                  room.pricePerMeter = val / room.meterValue;
                }
                _updateRoom(room);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final totalPaid = _project.totalPayments;
    final remaining = _project.remaining;
    final totalArea = _project.rooms.where((r) => r.calcMode == 'area').fold(0.0, (s, r) => s + r.meterValue);
    final totalPerimeter = _project.rooms.where((r) => r.calcMode == 'perimeter').fold(0.0, (s, r) => s + r.meterValue);
    final areaCost = _project.rooms.where((r) => r.calcMode == 'area').fold(0.0, (s, r) => s + r.totalCost);
    final perimeterCost = _project.rooms.where((r) => r.calcMode == 'perimeter').fold(0.0, (s, r) => s + r.totalCost);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_project.name, style: const TextStyle(fontSize: 13)),
          actions: [
            if (widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                tooltip: 'حذف المشروع',
                onPressed: () {
                  widget.onDelete!();
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price per meter box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Text('💰 سعر المتر:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    const Spacer(),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFF94A3B8))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (_) {
                          final p = double.tryParse(_priceCtrl.text.trim());
                          if (p != null) _project.globalPricePerMeter = p;
                          _save();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Payments section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💰 الدفعات المستلمة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const Spacer(),
                        GestureDetector(
                          onTap: _addPayment,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text('➕ إضافة', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_project.payments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('لا توجد دفعات', style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                      )
                    else ...[
                      // Payments table header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text('التاريخ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center)),
                            Expanded(child: Text('المبلغ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center)),
                            Expanded(child: Text('ملاحظة', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center)),
                            const SizedBox(width: 24),
                          ],
                        ),
                      ),
                      ..._project.payments.asMap().entries.map((entry) {
                        final i = entry.key;
                        final p = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(p.date, style: TextStyle(fontSize: 9, color: const Color(0xFF1E293B)), textAlign: TextAlign.center)),
                              Expanded(child: Text('${p.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              Expanded(child: Text(p.note, style: TextStyle(fontSize: 9, color: const Color(0xFF64748B)), textAlign: TextAlign.center)),
                              GestureDetector(
                                onTap: () => _deletePayment(i),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('✖', style: TextStyle(fontSize: 8, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 12),
                      Row(
                        children: [
                          const Text('إجمالي المدفوعات:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${totalPaid.toStringAsFixed(0)} د.ل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('المتبقي:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: remaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF065F46))),
                          const Spacer(),
                          Text('${remaining.toStringAsFixed(0)} د.ل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: remaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF065F46))),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Text('📐 المساحة:', style: TextStyle(fontSize: 10, color: const Color(0xFF1E293B))),
                          const Spacer(),
                          Text('${totalArea.toStringAsFixed(2)} م²', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('💰 تكلفة المساحة:', style: TextStyle(fontSize: 10, color: const Color(0xFF1E293B))),
                          const Spacer(),
                          Text('${areaCost.toStringAsFixed(0)} د.ل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('📏 المحيط:', style: TextStyle(fontSize: 10, color: const Color(0xFF1E293B))),
                          const Spacer(),
                          Text('${totalPerimeter.toStringAsFixed(2)} م', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('💰 تكلفة المحيط:', style: TextStyle(fontSize: 10, color: const Color(0xFF1E293B))),
                          const Spacer(),
                          Text('${perimeterCost.toStringAsFixed(0)} د.ل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('🏗️ المجموع الكلي (مساحة + محيط):', style: TextStyle(fontSize: 10, color: const Color(0xFF1E293B))),
                          const Spacer(),
                          Text('${(totalArea + totalPerimeter).toStringAsFixed(2)} م', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text('💰 إجمالي التكلفة:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          const Spacer(),
                          Text('${_project.totalCost.toStringAsFixed(0)} د.ل', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Add room button
              GestureDetector(
                onTap: _addRoom,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('➕ إضافة غرفة', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Rooms table
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Rooms table header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      ),
                      child: Row(
                        children: [
                          _roomHeaderCell('#', 20),
                          _roomHeaderCell('الطول', null),
                          _roomHeaderCell('العرض', null),
                          _roomHeaderCell('النوع', 40),
                          _roomHeaderCell('القيمة', null),
                          _roomHeaderCell('الإجمالي', null),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),
                    ..._project.rooms.asMap().entries.map((entry) {
                      final i = entry.key;
                      final room = entry.value;
                      return _RoomTableRow(
                        room: room,
                        index: i,
                        globalPrice: _project.globalPricePerMeter,
                        onUpdate: _updateRoom,
                        onDelete: () => _deleteRoom(room),
                        onCalc: () => _showCalculator(room),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Attachments
              Row(
                children: [
                  const Text('المرفقات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const Spacer(),
                  PopupMenuButton<ImageSource>(
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFF3B82F6)),
                    tooltip: 'إضافة مرفق',
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: ImageSource.camera, child: ListTile(
                        leading: Icon(Icons.camera_alt), title: Text('تصوير'),
                      )),
                      PopupMenuItem(value: ImageSource.gallery, child: ListTile(
                        leading: Icon(Icons.photo_library), title: Text('اختيار من المعرض'),
                      )),
                    ],
                    onSelected: _addAttachment,
                  ),
                ],
              ),
              if (_project.attachments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('لا توجد مرفقات', style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
                ),
              ..._project.attachments.asMap().entries.map((entry) {
                final i = entry.key;
                final a = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2)],
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.image, size: 32, color: Color(0xFF3B82F6)),
                    title: Text(a.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    subtitle: a.note.isNotEmpty ? Text(a.note, style: const TextStyle(fontSize: 10)) : null,
                    trailing: GestureDetector(
                      onTap: () => _deleteAttachment(i),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444)),
                      ),
                    ),
                    onTap: () => _viewAttachment(a),
                  ),
                );
              }),
              const SizedBox(height: 16),
              // Notes
              const Text('ملاحظات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'أضف ملاحظات حول المشروع...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                ),
                onChanged: (_) => _save(),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomHeaderCell(String label, double? width) {
    return SizedBox(
      width: width,
      child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), textAlign: TextAlign.center),
    );
  }
}

class _RoomDialog extends StatefulWidget {
  final double pricePerMeter;
  final Function(Room) onSave;

  const _RoomDialog({required this.pricePerMeter, required this.onSave});

  @override
  State<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<_RoomDialog> {
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  String _calcMode = 'area';

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة غرفة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _lengthCtrl,
              decoration: const InputDecoration(labelText: 'الطول'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _widthCtrl,
              decoration: const InputDecoration(labelText: 'العرض'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'area', label: Text('مساحة')),
                ButtonSegment(value: 'perimeter', label: Text('محيط')),
              ],
              selected: {_calcMode},
              onSelectionChanged: (v) => setState(() => _calcMode = v.first),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final l = double.tryParse(_lengthCtrl.text.trim());
              final w = double.tryParse(_widthCtrl.text.trim());
              if (l == null || w == null) return;
              final room = Room(
                id: DateTime.now().millisecondsSinceEpoch,
                lengthVal: l,
                widthVal: w,
                calcMode: _calcMode,
                pricePerMeter: widget.pricePerMeter,
              );
              widget.onSave(room);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _RoomTableRow extends StatelessWidget {
  final Room room;
  final int index;
  final double globalPrice;
  final Function(Room) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onCalc;

  const _RoomTableRow({
    required this.room,
    required this.index,
    required this.globalPrice,
    required this.onUpdate,
    required this.onDelete,
    required this.onCalc,
  });

  @override
  Widget build(BuildContext context) {
    final lCtrl = TextEditingController(text: room.lengthVal?.toStringAsFixed(2) ?? '');
    final wCtrl = TextEditingController(text: room.widthVal?.toStringAsFixed(2) ?? '');
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 0.5)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text('${index + 1}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: TextField(
                    controller: lCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      final l = double.tryParse(lCtrl.text.trim());
                      final w = double.tryParse(wCtrl.text.trim());
                      if (l != null && w != null) {
                        room.lengthVal = l;
                        room.widthVal = w;
                      }
                      onUpdate(room);
                    },
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: TextField(
                    controller: wCtrl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      final l = double.tryParse(lCtrl.text.trim());
                      final w = double.tryParse(wCtrl.text.trim());
                      if (l != null && w != null) {
                        room.lengthVal = l;
                        room.widthVal = w;
                      }
                      onUpdate(room);
                    },
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(room.calcMode == 'area' ? 'مساحة' : 'محيط', style: const TextStyle(fontSize: 9), textAlign: TextAlign.center),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onCalc,
                  child: Text('${room.meterValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
              Expanded(
                child: Text('${room.totalCost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)), textAlign: TextAlign.center),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: const Text('✖', style: TextStyle(fontSize: 8, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
