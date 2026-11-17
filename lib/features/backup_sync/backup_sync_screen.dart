import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupSyncScreen extends ConsumerStatefulWidget {
  const BackupSyncScreen({super.key});

  @override
  ConsumerState<BackupSyncScreen> createState() => _BackupSyncScreenState();
}

class _BackupSyncScreenState extends ConsumerState<BackupSyncScreen> {
  bool isProcessing = false;
  String? lastStatusMessage;

  
  static const String _clientId = "YOUR_CLIENT_ID_HERE";
  static const String _clientSecret="REMOVED_SECRET";

  
  Future<File> _getDatabaseFile() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'EnterpriseERP', 'erp_system_v4.sqlite'));
    return file;
  }

  
  Future<void> _createLocalBackup() async {
    setState(() {
      isProcessing = true;
      lastStatusMessage = null;
    });

    try {
      final dbFile = await _getDatabaseFile();
      if (!await dbFile.exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود في: ${dbFile.path}');
      }

      String? selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'اختر مجلد حفظ النسخة الاحتياطية',
      );

      if (selectedDirectory == null) {
        setState(() => isProcessing = false);
        return;
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupFileName = 'banana_erp_backup_$timestamp.sqlite';
      final destinationPath = p.join(selectedDirectory, backupFileName);

      await dbFile.copy(destinationPath);

      setState(() {
        lastStatusMessage = 'تم حفظ النسخة الاحتياطية محلياً بنجاح في:\n$destinationPath';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية المحلية بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => lastStatusMessage = 'فشل الحفظ المحلي: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  
  Future<void> _uploadToGoogleDrive() async {
    setState(() {
      isProcessing = true;
      lastStatusMessage = 'جاري فتح المتصفح لتسجيل الدخول إلى Google Drive...';
    });

    try {
      final dbFile = await _getDatabaseFile();
      if (!await dbFile.exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود في: ${dbFile.path}');
      }

      final id = ClientId(_clientId, _clientSecret);
      final scopes = [drive.DriveApi.driveFileScope];

      
      final authClient = await clientViaUserConsent(id, scopes, (url) async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('تعذر فتح المتصفح للمصادقة: $url');
        }
      });

      setState(() => lastStatusMessage = 'تم تسجيل الدخول! جاري رفع قاعدة البيانات إلى Google Drive...');

      final driveApi = drive.DriveApi(authClient);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];

      final driveFile = drive.File()
        ..name = 'EnterpriseERP_Backup_$timestamp.sqlite'
        ..description = 'نسخة احتياطية لنظام إدارة تجارة الموز والتخمير';

      final media = drive.Media(dbFile.openRead(), await dbFile.length());
      final uploadedFile = await driveApi.files.create(driveFile, uploadMedia: media);

      authClient.close();

      setState(() {
        lastStatusMessage = 'تم رفع النسخة الاحتياطية بنجاح إلى Google Drive!\nاسم الملف السحابي: ${uploadedFile.name}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت المزامنة والرفع إلى Google Drive بنجاح!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => lastStatusMessage = 'حدث خطأ أثناء الرفع إلى Google Drive:\n$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الرفع السحابي: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  
  Future<void> _restoreLocalBackup() async {
    setState(() {
      isProcessing = true;
      lastStatusMessage = null;
    });

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية (.sqlite)',
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        setState(() => isProcessing = false);
        return;
      }

      final backupFile = File(result.files.single.path!);
      final dbFile = await _getDatabaseFile();

      await backupFile.copy(dbFile.path);

      setState(() {
        lastStatusMessage = 'تمت استعادة البيانات بنجاح! يُرجى إعادة تشغيل البرنامج لتحديث كافة الشاشات.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت الاستعادة بنجاح! أعد تشغيل البرنامج لتطبيق البيانات.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => lastStatusMessage = 'فشلت عملية الاستعادة: $e');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي والمزامنة السحابية'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_sync, size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'إدارة أمان البيانات والنسخ الاحتياطي',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'احفظ نسخة محلية على جهازك أو ارفع نسخة مشفرة مباشرة إلى حسابك في Google Drive لضمان حماية بياناتك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                    const Divider(height: 40),

                    if (isProcessing)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _uploadToGoogleDrive,
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('رفع نسخة احتياطية إلى Google Drive الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: _createLocalBackup,
                                  icon: const Icon(Icons.save_alt),
                                  label: const Text('حفظ نسخة على الجهاز', style: TextStyle(fontSize: 15)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                                  ),
                                  onPressed: _restoreLocalBackup,
                                  icon: const Icon(Icons.restore),
                                  label: const Text('استعادة نسخة من الجهاز', style: TextStyle(fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    if (lastStatusMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          lastStatusMessage!,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
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