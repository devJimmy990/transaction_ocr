import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:local_ocr/core/helper/service_locator.dart';
import 'package:local_ocr/cubit/screenshot/screenshot_cubit.dart';
import 'package:local_ocr/cubit/screenshot/screenshot_state.dart';
import 'package:local_ocr/cubit/transaction_ocr/transaction_cubit.dart';
import 'package:local_ocr/presentation/screens/transactions_screen.dart';

class ScreenshotControlScreen extends StatelessWidget {
  const ScreenshotControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ScreenshotCubit>()..checkPermissions(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Screenshot OCR Service'),
          actions: [
            IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => BlocProvider.value(
                          value: sl<TransactionCubit>(),
                          child: const TransactionsScreen(),
                        ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<ScreenshotCubit, ScreenshotState>(
          listener: (context, state) {
            if (state.isServiceRunning) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ تم بدء خدمة التقاط الشاشة'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              // ✅ Show message when service stops
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ تم إيقاف خدمة التقاط الشاشة'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            FlutterOverlayWindow.isActive().then((isActive) {
              print(
                'debug: Overlay Status: running=${state.isServiceRunning}, active=$isActive, permissions=${state.hasPermissions}',
              );
            });
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'حالة الخدمة:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        state.isServiceRunning
                                            ? Colors.green
                                            : Colors.grey,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    state.isServiceRunning ? 'نشطة' : 'متوقفة',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الأذونات:'),
                                Icon(
                                  state.hasPermissions
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color:
                                      state.hasPermissions
                                          ? Colors.green
                                          : Colors.red,
                                  size: 28,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    BlocBuilder<TransactionCubit, dynamic>(
                      builder: (context, ocrState) {
                        return Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'الإحصائيات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'ناجح',
                                      state.successCount,
                                      Colors.green,
                                      Icons.check_circle,
                                    ),
                                    _buildStatItem(
                                      'فاشل',
                                      state.failedCount,
                                      Colors.red,
                                      Icons.error,
                                    ),
                                    _buildStatItem(
                                      'الإجمالي',
                                      ocrState.statistics['total'] ?? 0,
                                      Colors.blue,
                                      Icons.list,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    if (!state.hasPermissions)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.security, size: 28),
                        label: const Text(
                          'منح الأذونات',
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: () async {
                          await context
                              .read<ScreenshotCubit>()
                              .requestPermissions();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),

                    if (state.hasPermissions)
                      ElevatedButton.icon(
                        icon: Icon(
                          state.isServiceRunning
                              ? Icons.stop
                              : Icons.play_arrow,
                          size: 28,
                        ),
                        label: Text(
                          state.isServiceRunning
                              ? 'إيقاف الخدمة'
                              : 'بدء التقاط الشاشة',
                          style: const TextStyle(fontSize: 18),
                        ),
                        onPressed: () async {
                          // في debug print، استبدل بهذا:
                          print(
                            'debug: isServiceRunning=${state.isServiceRunning}, hasPermissions=${state.hasPermissions}, isOverlayActive=${await FlutterOverlayWindow.isActive()}',
                          );
                          if (state.isServiceRunning) {
                            await context
                                .read<ScreenshotCubit>()
                                .closeOverlay();
                          } else {
                            final success =
                                await context
                                    .read<ScreenshotCubit>()
                                    .startOverlay();
                            if (!success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'فشل في بدء الخدمة. تأكد من منح جميع الأذونات',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor:
                              state.isServiceRunning
                                  ? Colors.red
                                  : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),

                    const SizedBox(height: 16),

                    if (!state.isServiceRunning && state.hasPermissions)
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'كيفية الاستخدام:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInstructionStep(
                                '1',
                                'اضغط "بدء التقاط الشاشة"',
                              ),
                              _buildInstructionStep(
                                '2',
                                'امنح إذن التقاط الشاشة',
                              ),
                              _buildInstructionStep(
                                '3',
                                'سيظهر overlay على الشاشة',
                              ),
                              _buildInstructionStep(
                                '4',
                                'اضغط الزرار الأزرق لالتقاط',
                              ),
                              _buildInstructionStep(
                                '5',
                                'اضغط مطولاً لإيقاف الخدمة',
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.list_alt),
                      label: const Text(
                        'عرض المعاملات',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => BlocProvider.value(
                                  value: sl<TransactionCubit>(),
                                  child: const TransactionsScreen(),
                                ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

// Widget _buildCounter(String label, int count, Color color) {
//   return CircleAvatar(
//     radius: 10,
//     backgroundColor: color,
//     child: Center(
//       child: Text(
//         '$count',
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//           fontSize: 14,
//         ),
//       ),
//     ),
//   );
// }
