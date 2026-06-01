// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class RealtimeTestScreen extends StatefulWidget {
//   const RealtimeTestScreen({Key? key}) : super(key: key);

//   @override
//   State<RealtimeTestScreen> createState() => _RealtimeTestScreenState();
// }

// class _RealtimeTestScreenState extends State<RealtimeTestScreen>
//     with SingleTickerProviderStateMixin {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late TabController _tabController;

//   // ─── Metode 1: Round-Trip (Satu Perangkat) ───────────────────────────────
//   List<int> _roundTripHistory = [];
//   double _roundTripAverage = 0.0;
//   int? _roundTripSendTime;
//   bool _isRoundTripSending = false;

//   // ─── Metode 2: Server Timestamp (Dua Perangkat) ──────────────────────────
//   List<int> _serverTsHistory = [];
//   double _serverTsAverage = 0.0;
//   bool _isListening = false;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _startServerTsListener();
//     _startRoundTripListener();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // METODE 1: ROUND-TRIP — Satu Perangkat
//   // Cara kerja: kirim data → tunggu listener menerima kembali → hitung selisih
//   // Tidak ada masalah clock skew karena hanya pakai satu jam (perangkat ini).
//   // ═══════════════════════════════════════════════════════════════════════════

//   void _startRoundTripListener() {
//     _firestore
//         .collection('realtime_test')
//         .doc('roundtrip_doc')
//         .snapshots()
//         .listen((snapshot) {
//       // Hanya proses jika kita yang mengirim (ada _roundTripSendTime)
//       if (_roundTripSendTime != null && snapshot.exists) {
//         final roundTripDelay =
//             DateTime.now().millisecondsSinceEpoch - _roundTripSendTime!;

//         // Reset send time supaya tidak terhitung dua kali
//         _roundTripSendTime = null;

//         // Filter outlier: abaikan jika > 10 detik (kemungkinan koneksi terputus)
//         if (roundTripDelay > 0 && roundTripDelay < 10000) {
//           setState(() {
//             _roundTripHistory.insert(0, roundTripDelay);
//             _isRoundTripSending = false;
//             _calculateRoundTripAverage();
//           });
//         }
//       }
//     });
//   }

//   Future<void> _sendRoundTrip() async {
//     if (_isRoundTripSending) return;
//     setState(() => _isRoundTripSending = true);

//     // Catat waktu SEBELUM mengirim ke Firestore
//     _roundTripSendTime = DateTime.now().millisecondsSinceEpoch;

//     try {
//       await _firestore.collection('realtime_test').doc('roundtrip_doc').set({
//         'trigger': _roundTripSendTime,
//         'message': 'round_trip_ping',
//       });
//     } catch (e) {
//       setState(() => _isRoundTripSending = false);
//       _roundTripSendTime = null;
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('❌ Gagal mengirim: $e')),
//         );
//       }
//     }
//   }

//   void _calculateRoundTripAverage() {
//     if (_roundTripHistory.isEmpty) return;
//     final total = _roundTripHistory.fold(0, (sum, item) => sum + item);
//     _roundTripAverage = total / _roundTripHistory.length;
//   }

//   void _resetRoundTrip() {
//     setState(() {
//       _roundTripHistory.clear();
//       _roundTripAverage = 0.0;
//       _roundTripSendTime = null;
//       _isRoundTripSending = false;
//     });
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // METODE 2: SERVER TIMESTAMP — Dua Perangkat
//   // Cara kerja: Perangkat A kirim data + FieldValue.serverTimestamp()
//   //             Perangkat B terima → hitung (jam B - jam server Firebase)
//   // Jauh lebih akurat dari kode asli karena menghilangkan clock skew antar device.
//   // ═══════════════════════════════════════════════════════════════════════════

//   void _startServerTsListener() {
//     setState(() => _isListening = true);

//     _firestore
//         .collection('realtime_test')
//         .doc('sync_doc')
//         .snapshots()
//         .listen((snapshot) {
//       if (snapshot.exists && snapshot.data() != null) {
//         final data = snapshot.data()!;

//         // Gunakan server timestamp, bukan timestamp dari device pengirim
//         final sentAtServer = data['sent_at_server'] as Timestamp?;

