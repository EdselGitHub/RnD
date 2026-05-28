// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class RealtimeTestScreen extends StatefulWidget {
//   const RealtimeTestScreen({Key? key}) : super(key: key);

//   @override
//   State<RealtimeTestScreen> createState() => _RealtimeTestScreenState();
// }

// class _RealtimeTestScreenState extends State<RealtimeTestScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   List<int> _delayHistory = [];
//   int? _lastDelay;
//   double _averageDelay = 0.0;
//   bool _isListening = false;

//   @override
//   void initState() {
//     super.initState();
//     _startListening();
//   }

//   // Fungsi untuk menerima data secara real-time
//   void _startListening() {
//     setState(() => _isListening = true);
    
//     _firestore
//         .collection('realtime_test')
//         .doc('sync_doc')
//         .snapshots()
//         .listen((snapshot) {
//       if (snapshot.exists && snapshot.data() != null) {
//         final data = snapshot.data()!;
//         final sentAt = data['sent_at'] as int?;
        
//         if (sentAt != null) {
//           // Waktu saat perangkat ini menerima data
//           final receivedAt = DateTime.now().millisecondsSinceEpoch; 
          
//           // Hitung selisih waktu (delay)
//           final delay = receivedAt - sentAt;

//           // Jangan catat jika delay bernilai negatif (terjadi jika jam antar device tidak sinkron)
//           // atau jika device ini sendiri yang mengirim data (waktu hampir 0 ms).
//           // Kita asumsikan pengujian dilakukan dari device lain.
//           if (delay > 0) {
//             setState(() {
//               _lastDelay = delay;
//               _delayHistory.insert(0, delay); // Masukkan ke urutan paling atas
//               _calculateAverage();
//             });
//           }
//         }
//       }
//     });
//   }

//   // Fungsi untuk mengirim data
//   Future<void> _sendData() async {
//     final currentMillis = DateTime.now().millisecondsSinceEpoch;
    
//     try {
//       await _firestore.collection('realtime_test').doc('sync_doc').set({
//         'message': 'Testing sync delay',
//         'sent_at': currentMillis,
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('📤 Data dikirim! Cek delay di perangkat kedua.')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('❌ Gagal mengirim data: $e')),
//       );
//     }
//   }

//   // Fungsi menghitung rata-rata delay
//   void _calculateAverage() {
//     if (_delayHistory.isEmpty) return;
//     int total = _delayHistory.fold(0, (sum, item) => sum + item);
//     _averageDelay = total / _delayHistory.length;
//   }

//   // Fungsi mereset data pengujian
//   void _resetData() {
//     setState(() {
//       _delayHistory.clear();
//       _lastDelay = null;
//       _averageDelay = 0.0;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pengujian Real-Time'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _resetData,
//             tooltip: 'Reset Data',
//           )
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Panel Informasi Rata-rata
//             Card(
//               color: Colors.blue.shade50,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Rata-rata Delay Sinkronisasi',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${_averageDelay.toStringAsFixed(2)} ms',
//                       style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
//                     ),
//                     const SizedBox(height: 8),
//                     Text('Dari ${_delayHistory.length} kali percobaan'),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
            
//             // Tombol Kirim Data
//             ElevatedButton.icon(
//               onPressed: _sendData,
//               icon: const Icon(Icons.send),
//               label: const Padding(
//                 padding: EdgeInsets.all(12.0),
//                 child: Text('Kirim Data Baru', style: TextStyle(fontSize: 16)),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 24),
            
//             // Riwayat Delay
//             const Text(
//               'Riwayat Percobaan (Terbaru di atas)',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const Divider(),
//             Expanded(
//               child: _delayHistory.isEmpty
//                   ? const Center(child: Text('Belum ada data yang diterima.'))
//                   : ListView.builder(
//                       itemCount: _delayHistory.length,
//                       itemBuilder: (context, index) {
//                         return ListTile(
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.green.shade100,
//                             child: Text('${_delayHistory.length - index}'),
//                           ),
//                           title: Text('Percobaan ke-${_delayHistory.length - index}'),
//                           trailing: Text(
//                             '${_delayHistory[index]} ms',
//                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }