import 'package:flutter/material.dart';
import 'package:works_app/models/user_data.dart';
import 'package:works_app/models/customer.dart';
import 'package:works_app/models/project.dart';
import 'package:works_app/screens/customers/customer_projects_screen.dart';

class CustomersScreen extends StatefulWidget {
  final UserData userData;
  final Function(UserData) onSave;

  const CustomersScreen({super.key, required this.userData, required this.onSave});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  void _addCustomer() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة عميل'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم العميل'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final newCustomer = Customer(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                final updated = UserData(
                  customers: [newCustomer, ...widget.userData.customers],
                  workersByWeek: widget.userData.workersByWeek,
                  accounting: widget.userData.accounting,
                  partnerAccounting: widget.userData.partnerAccounting,
                  lastBackupDate: widget.userData.lastBackupDate,
                );
                widget.onSave(updated);
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف عميل'),
          content: Text('هل أنت متأكد من حذف "${customer.name}"؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final updated = UserData(
                  customers: widget.userData.customers.where((c) => c.id != customer.id).toList(),
                  workersByWeek: widget.userData.workersByWeek,
                  accounting: widget.userData.accounting,
                  partnerAccounting: widget.userData.partnerAccounting,
                  lastBackupDate: widget.userData.lastBackupDate,
                );
                widget.onSave(updated);
                Navigator.pop(ctx);
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _addProjectForCustomer(Customer customer) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إضافة مشروع لـ ${customer.name}'),
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
                  id: customer.id,
                  name: customer.name,
                  phone: customer.phone,
                  projects: [project, ...customer.projects],
                );
                final newList = widget.userData.customers.map((c) => c.id == updated.id ? updated : c).toList();
                widget.onSave(UserData(
                  customers: newList,
                  workersByWeek: widget.userData.workersByWeek,
                  accounting: widget.userData.accounting,
                  partnerAccounting: widget.userData.partnerAccounting,
                  lastBackupDate: widget.userData.lastBackupDate,
                ));
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
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text('📂 قائمة العملاء', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addCustomer,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('عميل جديد', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.userData.customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('لا يوجد عملاء', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addCustomer,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('إضافة عميل'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {},
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemCount: widget.userData.customers.length,
                      itemBuilder: (_, i) {
                        final customer = widget.userData.customers[i];
                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerProjectsScreen(
                                    customer: customer,
                                    userData: widget.userData,
                                    onSave: widget.onSave,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      customer.name.isNotEmpty ? customer.name[0] : '?',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(customer.name, style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${customer.phone}  •  ${customer.projects.length} مشاريع',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[300]),
                                    onPressed: () => _deleteCustomer(customer),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
