import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers/database_provider.dart';
import '../../core/database/app_database.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryDao = ref.watch(inventoryDaoProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة غرف التخمير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'إضافة غرفة',
            onPressed: () => _showAddRoomDialog(context, inventoryDao),
          ),
          const SizedBox(width: 16),
        ],
      ),
      
      body: StreamBuilder<List<Room>>(
        stream: inventoryDao.watchAllRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.door_front_door_outlined, size: 80, color: theme.colorScheme.secondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('لا توجد غرف مضافة حالياً.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRoomDialog(context, inventoryDao),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة غرفة جديدة'),
                  )
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, 
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('غرفة ${room.roomNumber}', 
                            style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
                          Icon(Icons.meeting_room, color: theme.colorScheme.secondary),
                        ],
                      ),
                      const Divider(),
                      Text('الطابق: ${room.floorNumber}', style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(room.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: _getStatusColor(room.status),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'جاهز': return Colors.green.shade100;
      case 'قيد التخمير': return Colors.orange.shade100;
      case 'أخضر': return Colors.blue.shade100;
      default: return Colors.grey.shade200;
    }
  }

  
  void _showAddRoomDialog(BuildContext context, dynamic inventoryDao) {
    final roomNumberController = TextEditingController();
    final floorNumberController = TextEditingController();
    String selectedStatus = 'جاهز';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة غرفة تخمير جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomNumberController,
                decoration: const InputDecoration(labelText: 'رقم الغرفة', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: floorNumberController,
                decoration: const InputDecoration(labelText: 'رقم الطابق', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'حالة الغرفة', border: OutlineInputBorder()),
                items: ['جاهز', 'أخضر', 'قيد التخمير'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedStatus = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final roomNum = int.tryParse(roomNumberController.text);
                final floorNum = int.tryParse(floorNumberController.text);

                if (roomNum != null && floorNum != null) {
                  await inventoryDao.insertRoom(
                    RoomsCompanion(
                      roomNumber: drift.Value(roomNum),
                      floorNumber: drift.Value(floorNum),
                      status: drift.Value(selectedStatus),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ الغرفة'),
            ),
          ],
        );
      },
    );
  }
}