//         if (sentAtServer != null) {
//           final receivedAt = DateTime.now().millisecondsSinceEpoch;
//           final delay = receivedAt - sentAtServer.millisecondsSinceEpoch;

//           // Filter: abaikan nilai negatif dan outlier > 10 detik
//           if (delay > 0 && delay < 10000) {
//             setState(() {
//               _serverTsHistory.insert(0, delay);
//               _calculateServerTsAverage();
//             });
//           }
//         }
//       }
//     });
//   }

//   Future<void> _sendServerTs() async {
//     try {
//       await _firestore.collection('realtime_test').doc('sync_doc').set({
//         'message': 'Testing sync delay',
//         // FieldValue.serverTimestamp() → dicatat oleh server Firebase,
//         // bukan jam device pengirim — ini yang memperbaiki kode aslimu
//         'sent_at_server': FieldValue.serverTimestamp(),
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('📤 Data dikirim! Cek delay di perangkat kedua.')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('❌ Gagal mengirim data: $e')),
//         );
//       }
//     }
//   }

//   void _calculateServerTsAverage() {
//     if (_serverTsHistory.isEmpty) return;
//     final total = _serverTsHistory.fold(0, (sum, item) => sum + item);
//     _serverTsAverage = total / _serverTsHistory.length;
//   }

//   void _resetServerTs() {
//     setState(() {
//       _serverTsHistory.clear();
//       _serverTsAverage = 0.0;
//     });
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // UI HELPERS
//   // ═══════════════════════════════════════════════════════════════════════════

//   Color _getDelayColor(double avg) {
//     if (avg == 0) return Colors.grey;
//     if (avg < 300) return Colors.green;
//     if (avg < 600) return Colors.orange;
//     return Colors.red;
//   }

//   String _getDelayLabel(double avg) {
//     if (avg == 0) return 'Belum ada data';
//     if (avg < 300) return '✅ Sangat Baik';
//     if (avg < 600) return '⚠️ Cukup Baik';
//     return '❌ Lambat';
//   }

//   // ═══════════════════════════════════════════════════════════════════════════
//   // BUILD
//   // ═══════════════════════════════════════════════════════════════════════════

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pengujian Real-Time'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(icon: Icon(Icons.phone_android), text: '1 Perangkat'),
//             Tab(icon: Icon(Icons.devices), text: '2 Perangkat'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildRoundTripTab(),
//           _buildServerTsTab(),
//         ],
//       ),
//     );
//   }

//   // ─── Tab 1: Round-Trip ────────────────────────────────────────────────────
//   Widget _buildRoundTripTab() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Info metodologi
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.green.shade200),
//             ),
//             child: const Text(
//               '📱 Metode Round-Trip (1 Perangkat)\n'
//               'Mengukur waktu dari kirim → diterima listener di perangkat yang SAMA. '
//               'Tidak ada clock skew. Bagi 2 untuk estimasi one-way latency.',
//               style: TextStyle(fontSize: 12, color: Colors.black87),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Panel rata-rata
//           _buildAverageCard(
//             label: 'Round-Trip Time',
//             average: _roundTripAverage,
//             count: _roundTripHistory.length,
//             extraInfo: _roundTripAverage > 0
//                 ? 'Estimasi one-way: ${(_roundTripAverage / 2).toStringAsFixed(2)} ms'
//                 : null,
//           ),
//           const SizedBox(height: 16),

//           // Tombol kirim
//           ElevatedButton.icon(
//             onPressed: _isRoundTripSending ? null : _sendRoundTrip,
//             icon: _isRoundTripSending
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                         strokeWidth: 2, color: Colors.white),
//                   )
//                 : const Icon(Icons.send),
//             label: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Text(
//                 _isRoundTripSending ? 'Menunggu respons...' : 'Kirim Ping',
//                 style: const TextStyle(fontSize: 16),
//               ),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 8),
//           OutlinedButton.icon(
//             onPressed: _resetRoundTrip,
//             icon: const Icon(Icons.refresh),
//             label: const Text('Reset Data'),
//           ),
//           const SizedBox(height: 16),

