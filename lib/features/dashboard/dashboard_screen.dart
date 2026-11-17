import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:fl_chart/fl_chart.dart';

import '../../core/providers/database_provider.dart';
import '../../core/services/google_auth_service.dart';
import '../accounting/reports_screen.dart';
import '../accounting/vouchers_screen.dart';
import '../accounting/accounts_screen.dart';
import '../inventory/shipments_screen.dart';
import '../backup_sync/backup_sync_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  
  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(googleAuthServiceProvider).signOut();
    final dir = await getApplicationDocumentsDirectory();
    final localSession = File(p.join(dir.path, 'EnterpriseERP', 'local_session.json'));
    if (await localSession.exists()) {
      await localSession.delete();
    }
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salesDao = ref.watch(salesDaoProvider);
    final inventoryDao = ref.watch(inventoryDaoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'نظام إدارة المستودعات - Enterprise ERP',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          
          
        IconButton(
  tooltip: 'قفل الشاشة لحماية الحسابات',
  icon: const Icon(Icons.lock_outline_rounded),
  onPressed: () => context.go('/lock'),
),
          StreamBuilder(

            stream: inventoryDao.watchAllRooms(),
            builder: (context, roomsSnapshot) {
              return StreamBuilder(
                stream: salesDao.watchAllInvoices(),
                builder: (context, invoicesSnapshot) {
                  final rooms = roomsSnapshot.data ?? [];
                  final invoices = invoicesSnapshot.data ?? [];

                  final readyRooms = rooms.where((r) => r.status == 'جاهز').toList();
                  final creditInvoices = invoices.where((inv) => inv.paymentType == 'آجل').toList();
                  final totalCreditAmount = creditInvoices.fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);

                  final now = DateTime.now();
                  final overdueInvoices = creditInvoices.where((inv) {
                    final invDate = DateTime.tryParse(inv.date);
                    if (invDate == null) return false;
                    return now.difference(invDate).inDays > 7;
                  }).toList();
                  final totalOverdueAmount = overdueInvoices.fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);

                  int alertCount = 1;
                  if (creditInvoices.isNotEmpty) alertCount++;
                  if (overdueInvoices.isNotEmpty) alertCount++;
                  if (readyRooms.isNotEmpty) alertCount++;

                  return IconButton(
                    tooltip: 'مركز التنبيهات والرقابة الذكية',
                    icon: Badge(
                      label: Text('$alertCount'),
                      backgroundColor: overdueInvoices.isNotEmpty
                          ? Colors.red
                          : (creditInvoices.isNotEmpty || readyRooms.isNotEmpty ? Colors.orange : Colors.blue),
                      child: const Icon(Icons.notifications_active_outlined),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.notifications_active, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('مركز التنبيهات والرقابة الذكية'),
                            ],
                          ),
                          content: SizedBox(
                            width: 470,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (overdueInvoices.isNotEmpty) ...[
                                    ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                                      ),
                                      title: Text(
                                        'ديون متأخرة: ${overdueInvoices.length} فاتورة تجاوزت 7 أيام!',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                      ),
                                      subtitle: Text(
                                        'إجمالي الديون المتأخرة: ${totalOverdueAmount.toStringAsFixed(2)} ريال.',
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        context.push('/sales');
                                      },
                                    ),
                                    const Divider(),
                                  ],
                                  if (creditInvoices.isNotEmpty) ...[
                                    ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.deepOrange,
                                        child: Icon(Icons.account_balance_wallet, color: Colors.white),
                                      ),
                                      title: Text(
                                        'المبيعات الآجلة: ${creditInvoices.length} فاتورة آجلة',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                      ),
                                      subtitle: Text(
                                        'إجمالي قيمة الفواتير الآجلة: ${totalCreditAmount.toStringAsFixed(2)} ريال.',
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                                      },
                                    ),
                                    const Divider(),
                                  ],
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: readyRooms.isNotEmpty ? Colors.green : Colors.grey,
                                      child: const Icon(Icons.meeting_room, color: Colors.white),
                                    ),
                                    title: Text(
                                      readyRooms.isNotEmpty
                                          ? 'غرف جاهزة للبيع: ${readyRooms.length} غرفة'
                                          : 'لا توجد غرف جاهزة للتفريغ حالياً',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: const Text('اضغط للانتقال إلى شاشة إدارة غرف التخمير.'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.push('/rooms');
                                    },
                                  ),
                                  const Divider(),
                                  ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Icon(Icons.cloud_sync, color: Colors.white),
                                    ),
                                    title: const Text('تذكير النسخ الاحتياطي السحابي'),
                                    subtitle: const Text('احفظ نسخة من قاعدة البيانات على Google Drive.'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupSyncScreen()));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),

          
          FutureBuilder<bool>(
            future: () async {
              final dir = await getApplicationDocumentsDirectory();
              return File(p.join(dir.path, 'EnterpriseERP', 'google_session.json')).exists();
            }(),
            builder: (context, snapshot) {
              final isGoogleConnected = snapshot.data ?? false;
              return PopupMenuButton<String>(
                tooltip: 'حساب المستخدم',
                offset: const Offset(0, 50),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          isGoogleConnected ? Icons.cloud_done : Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مدير النظام',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            isGoogleConnected ? 'مرتبط بـ Google Drive' : 'حساب محلي',
                            style: TextStyle(
                              fontSize: 11,
                              color: isGoogleConnected ? Colors.greenAccent : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'backup') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupSyncScreen()));
                  } else if (value == 'logout') {
                    await _performLogout(context, ref); 
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      isGoogleConnected ? 'الحالة: متصل بالسحابة ✅' : 'الحالة: وضع محلي (Offline)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'backup',
                    child: Row(children: [Icon(Icons.backup, size: 20), SizedBox(width: 10), Text('النسخ الاحتياطي والمزامنة')]),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [Icon(Icons.logout, color: Colors.red, size: 20), SizedBox(width: 10), Text('تسجيل الخروج', style: TextStyle(color: Colors.red))]),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref, theme),
      body: StreamBuilder(
        stream: salesDao.watchAllInvoices(),
        builder: (context, salesSnap) {
          return StreamBuilder(
            stream: inventoryDao.watchAllRooms(),
            builder: (context, roomsSnap) {
              final invoices = salesSnap.data ?? [];
              final rooms = roomsSnap.data ?? [];

              final totalSales = invoices.fold<double>(0.0, (sum, inv) => sum + inv.totalAmount);
              final creditSales = invoices.where((i) => i.paymentType == 'آجل').fold<double>(0.0, (sum, i) => sum + i.totalAmount);
              final cashSales = totalSales - creditSales;

              final readyRooms = rooms.where((r) => r.status == 'جاهز').length;
              final fermentingRooms = rooms.where((r) => r.status != 'جاهز' && r.status != 'فارغ').length;
              final emptyRooms = rooms.where((r) => r.status == 'فارغ').length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوحة التحكم والتحليلات التنفيذية',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'نظرة شاملة ومباشرة على حركة المبيعات، الديون، وحالة غرف التخمير',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 12,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => context.push('/pos'),
                              icon: const Icon(Icons.point_of_sale),
                              label: const Text('نقطة البيع (POS)', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => context.push('/rooms'),
                              icon: const Icon(Icons.meeting_room),
                              label: const Text('إدارة الغرف', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModernKpiCard(
                            title: 'إجمالي المبيعات',
                            value: '${totalSales.toStringAsFixed(2)} ريال',
                            subtitle: 'نقدي: ${cashSales.toStringAsFixed(0)} ريال',
                            icon: Icons.trending_up_rounded,
                            accentColor: const Color(0xFF00897B),
                            badgeText: '${invoices.length} فاتورة',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernKpiCard(
                            title: 'المبيعات الآجلة (الديون)',
                            value: '${creditSales.toStringAsFixed(2)} ريال',
                            subtitle: 'مستحقات لدى العملاء',
                            icon: Icons.account_balance_wallet_rounded,
                            accentColor: const Color(0xFFE53935),
                            badgeText: 'متابعة التحصيل',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernKpiCard(
                            title: 'غرف التخمير الجاهزة',
                            value: '$readyRooms / ${rooms.length} غرفة',
                            subtitle: 'قيد التخمير: $fermentingRooms غرفة',
                            icon: Icons.meeting_room_rounded,
                            accentColor: const Color(0xFFFB8C00),
                            badgeText: readyRooms > 0 ? 'جاهز للبيع' : 'قيد المتابعة',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModernKpiCard(
                            title: 'كفاءة التشغيل والمخزون',
                            value: rooms.isEmpty
                                ? '0%'
                                : '${(((readyRooms + fermentingRooms) / rooms.length) * 100).toStringAsFixed(0)}%',
                            subtitle: 'غرف فارغة متاحة: $emptyRooms',
                            icon: Icons.pie_chart_rounded,
                            accentColor: const Color(0xFF1E88E5),
                            badgeText: 'نشط',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 360,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('تحليل تدفق المبيعات والإيرادات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text('مؤشر نمو المبيعات حسب الفواتير المسجلة', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'مباشر • Live',
                                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Expanded(
                                  child: _buildSalesLineChart(invoices, theme.colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 360,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('توزيع حالات غرف التخمير', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('نسبة الجاهزية والتشغيل الفعلي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _buildRoomsDonutChart(readyRooms, fermentingRooms, emptyRooms),
                                ),
                                const SizedBox(height: 12),
                                _buildLegendRow('جاهز للبيع', readyRooms, Colors.green),
                                const SizedBox(height: 6),
                                _buildLegendRow('قيد التخمير', fermentingRooms, Colors.orange),
                                const SizedBox(height: 6),
                                _buildLegendRow('فارغ', emptyRooms, Colors.grey.shade400),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('أحدث فواتير المبيعات المسجلة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: () => context.push('/sales'),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: const Text('عرض السجل الكامل'),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (invoices.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'لا توجد فواتير مسجلة حتى الآن. ابدأ بإصدار أول فاتورة من نقطة البيع (POS).',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FC)),
                                columns: const [
                                  DataColumn(label: Text('رقم الفاتورة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('نوع الدفع', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الضريبة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: invoices.reversed.take(5).map((inv) {
                                  final isCredit = inv.paymentType == 'آجل';
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('#${inv.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(inv.date.split('T').first)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isCredit ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            inv.paymentType,
                                            style: TextStyle(
                                              color: isCredit ? Colors.red : Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text('${inv.taxAmount.toStringAsFixed(2)} ريال')),
                                      DataCell(Text('${inv.totalAmount.toStringAsFixed(2)} ريال', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSalesLineChart(List<dynamic> invoices, Color primaryColor) {
    final List<FlSpot> spots = invoices.isEmpty
        ? const [
            FlSpot(1, 1200),
            FlSpot(2, 2400),
            FlSpot(3, 1900),
            FlSpot(4, 3600),
            FlSpot(5, 3100),
            FlSpot(6, 4800),
          ]
        : invoices.take(10).toList().asMap().entries.map((entry) {
            return FlSpot((entry.key + 1).toDouble(), entry.value.totalAmount);
          }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('حركة ${value.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toInt().toString(),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.28),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsDonutChart(int ready, int fermenting, int empty) {
    final total = ready + fermenting + empty;
    final hasData = total > 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 46,
            sections: hasData
                ? [
                    PieChartSectionData(value: ready.toDouble(), color: Colors.green, radius: 22, showTitle: false),
                    PieChartSectionData(value: fermenting.toDouble(), color: Colors.orange, radius: 22, showTitle: false),
                    PieChartSectionData(value: empty.toDouble(), color: Colors.grey.shade300, radius: 22, showTitle: false),
                  ]
                : [
                    PieChartSectionData(value: 1, color: Colors.grey.shade200, radius: 22, showTitle: false),
                  ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('غرفة', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildModernKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(right: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 26, color: accentColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(badgeText, style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.storefront, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text('إدارة تجارة الموز', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard, color: theme.colorScheme.secondary),
            title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.bold)),
            selected: true,
            selectedTileColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: Icon(Icons.inventory, color: theme.colorScheme.primary),
            title: const Text('المخزون والغرف'),
            onTap: () {
              Navigator.pop(context);
              context.push('/rooms');
            },
          ),
          ListTile(
            leading: Icon(Icons.point_of_sale, color: theme.colorScheme.primary),
            title: const Text('المبيعات والفواتير'),
            onTap: () {
              Navigator.pop(context);
              context.push('/sales');
            },
          ),
          ListTile(
            leading: Icon(Icons.local_shipping, color: theme.colorScheme.primary),
            title: const Text('إدارة الشحنات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ShipmentsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.account_tree, color: theme.colorScheme.primary),
            title: const Text('شجرة الحسابات المالية'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountsScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt_long, color: theme.colorScheme.primary),
            title: const Text('سندات القبض والصرف'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const VouchersScreen()));
            },
          ),
          ListTile(
            leading: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
            title: const Text('التقارير وكشوفات الحساب'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.backup, color: theme.colorScheme.primary),
            title: const Text('النسخ الاحتياطي والاستعادة'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupSyncScreen()));
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _performLogout(context, ref), 
          ),
        ],
      ),
    );
  }
}