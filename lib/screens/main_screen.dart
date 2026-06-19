import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:works_app/services/storage_service.dart';
import 'package:works_app/services/file_picker_service.dart';
import 'package:works_app/services/firebase_sync_service.dart';
import 'package:works_app/models/user_data.dart';
import 'package:works_app/models/accounting.dart';
import 'package:works_app/screens/customers/customers_screen.dart';
import 'package:works_app/screens/workers/workers_screen.dart';
import 'package:works_app/screens/accounting/accounting_screen.dart';

class MainScreen extends StatefulWidget {
  final UserData userData;

  const MainScreen({super.key, required this.userData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late UserData _data;
  int _currentIndex = 0;
  final _firebase = FirebaseSyncService();

  bool _isSyncing = false;

  final _titles = ['العملاء', 'العمال', 'المحاسبة', 'تسوية'];

  @override
  void initState() {
    super.initState();
    _data = widget.userData;
    _tryLoginFromPrefs();
  }

  Future<void> _tryLoginFromPrefs() async {
    final email = await StorageService().getFirebaseEmail();
    final password = await StorageService().getFirebasePassword();
    if (email != null && password != null) {
      await _firebase.signIn(email, password);
      if (mounted) setState(() {});
    }
  }

  void _saveData(UserData updatedData) {
    setState(() {
      _data.customers = updatedData.customers;
      _data.workersByWeek = updatedData.workersByWeek;
      _data.accounting = updatedData.accounting;
      _data.partnerAccounting = updatedData.partnerAccounting;
    });
    StorageService().saveUserData(_data);
    if (_firebase.isSignedIn) {
      _firebase.saveToFirebase(_data);
    }
  }

  Future<void> _exportJson() async {
    try {
      final path = await StorageService().exportToJson(_data);
      final file = XFile(path);
      await SharePlus.instance.share(
        ShareParams(files: [file], text: 'نسخة احتياطية - نظام إدارة المشاريع'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importJson() async {
    final method = await showDialog<String>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استيراد بيانات'),
          content: const Text('اختر طريقة الاستيراد:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'paste'),
              child: const Text('📋 لصق نص'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'file'),
              child: const Text('📂 اختيار ملف'),
            ),
          ],
        ),
      ),
    );
    if (method == null) return;

    if (method == 'paste') {
      final ctrl = TextEditingController();
      final imported = await showDialog<UserData>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('لصق JSON'),
            content: SizedBox(
              width: double.maxFinite,
              child: TextField(
                controller: ctrl,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'الصق محتوى JSON هنا',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  try {
                    final data = StorageService().importFromJson(ctrl.text.trim());
                    Navigator.pop(ctx, data);
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('استيراد'),
              ),
            ],
          ),
        ),
      );
      if (imported != null) {
        _saveData(imported);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استيراد البيانات بنجاح')));
      }
    } else {
      try {
        final content = await FilePickerService.pickJsonFile();
        if (content == null || content.isEmpty) return;
        final data = StorageService().importFromJson(content);
        _saveData(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استيراد البيانات بنجاح')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editPartnerNames() async {
    final ctrl1 = TextEditingController(text: _data.accounting.partnerName);
    final ctrl2 = TextEditingController(text: _data.partnerAccounting.partnerName);
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل أسماء الشركاء'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl1,
                decoration: const InputDecoration(labelText: 'اسم الشريك الأول'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl2,
                decoration: const InputDecoration(labelText: 'اسم الشريك الثاني'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                _data.accounting.partnerName = ctrl1.text.trim().isEmpty ? 'الشريك' : ctrl1.text.trim();
                _data.partnerAccounting.partnerName = ctrl2.text.trim().isEmpty ? 'الشريك' : ctrl2.text.trim();
                _saveData(_data);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('⚠️ حذف كل البيانات'),
          content: const Text('هل أنت متأكد؟ سيتم حذف جميع العملاء والمشاريع والعمال والمحاسبة.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف الكل'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      _saveData(UserData());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف كل البيانات')),
        );
      }
    }
  }

  Future<void> _showFirebaseLoginDialog() async {
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final registerC = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل دخول السحابة'),
          content: StatefulBuilder(
            builder: (ctx, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('سجل الدخول بنفس حساب HTML لمزامنة البيانات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  TextField(controller: emailC, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 8),
                  TextField(controller: passC, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder()), obscureText: true),
                  if (registerC.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextField(controller: registerC, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', border: OutlineInputBorder()), obscureText: true),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          registerC.text = registerC.text.isEmpty ? ' ' : '';
                          setDialogState(() {});
                        },
                        child: Text(registerC.text.isEmpty ? 'مستخدم جديد؟' : 'لدي حساب', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (emailC.text.isEmpty || passC.text.isEmpty) return;
                final isRegister = registerC.text.isNotEmpty;
                String? error;
                if (isRegister) {
                  if (passC.text != registerC.text) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('كلمة المرور غير متطابقة')));
                    return;
                  }
                  error = await _firebase.register(emailC.text, passC.text);
                } else {
                  error = await _firebase.signIn(emailC.text, passC.text);
                }
                if (error != null) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error!)));
                  }
                  return;
                }
                await StorageService().saveFirebaseCredentials(emailC.text, passC.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isRegister ? 'تم إنشاء الحساب وتخزين البيانات محلياً - اضغط استيراد من السحابة لنقل البيانات' : 'تم تسجيل الدخول'), duration: Duration(seconds: 2)),
                  );
                }
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncFromFirebase() async {
    setState(() => _isSyncing = true);
    final cloudData = await _firebase.loadFromFirebase();
    if (cloudData != null) {
      _data = cloudData;
      StorageService().saveUserData(_data);
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد البيانات من السحابة'), duration: Duration(seconds: 2)),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا توجد بيانات في السحابة أو فشل الاتصال'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  void _syncToAccounting() {
    final accRows = <AccountingRow>[];
    int projCount = 0, workerCount = 0;

    for (final weekWorkers in _data.workersByWeek.values) {
      for (final w in weekWorkers) {
        final exp = double.tryParse(w.expenseText) ?? 0;
        if (exp > 0) {
          accRows.add(AccountingRow(expense: exp, note: 'عامل ${w.name}', source: 'worker'));
          workerCount++;
        }
      }
    }

    for (final c in _data.customers) {
      for (final p in c.projects) {
        for (final pm in p.payments) {
          accRows.add(AccountingRow(revenue: pm.amount, note: 'عميل ${c.name} - ${p.name}', source: 'project'));
          projCount++;
        }
      }
    }

    _data.accounting = AccountingData(rows: [..._data.accounting.rows, ...accRows], history: _data.accounting.history, partnerName: _data.accounting.partnerName);
    StorageService().saveUserData(_data);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت المزامنة: ${accRows.length} سطر (${workerCount} عامل + $projCount مشروع)')),
    );
  }

  static Widget _menuItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'toggleAutoSync':
                    _data.autoSync = !_data.autoSync;
                    StorageService().saveUserData(_data);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_data.autoSync ? 'التسجيل التلقائي مفعل' : 'التسجيل التلقائي معطل'), duration: Duration(seconds: 1)),
                    );
                    break;
                  case 'sync':
                    _syncToAccounting();
                    break;
                  case 'export':
                    _exportJson();
                    break;
                  case 'import':
                    _importJson();
                    break;
                  case 'partners':
                    _editPartnerNames();
                    break;
                  case 'firebaseLogin':
                    _showFirebaseLoginDialog();
                    break;
                  case 'firebaseLogout':
                    _firebase.signOut();
                    StorageService().clearFirebaseCredentials();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم تسجيل الخروج من السحابة'), duration: Duration(seconds: 1)),
                    );
                    break;
                  case 'syncFromCloud':
                    _syncFromFirebase();
                    break;
                  case 'reset':
                    _resetAllData();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggleAutoSync',
                  child: Row(
                    children: [
                      Icon(_data.autoSync ? Icons.toggle_on : Icons.toggle_off_outlined, color: _data.autoSync ? Colors.green : Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(_data.autoSync ? 'التسجيل التلقائي: مفعل' : 'التسجيل التلقائي: معطل', style: TextStyle(fontSize: 12, color: _data.autoSync ? Colors.green : Colors.grey[600])),
                    ],
                  ),
                ),
                PopupMenuItem(value: 'sync', child: _menuItem(Icons.sync, 'مزامنة يدوية', const Color(0xFF3B82F6))),
                if (_firebase.isSignedIn)
                  PopupMenuItem(
                    value: 'syncFromCloud',
                    child: _isSyncing
                        ? Row(children: [SizedBox(width:16,height:16,child: CircularProgressIndicator(strokeWidth:2)), SizedBox(width:8), Text('جارٍ التحميل...', style: TextStyle(fontSize:12))])
                        : _menuItem(Icons.cloud_download, 'استيراد من السحابة', const Color(0xFF3B82F6)),
                  ),
                PopupMenuItem(
                  value: _firebase.isSignedIn ? 'firebaseLogout' : 'firebaseLogin',
                  child: _menuItem(
                    _firebase.isSignedIn ? Icons.cloud_off : Icons.cloud,
                    _firebase.isSignedIn ? 'تسجيل خروج السحابة (${_firebase.email})' : 'تسجيل دخول السحابة',
                    const Color(0xFF3B82F6),
                  ),
                ),
                PopupMenuItem(value: 'partners', child: _menuItem(Icons.people, 'تعديل أسماء الشركاء', const Color(0xFF8B5CF6))),
                PopupMenuItem(value: 'export', child: _menuItem(Icons.download, 'تصدير JSON', const Color(0xFF10B981))),
                PopupMenuItem(value: 'import', child: _menuItem(Icons.upload, 'استيراد JSON', const Color(0xFFF59E0B))),
                PopupMenuItem(value: 'reset', child: _menuItem(Icons.delete_forever, 'حذف كل البيانات', const Color(0xFFEF4444))),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            CustomersScreen(
              userData: _data,
              onSave: _saveData,
            ),
            WorkersScreen(
              userData: _data,
              onSave: _saveData,
            ),
            AccountingScreen(
              userData: _data,
              onSave: _saveData,
            ),
            SettlementScreen(
              accounting: _data.accounting,
              partnerAccounting: _data.partnerAccounting,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'العملاء'),
            BottomNavigationBarItem(icon: Icon(Icons.engineering), label: 'العمال'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'المحاسبة'),
            BottomNavigationBarItem(icon: Icon(Icons.balance), label: 'تسوية'),
          ],
        ),
      ),
    );
  }
}

