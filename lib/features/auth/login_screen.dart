import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/services/google_auth_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  bool isLoading = false;
  bool isRegisterMode = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    super.dispose();
  }

  Future<void> _saveLocalSession(String username) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'EnterpriseERP'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final file = File(p.join(folder.path, 'local_session.json'));
    await file.writeAsString('{"username": "$username", "loggedIn": true}');
  }

  
  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      await ref.read(googleAuthServiceProvider).signInWithGoogle();
      if (!mounted) return;
      context.go('/lock'); 
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر الربط بحساب Google: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  
  Future<void> _handleLocalAuth() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final fullName = fullNameController.text.trim();

    if (username.isEmpty || password.isEmpty || (isRegisterMode && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول المطلوبة'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final db = ref.read(databaseProvider);

      if (isRegisterMode) {
        await db.into(db.users).insert(
              UsersCompanion.insert(
                name: fullName,
                username: username,
                passwordHash: password,
                role: 'admin',
              ),
            );

        await _saveLocalSession(username);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الحساب بنجاح!'), backgroundColor: Colors.green),
        );
        context.go('/lock'); 
      } else {
        final users = await (db.select(db.users)
              ..where((u) => u.username.equals(username))
              ..where((u) => u.passwordHash.equals(password)))
            .get();

        if (users.isNotEmpty) {
          await _saveLocalSession(username);
          if (!mounted) return;
          context.go('/lock'); 
        } else {
          final allUsers = await db.select(db.users).get();
          if (allUsers.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لا يوجد حساب مسجل بعد، يرجى إنشاء حساب أولاً'), backgroundColor: Colors.orange),
            );
            setState(() => isRegisterMode = true);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('اسم المستخدم أو كلمة المرور غير صحيحة'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
              const Color(0xFF1A237E),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 10,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRegisterMode ? Icons.person_add_alt_1_rounded : Icons.lock_person_rounded,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isRegisterMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول للنظام',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegisterMode
                            ? 'أنشئ حسابك المحلي لإدارة المستودع والمبيعات'
                            : 'سجّل دخولك لربط حسابك السحابي وإدارة العمليات',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.cloud_done),
                          label: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'الدخول والربط بحساب Google Drive',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('أو الدخول المحلي', style: TextStyle(color: Colors.grey)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),

                      if (isRegisterMode) ...[
                        TextField(
                          controller: fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم الكامل (مثال: مدير النظام)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isLoading ? null : _handleLocalAuth,
                          child: Text(
                            isRegisterMode ? 'إنشاء الحساب والدخول' : 'تسجيل الدخول (بدون مزامنة سحابية)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  isRegisterMode = !isRegisterMode;
                                });
                              },
                        child: Text(
                          isRegisterMode
                              ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                              : 'ليس لديك حساب؟ إنشاء حساب جديد',
                          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}