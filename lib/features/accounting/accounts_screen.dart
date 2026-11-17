import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final codeController = TextEditingController();
  final nameController = TextEditingController();
String selectedType = 'الأصول النقدية (صندوق/بنك)';   
  int? selectedParentId;         
final List<String> accountTypes = [
    'الأصول النقدية (صندوق/بنك)',
    'حسابات العملاء',
    'حسابات الموردين',
    'المصاريف التشغيلية (نقل، عمالة)',
    'إيرادات المبيعات',
  ];

  @override
  void dispRose() {
    codeController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountDao = ref.watch(accountDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل شجرة الحسابات المالية'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إضافة حساب جديد', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'رقم الحساب (الكود)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.code),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم الحساب',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'تصنيف الحساب (النوع)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: accountTypes.map((type) {
                          return DropdownMenuItem(value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _saveAccount(context),
                        icon: const Icon(Icons.add_circle),
                        label: const Text('حفظ الحساب في الدليل'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('دليل الحسابات المسجلة', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Divider(),
                      const SizedBox(height: 8),
                      
                      Expanded(
                        child: StreamBuilder<List<Account>>(
                          stream: accountDao.watchAllAccounts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final accounts = snapshot.data ?? [];

                            if (accounts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.account_tree_outlined, size: 80, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    const Text('لا توجد حسابات مضافة حتى الآن', style: TextStyle(color: Colors.grey, fontSize: 18)),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: accounts.length,
                              itemBuilder: (context, index) {
                                final acc = accounts[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                      child: Text(acc.code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                    ),
                                    title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('التصنيف: ${acc.type}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () async {
                                        await accountDao.deleteAccount(acc.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('تم حذف الحساب بنجاح'), backgroundColor: Colors.red),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Future<void> _saveAccount(BuildContext context) async {
    if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم و اسم الحساب'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final accountDao = ref.read(accountDaoProvider);

      await accountDao.insertAccount(
        AccountsCompanion.insert(
          code: codeController.text.trim(),
          name: nameController.text.trim(),
          type: selectedType,
          parentId: drift.Value(selectedParentId),
          isActive: const drift.Value(true),
        ),
      );

      codeController.clear();
      nameController.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الحساب بنجاح إلى الشجرة!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ (تأكد أن كود الحساب غير مكرر): $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}