//           // Riwayat
//           _buildHistoryHeader('Round-Trip Time'),
//           const Divider(),
//           _buildHistoryList(_roundTripHistory, showHalf: true),
//         ],
//       ),
//     );
//   }

//   // ─── Tab 2: Server Timestamp ──────────────────────────────────────────────
//   Widget _buildServerTsTab() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // Info metodologi
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue.shade50,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.blue.shade200),
//             ),
//             child: const Text(
//               '📱➡️📱 Metode Server Timestamp (2 Perangkat)\n'
//               'Perangkat A tekan "Kirim". Perangkat B buka tab ini untuk melihat delay. '
//               'Menggunakan jam server Firebase — lebih akurat dari jam device pengirim.',
//               style: TextStyle(fontSize: 12, color: Colors.black87),
//             ),
//           ),
//           const SizedBox(height: 16),

//           // Panel rata-rata
//           _buildAverageCard(
//             label: 'Delay Sinkronisasi',
//             average: _serverTsAverage,
//             count: _serverTsHistory.length,
//           ),
//           const SizedBox(height: 16),

//           // Tombol kirim
//           ElevatedButton.icon(
//             onPressed: _sendServerTs,
//             icon: const Icon(Icons.send),
//             label: const Padding(
//               padding: EdgeInsets.all(12.0),
//               child: Text('Kirim Data Baru', style: TextStyle(fontSize: 16)),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 8),
//           OutlinedButton.icon(
//             onPressed: _resetServerTs,
//             icon: const Icon(Icons.refresh),
//             label: const Text('Reset Data'),
//           ),
//           const SizedBox(height: 16),

//           // Riwayat
//           _buildHistoryHeader('Delay Diterima'),
//           const Divider(),
//           _buildHistoryList(_serverTsHistory, showHalf: false),
//         ],
//       ),
//     );
//   }

//   // ─── Shared Widgets ───────────────────────────────────────────────────────

//   Widget _buildAverageCard({
//     required String label,
//     required double average,
//     required int count,
//     String? extraInfo,
//   }) {
//     final color = _getDelayColor(average);
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(label,
//                 style:
//                     const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             Text(
//               average > 0 ? '${average.toStringAsFixed(2)} ms' : '— ms',
//               style: TextStyle(
//                   fontSize: 36, fontWeight: FontWeight.bold, color: color),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               _getDelayLabel(average),
//               style: TextStyle(
//                   fontSize: 13, color: color, fontWeight: FontWeight.w500),
//             ),
//             if (extraInfo != null) ...[
//               const SizedBox(height: 4),
//               Text(extraInfo,
//                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
//             ],
//             const SizedBox(height: 4),
//             Text('Dari $count kali percobaan',
//                 style: const TextStyle(color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHistoryHeader(String title) {
//     return Text(
//       'Riwayat $title (Terbaru di atas)',
//       style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//     );
//   }

//   Widget _buildHistoryList(List<int> history, {required bool showHalf}) {
//     return Expanded(
//       child: history.isEmpty
//           ? const Center(
//               child: Text('Belum ada data.',
//                   style: TextStyle(color: Colors.grey)))
//           : ListView.builder(
//               itemCount: history.length,
//               itemBuilder: (context, index) {
//                 final delay = history[index];
//                 final no = history.length - index;

//                 Color tileColor = Colors.green;
//                 if (delay >= 300 && delay < 600) tileColor = Colors.orange;
//                 if (delay >= 600) tileColor = Colors.red;

//                 return ListTile(
//                   dense: true,
//                   leading: CircleAvatar(
//                     backgroundColor: tileColor.withOpacity(0.15),
//                     child: Text('$no',
//                         style: TextStyle(
//                             color: tileColor, fontWeight: FontWeight.bold)),
//                   ),
//                   title: Text('Percobaan ke-$no'),
//                   subtitle: showHalf
//                       ? Text('One-way ≈ ${(delay / 2).toStringAsFixed(1)} ms',
//                           style:
//                               const TextStyle(fontSize: 11, color: Colors.grey))
//                       : null,
//                   trailing: Text(
//                     '$delay ms',
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                         color: tileColor),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }