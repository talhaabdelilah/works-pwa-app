import 'package:flutter/material.dart';
import 'package:works_app/models/user_data.dart';
import 'package:works_app/models/customer.dart';
import 'package:works_app/models/project.dart';
import 'package:works_app/models/accounting.dart';
import 'package:works_app/screens/customers/project_detail_screen.dart';

class CustomerProjectsScreen extends StatefulWidget {
  final Customer customer;
  final UserData userData;
  final Function(UserData) onSave;

  const CustomerProjectsScreen({
    super.key,
    required this.customer,
    required this.userData,
    required this.onSave,
  });

  @override
  State<CustomerProjectsScreen> createState() => _CustomerProjectsScreenState();
}

class _CustomerProjectsScreenState extends State<CustomerProjectsScreen> {
  late Customer _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  void _updateCustomer(Customer updated) {
    setState(() => _customer = updated);
    final newList = widget.userData.customers.map((c) => c.id == updated.id ? updated : c).toList();

    if (widget.userData.autoSync) {
      final accRows = widget.userData.accounting.rows.where((r) => r.source != 'project').toList();
      for (final c in newList) {
        for (final p in c.projects) {
          for (final pm in p.payments) {
            accRows.add(AccountingRow(
              revenue: pm.amount,
              note: 'عميل ${c.name} - ${p.name}',
              source: 'project',
            ));
          }
        }
      }
      widget.onSave(UserData(
        customers: newList,
        workersByWeek: widget.userData.workersByWeek,
        accounting: AccountingData(rows: accRows, history: widget.userData.accounting.history, partnerName: widget.userData.accounting.partnerName),
        partnerAccounting: widget.userData.partnerAccounting,
        lastBackupDate: widget.userData.lastBackupDate,
      ));
    } else {
      widget.onSave(UserData(
        customers: newList,
        workersByWeek: widget.userData.workersByWeek,
        accounting: widget.userData.accounting,
        partnerAccounting: widget.userData.partnerAccounting,
        lastBackupDate: widget.userData.lastBackupDate,
      ));
    }
  }

  void _addProject() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة مشروع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المشروع'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'السعر للمتر'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final project = Project(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: nameCtrl.text.trim(),
                  globalPricePerMeter: double.tryParse(priceCtrl.text.trim()) ?? 50,
                );
                final updated = Customer(
                  id: _customer.id,
                  name: _customer.name,
                  phone: _customer.phone,
                  projects: [project, ..._customer.projects],
                );
                _updateCustomer(updated);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProject(Project project) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف مشروع'),
          content: Text('هل أنت متأكد من حذف "${project.name}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final updated = Customer(
                  id: _customer.id,
                  name: _customer.name,
                  phone: _customer.phone,
                  projects: _customer.projects.where((p) => p.id != project.id).toList(),
                );
                _updateCustomer(updated);
                Navigator.pop(ctx);
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_customer.name, style: const TextStyle(fontSize: 13)),
          actions: [
            GestureDetector(
              onTap: _addProject,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('مشروع', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Breadcrumb
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Text('رجوع', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                    ),
                  ),
                  const Spacer(),
                  Text(_customer.name, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  const Text(' / ', style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
                  Text('${_customer.projects.length} مشاريع', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
            ),
            Expanded(
              child: _customer.projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('لا يوجد مشاريع', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _addProject,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text('إضافة مشروع', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: _customer.projects.length,
                      itemBuilder: (_, i) {
                        final project = _customer.projects[i];
                        final remaining = project.remaining;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: const Border(right: BorderSide(color: Color(0xFF3B82F6), width: 3)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProjectDetailScreen(
                                    project: project,
                                    onUpdate: (updated) => _updateProject(updated),
                                    onDelete: () => _deleteProject(project),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(project.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                        const SizedBox(height: 4),
                                        Text('التكلفة: ${project.totalCost.toStringAsFixed(0)}  •  المتبقي: ${remaining.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_left, size: 18, color: Color(0xFFCBD5E1)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addProject,
          child: const Icon(Icons.add, size: 22),
        ),
      ),
    );
  }

  void _updateProject(Project updated) {
    final newProjects = _customer.projects.map((p) => p.id == updated.id ? updated : p).toList();
    final updatedCustomer = Customer(
      id: _customer.id,
      name: _customer.name,
      phone: _customer.phone,
      projects: newProjects,
    );
    _updateCustomer(updatedCustomer);
  }
}
