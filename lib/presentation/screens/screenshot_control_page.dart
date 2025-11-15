// import 'package:flutter/material.dart';
// import 'package:local_ocr/core/screenshot_service.dart';
// import 'package:local_ocr/presentation/screens/failed_transactions.dart';

// class ScreenshotControlPage extends StatefulWidget {
//   const ScreenshotControlPage({super.key});

//   @override
//   State<ScreenshotControlPage> createState() => _ScreenshotControlPageState();
// }

// class _ScreenshotControlPageState extends State<ScreenshotControlPage> {
//   bool _isServiceRunning = false;
//   bool _hasOverlayPermission = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkStatus();

//     // Listen to service status
//     ScreenshotService.statusStream.listen((status) {
//       if (mounted) {
//         setState(() {
//           _isServiceRunning = status == ServiceStatus.running;
//         });
//       }
//     });
//   }

//   Future<void> _checkStatus() async {
//     final permissions = await ScreenshotService.checkPermissions();
//     final isRunning = await ScreenshotService.isServiceRunning();

//     setState(() {
//       _hasOverlayPermission = permissions['overlay'] ?? false;
//       _isServiceRunning = isRunning;
//     });
//   }

//   Future<void> _requestPermission() async {
//     await ScreenshotService.requestOverlayPermission();
//     await Future.delayed(Duration(seconds: 1));
//     _checkStatus();
//   }

//   Future<void> _startService() async {
//     final success = await ScreenshotService.startService();
//     if (success) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Screenshot service started')));
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to start service')));
//     }
//   }

//   Future<void> _stopService() async {
//     await ScreenshotService.stopService();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Screenshot Service'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.error_outline),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => FailedScreenshotsPage(),
//                 ),
//               );
//             },
//             tooltip: 'View Failed Screenshots',
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Status Card
//             Card(
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Service Status:'),
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color:
//                                 _isServiceRunning ? Colors.green : Colors.grey,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             _isServiceRunning ? 'Running' : 'Stopped',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Overlay Permission:'),
//                         Icon(
//                           _hasOverlayPermission
//                               ? Icons.check_circle
//                               : Icons.cancel,
//                           color:
//                               _hasOverlayPermission ? Colors.green : Colors.red,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: 16),

//             // Statistics
//             Card(
//               child: Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Statistics',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         _buildStatItem(
//                           'Success',
//                           ScreenshotService.successCount,
//                           Colors.green,
//                         ),
//                         _buildStatItem(
//                           'Failed',
//                           ScreenshotService.failedCount,
//                           Colors.red,
//                         ),
//                         _buildStatItem(
//                           'Queue',
//                           ScreenshotService.queueLength,
//                           Colors.blue,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             SizedBox(height: 24),

//             // Permission Button
//             if (!_hasOverlayPermission)
//               ElevatedButton.icon(
//                 icon: Icon(Icons.security),
//                 label: Text('Grant Overlay Permission'),
//                 onPressed: _requestPermission,
//                 style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
//               ),

//             // Start/Stop Button
//             if (_hasOverlayPermission)
//               ElevatedButton.icon(
//                 icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
//                 label: Text(
//                   _isServiceRunning ? 'Stop Service' : 'Start Service',
//                 ),
//                 onPressed: _isServiceRunning ? _stopService : _startService,
//                 style: ElevatedButton.styleFrom(
//                   padding: EdgeInsets.all(16),
//                   backgroundColor:
//                       _isServiceRunning ? Colors.red : Colors.green,
//                 ),
//               ),

//             SizedBox(height: 16),

//             // Instructions
//             if (!_isServiceRunning && _hasOverlayPermission)
//               Card(
//                 color: Colors.blue[50],
//                 child: Padding(
//                   padding: EdgeInsets.all(12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'How to use:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 8),
//                       Text('1. Press "Start Service"'),
//                       Text('2. Floating button will appear'),
//                       Text('3. Tap to capture screenshot'),
//                       Text('4. Long press to stop'),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, int value, Color color) {
//     return Column(
//       children: [
//         Text(
//           value.toString(),
//           style: TextStyle(
//             fontSize: 32,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(label),
//       ],
//     );
//   }
// }
