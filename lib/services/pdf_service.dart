import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart' as intl;
import 'package:project_manager/models/user_data.dart';
import 'package:project_manager/models/accounting.dart';
import 'package:project_manager/models/worker.dart';

class PdfService {
  static pw.Font? _arabicFont;

  static Future<void> init() async {
    if (_arabicFont != null) return;
    final ttf = await rootBundle.load('fonts/NotoNaskhArabic.ttf');
    _arabicFont = pw.Font.ttf(ttf);
  }

  static pw.TextStyle _style(double size, {PdfColor? color, pw.FontWeight? weight}) {
    return pw.TextStyle(
      font: _arabicFont!,
      fontSize: size,
      color: color ?? PdfColors.black,
      fontWeight: weight ?? pw.FontWeight.normal,
    );
  }

  static pw.Widget _txt(String text, {double? size, PdfColor? color, pw.FontWeight? weight}) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(text, style: _style(size ?? 10, color: color, weight: weight)),
    );
  }

  static Future<void> sharePdf(String fileName, pw.Document doc) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: fileName),
    );
  }

  static pw.Widget _header(pw.Context context, String title, String date) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _txt(title, size: 18, weight: pw.FontWeight.bold),
      pw.SizedBox(height: 4),
      _txt(date, size: 10, color: PdfColors.grey600),
      pw.SizedBox(height: 8),
      pw.Divider(),
      pw.SizedBox(height: 8),
    ]);
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(color: PdfColors.blue800, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
      margin: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: _txt(title, size: 13, color: PdfColors.white, weight: pw.FontWeight.bold),
    );
  }

  static pw.Widget _row(String label, String value, {PdfColor? color}) {
    return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      _txt(label, size: 10),
      _txt(value, size: 10, weight: pw.FontWeight.bold, color: color),
    ]);
  }

  static pw.Widget _subRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 16),
      child: _row(label, value),
    );
  }

  static Future<pw.Document> generateEndCyclePdf(UserData data) async {
    await init();
    final now = DateTime.now();
    final date = intl.DateFormat('yyyy/MM/dd HH:mm').format(now);
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) {
        final pages = <pw.Widget>[];

        pages.add(_header(ctx, 'تقرير نهاية الدورة', date));

        // ===== العملاء =====
        if (data.customers.isNotEmpty) {
          pages.add(_sectionTitle('العملاء'));
          for (final c in data.customers) {
            pages.add(_txt(c.name, size: 11, weight: pw.FontWeight.bold));
            if (c.projects.isEmpty) {
              pages.add(pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: _txt('لا توجد مشاريع', size: 9, color: PdfColors.grey600),
              ));
            }
              for (final p in c.projects) {
                final area = p.rooms.where((r) => r.calcMode == 'area').fold(0.0, (s, r) => s + r.meterValue);
                final perim = p.rooms.where((r) => r.calcMode == 'perimeter').fold(0.0, (s, r) => s + r.meterValue);
              pages.add(pw.Container(
                margin: const pw.EdgeInsets.only(left: 16, bottom: 6),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  _txt('مشروع ${p.name}', size: 10, weight: pw.FontWeight.bold, color: PdfColors.blue800),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16),
                    child: pw.Column(children: [
                      if (area > 0) _row('  المساحة:', '${area.toStringAsFixed(2)} م²'),
                      if (perim > 0) _row('  المحيط:', '${perim.toStringAsFixed(2)} م'),
                      _row('  سعر المتر:', '${p.globalPricePerMeter.toStringAsFixed(0)} د.ل'),
                      _row('  إجمالي التكلفة:', '${p.totalCost.toStringAsFixed(0)} د.ل', color: PdfColors.blue800),
                      _row('  الدفعات:', '${p.totalPayments.toStringAsFixed(0)} د.ل', color: PdfColors.green700),
                      _row('  الباقي:', '${p.remaining.toStringAsFixed(0)} د.ل',
                          color: p.remaining > 0 ? PdfColors.red700 : PdfColors.green700),
                    ]),
                  ),
                ]),
              ));
            }
            pages.add(pw.SizedBox(height: 4));
          }
        } else {
          pages.add(_txt('لا يوجد عملاء', size: 10, color: PdfColors.grey600));
        }

        // ===== العمال =====
        if (data.workersByWeek.isNotEmpty) {
          pages.add(_sectionTitle('العمال'));
          final workerNames = <String>{};
          for (final entry in data.workersByWeek.entries) {
            for (final w in entry.value) {
              workerNames.add(w.name);
            }
          }
          for (final name in workerNames.toList()..sort()) {
            double totalDues = 0, totalExp = 0;
            int totalDays = 0;
            final weeks = <MapEntry<String, Worker>>[];
            for (final entry in data.workersByWeek.entries) {
              for (final w in entry.value) {
                if (w.name == name) {
                  weeks.add(MapEntry(entry.key, w));
                }
              }
            }
            weeks.sort((a, b) => b.key.compareTo(a.key));

            pages.add(_txt(name, size: 11, weight: pw.FontWeight.bold));
            for (final week in weeks) {
              final w = week.value;
              final days = Worker.dayKeys.fold(0, (s, d) => s + (w.days[d] == 1 ? 1 : 0));
              final wages = days * w.price;
              final exp = double.tryParse(w.expenseText) ?? 0;
              totalDays += days;
              totalDues += wages;
              totalExp += exp;

              pages.add(pw.Container(
                margin: const pw.EdgeInsets.only(left: 16, bottom: 4),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  _txt('الأسبوع ${week.key}', size: 9, color: PdfColors.grey700),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16),
                    child: pw.Column(children: [
                      _subRow('  أيام العمل:', '$days يوم'),
                      _subRow('  السعر:', '${w.price.toStringAsFixed(0)} د.ل'),
                      _subRow('  المستحق:', '${wages.toStringAsFixed(0)} د.ل'),
                      _subRow('  المصروفات:', '${exp.toStringAsFixed(0)} د.ل'),
                      _subRow('  الصافي:', '${(wages - exp).toStringAsFixed(0)} د.ل'),
                    ]),
                  ),
                ]),
              ));
            }
            pages.add(pw.Container(
              margin: const pw.EdgeInsets.only(left: 16),
              child:               _row('المجموع الكلي لـ $name:', '$totalDays يوم | $totalDues د.ل | مصروفات $totalExp د.ل | صافي ${(totalDues - totalExp).toStringAsFixed(0)} د.ل',
                  color: PdfColors.blue800),
            ));
            pages.add(pw.SizedBox(height: 4));
          }
        } else {
          pages.add(_txt('لا يوجد عمال', size: 10, color: PdfColors.grey600));
        }

        // ===== المحاسبة =====
        for (final isPartner in [false, true]) {
          final acc = isPartner ? data.partnerAccounting : data.accounting;
          pages.add(_sectionTitle('محاسبة ${acc.partnerName}'));

          final revenues = acc.rows.where((r) => r.revenue > 0).toList();
          final expenses = acc.rows.where((r) => r.expense > 0).toList();
          double totalRev = 0, totalExp = 0;

          if (expenses.isNotEmpty) {
            pages.add(_txt('المصروفات', size: 10, weight: pw.FontWeight.bold, color: PdfColors.red800));
            for (final r in expenses) {
              totalExp += r.expense;
              pages.add(_subRow('  ${r.expense.toStringAsFixed(0)} د.ل${r.note.isNotEmpty ? "  -  ${r.note}" : ""}', ''));
            }
          }

          if (revenues.isNotEmpty) {
            pages.add(pw.SizedBox(height: 4));
            pages.add(_txt('الإيرادات', size: 10, weight: pw.FontWeight.bold, color: PdfColors.green800));
            for (final r in revenues) {
              totalRev += r.revenue;
              pages.add(_subRow('  ${r.revenue.toStringAsFixed(0)} د.ل${r.note.isNotEmpty ? "  -  ${r.note}" : ""}', ''));
            }
          }

          if (acc.rows.isEmpty) {
            pages.add(_txt('لا توجد سجلات', size: 10, color: PdfColors.grey600));
          } else {
            pages.add(pw.Divider());
            pages.add(_row('مجموع الإيرادات:', '${totalRev.toStringAsFixed(0)} د.ل', color: PdfColors.green700));
            pages.add(_row('مجموع المصروفات:', '${totalExp.toStringAsFixed(0)} د.ل', color: PdfColors.red700));
            pages.add(_row('صافي الأرباح:', '${(totalRev - totalExp).toStringAsFixed(0)} د.ل', color: PdfColors.blue800));
          }

          // Accounting history
          if (acc.history.isNotEmpty) {
            pages.add(pw.SizedBox(height: 8));
            pages.add(_txt('سجل الأرشفة', size: 10, weight: pw.FontWeight.bold));
            for (final h in acc.history) {
              pages.add(pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16, bottom: 2),
                child: _txt('${h.date} ${h.time}  -  ${h.rowCount} سطور  -  صافي ${(h.summary['netProfit'] ?? 0).toStringAsFixed(0)} د.ل',
                    size: 9, color: PdfColors.grey700),
              ));
            }
          }
        }

        // ===== التسوية =====
        pages.add(_sectionTitle('التسوية'));
        final p1Profit = data.accounting.netProfit;
        final p2Profit = data.partnerAccounting.netProfit;
        final totalProfit = p1Profit + p2Profit;
        final halfShare = totalProfit / 2;
        final diff = (p1Profit - p2Profit).abs() / 2;

        pages.add(_row('ربح ${data.accounting.partnerName}:', '${p1Profit.toStringAsFixed(0)} د.ل'));
        pages.add(_row('ربح ${data.partnerAccounting.partnerName}:', '${p2Profit.toStringAsFixed(0)} د.ل'));
        pages.add(_row('إجمالي الربح:', '${totalProfit.toStringAsFixed(0)} د.ل', color: PdfColors.blue800));
        pages.add(_row('نصيب كل شريك:', '${halfShare.toStringAsFixed(0)} د.ل'));
        pages.add(pw.SizedBox(height: 8));
        if (p1Profit > p2Profit) {
          pages.add(_txt('${data.accounting.partnerName} يدفع ${diff.toStringAsFixed(0)} د.ل إلى ${data.partnerAccounting.partnerName}',
              size: 11, weight: pw.FontWeight.bold, color: PdfColors.orange700));
        } else if (p2Profit > p1Profit) {
          pages.add(_txt('${data.partnerAccounting.partnerName} يدفع ${diff.toStringAsFixed(0)} د.ل إلى ${data.accounting.partnerName}',
              size: 11, weight: pw.FontWeight.bold, color: PdfColors.orange700));
        } else {
          pages.add(_txt('لا توجد فروقات - التسوية متساوية',
              size: 11, weight: pw.FontWeight.bold, color: PdfColors.green700));
        }

        return pages;
      },
    ));
    return doc;
  }

  static Future<pw.Document> generateArchivePdf(ArchiveEntry entry, String partnerName, int index) async {
    await init();
    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(16),
      build: (ctx) => [
        _header(ctx, 'سجل أرشفة - $partnerName', '${entry.date} ${entry.time}'),
        _row('عدد السطور:', '${entry.rowCount}'),
        _row('الإيرادات:', '${(entry.summary['totalRevenue'] ?? 0).toStringAsFixed(0)} د.ل', color: PdfColors.green700),
        _row('المصروفات:', '${(entry.summary['totalExpense'] ?? 0).toStringAsFixed(0)} د.ل', color: PdfColors.red700),
        _row('صافي الربح:', '${(entry.summary['netProfit'] ?? 0).toStringAsFixed(0)} د.ل', color: PdfColors.blue800),
        pw.SizedBox(height: 12),
        pw.Divider(),
        _sectionTitle('تفاصيل السطور'),
        for (final r in entry.rows)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(children: [
              if (r.revenue > 0)
                _txt('إيراد: ${r.revenue.toStringAsFixed(0)} د.ل  ', size: 9, color: PdfColors.green700),
              if (r.expense > 0)
                _txt('مصروف: ${r.expense.toStringAsFixed(0)} د.ل  ', size: 9, color: PdfColors.red700),
              if (r.note.isNotEmpty)
                _txt('- ${r.note}', size: 9, color: PdfColors.grey700),
            ]),
          ),
      ],
    ));
    return doc;
  }
}
