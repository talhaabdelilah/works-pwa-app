import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:share_plus/share_plus.dart';
import 'package:project_manager/services/storage_service.dart';
import 'package:project_manager/services/file_picker_service.dart';
import 'package:project_manager/services/firebase_sync_service.dart';
import 'package:project_manager/models/user_data.dart';
import 'package:project_manager/models/accounting.dart';
import 'package:project_manager/services/pdf_service.dart';
import 'package:project_manager/screens/customers/customers_screen.dart';
import 'package:project_manager/screens/workers/workers_screen.dart';
import 'package:project_manager/screens/accounting/accounting_screen.dart';

class MainScreen extends StatefulWidget {
  final UserData userData;

  const MainScreen({super.key, required this.userData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  UserData _data = UserData();
  final _firebase = FirebaseSyncService();
  bool _isSyncing = false;

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

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => setState(() {}));
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

  Future<void> _exportPdf() async {
    try {
      final doc = await PdfService.generateEndCyclePdf(_data);
      final now = DateTime.now();
      final date = intl.DateFormat('yyyy-MM-dd_HHmm').format(now);
      await PdfService.sharePdf('تقرير_البيانات_$date.pdf', doc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تصدير PDF: $e'), backgroundColor: Colors.red),
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
              child: const Text('لصق نص'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'file'),
              child: const Text('اختيار ملف'),
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

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف كل البيانات'),
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

  @override
  Widget build(BuildContext context) {
    final workersCount = _data.workersByWeek.values.expand((list) => list).length;
    final customersCount = _data.customers.length;
    final projectsCount = _data.customers.expand((c) => c.projects).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدير المشاريع'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _exportJson();
                    break;
                  case 'exportPdf':
                    _exportPdf();
                    break;
                  case 'import':
                    _importJson();
                    break;
                  case 'reset':
                    _resetAllData();
                    break;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'export', child: _menuItem(Icons.download, 'تصدير JSON', const Color(0xFF10B981))),
                PopupMenuItem(value: 'exportPdf', child: _menuItem(Icons.picture_as_pdf, 'تصدير PDF', const Color(0xFFEF4444))),
                PopupMenuItem(value: 'import', child: _menuItem(Icons.upload, 'استيراد JSON', const Color(0xFFF59E0B))),
                PopupMenuItem(value: 'reset', child: _menuItem(Icons.delete_forever, 'حذف كل البيانات', const Color(0xFFEF4444))),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرحباً بك',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'نظرة عامة على أعمالك',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildStatCard('العمال', '$workersCount', Icons.engineering, const Color(0xFF3B82F6))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('العملاء', '$customersCount', Icons.people, const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('المشاريع', '$projectsCount', Icons.work, const Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 24),
              const Text('الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildNavigationCard(
                title: 'العملاء والمشاريع',
                subtitle: 'إدارة العملاء والمشاريع và التفاصيل',
                icon: Icons.people,
                color: const Color(0xFF10B981),
                onTap: () => _navigateTo(CustomersScreen(userData: _data, onSave: _saveData)),
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(
                title: 'العمال',
                subtitle: 'جدول الحضور والانصراف الأسبوعي',
                icon: Icons.engineering,
                color: const Color(0xFF3B82F6),
                onTap: () => _navigateTo(WorkersScreen(userData: _data, onSave: _saveData)),
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(
                title: 'المحاسبة',
                subtitle: 'الإيرادات والمصروفات والأرباح',
                icon: Icons.account_balance,
                color: const Color(0xFF8B5CF6),
                onTap: () => _navigateTo(AccountingScreen(userData: _data, onSave: _saveData)),
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(
                title: 'تسوية الشراكة',
                subtitle: 'حساب نصيب كل شريك',
                icon: Icons.balance,
                color: const Color(0xFFF59E0B),
                onTap: () => _navigateTo(SettlementScreen(
                  accounting: _data.accounting,
                  partnerAccounting: _data.partnerAccounting,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
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
        appBar: AppBar(title: const Text('تسوية الشراكة')),
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
        const Icon(Icons.person, size: 20, color: Colors.grey),
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
