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
          title: Text(_customer.name),
          actions: [
            TextButton.icon(
              onPressed: _addProject,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('مشروع', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
        body: _customer.projects.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('لا يوجد مشاريع', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addProject,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('إضافة مشروع'),
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
                  return Dismissible(
                    key: ValueKey(project.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      _deleteProject(project);
                      return false;
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(project.name),
                        subtitle: Text(
                          'التكلفة: ${project.totalCost.toStringAsFixed(0)}  •  المتبقي: ${remaining.toStringAsFixed(0)}',
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailScreen(
                                project: project,
                                onUpdate: (updated) => _updateProject(updated),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addProject,
          child: const Icon(Icons.add),
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