class SettlementScreen extends StatelessWidget {
  final AccountingData accounting;
  final AccountingData partnerAccounting;

  const SettlementScreen({
    super.key,
    required this.accounting,
    required this.partnerAccounting,
  });

  @override
  Widget build(BuildContext context) {
    final p1Profit = accounting.netProfit;
    final p2Profit = partnerAccounting.netProfit;
    final totalProfit = p1Profit + p2Profit;
    final halfShare = totalProfit / 2;
    final diff = (p1Profit - p2Profit).abs() / 2;

    String dirText;
    Color dirColor;
    if (p1Profit > p2Profit) {
      dirText = '${accounting.partnerName} يدفع ${diff.toStringAsFixed(0)} د.ل لـ ${partnerAccounting.partnerName}';
      dirColor = Colors.orange;
    } else if (p2Profit > p1Profit) {
      dirText = '${partnerAccounting.partnerName} يدفع ${diff.toStringAsFixed(0)} د.ل لـ ${accounting.partnerName}';
      dirColor = Colors.orange;
    } else {
      dirText = 'لا توجد فروقات - التسوية متساوية';
      dirColor = Colors.green;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.balance, size: 48, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('تسوية الشراكة', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _card(context, 'إجمالي الربح', totalProfit, Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              _card(context, 'نصيب كل شريك', halfShare, Colors.blue),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تفاصيل الأرباح', style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      _detailRow(context, accounting.partnerName, p1Profit),
                      const SizedBox(height: 8),
                      _detailRow(context, partnerAccounting.partnerName, p2Profit),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: dirColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('صافي التسوية', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Text(dirText, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: dirColor,
                      ), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String label, double value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Text('${value.toStringAsFixed(0)} د.ل', style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold, color: color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String name, double profit) {
    return Row(
      children: [
        Icon(Icons.person, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(name, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        Text('${profit.toStringAsFixed(0)} د.ل', style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600, color: profit >= 0 ? Colors.green : Colors.red,
        )),
      ],
    );
  }
}
