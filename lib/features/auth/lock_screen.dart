import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/providers/database_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final pinController = TextEditingController();
  bool isChecking = false;

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  
  Future<File> _getPinFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'EnterpriseERP'));
    if (!await folder.exists()) await folder.create(recursive: true);
    return File(p.join(folder.path, 'app_pin.txt'));
  }

  Future<void> _unlockApp() async {
    final input = pinController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز القفل أو كلمة المرور'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => isChecking = true);
    try {
      final pinFile = await _getPinFile();
      final db = ref.read(databaseProvider);

      
      if (await pinFile.exists()) {
        final savedPin = (await pinFile.readAsString()).trim();
        if (input == savedPin) {
          if (mounted) context.go('/dashboard');
          return;
        }
      }

      
      final users = await db.select(db.users).get();
      final matchedUser = users.any((u) => u.passwordHash == input);

      if (matchedUser || users.isEmpty) {
        
        if (!await pinFile.exists()) {
          await pinFile.writeAsString(input);
        }
        if (mounted) context.go('/dashboard');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رمز القفل غير صحيح! حاول مرة أخرى'), backgroundColor: Colors.red),
          );
          pinController.clear();
        }
      }
    } finally {
      if (mounted) setState(() => isChecking = false);
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
              theme.colorScheme.primary.withValues(alpha: 0.85),
              const Color(0xFF1A237E),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_clock_rounded, size: 56, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'النظام مقفل مؤقتاً',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'الحسابات والبيانات محمية. أدخل رمز القفل السريع أو كلمة المرور للمتابعة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.bold),
                      onSubmitted: (_) => _unlockApp(),
                      decoration: InputDecoration(
                        hintText: '••••',
                        labelText: 'رمز القفل / كلمة المرور',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.password_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isChecking ? null : _unlockApp,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: const Text('فتح القفل والمتابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('تبديل الحساب / تسجيل الدخول الكامل', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}