import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RealtimeTestScreen extends StatefulWidget {
  const RealtimeTestScreen({super.key});

  @override
  State<RealtimeTestScreen> createState() => _RealtimeTestScreenState();
}

class _RealtimeTestScreenState extends State<RealtimeTestScreen> {
  final _firestore = FirebaseFirestore.instance;
  int? _sendTime;
  int? _latency;
  bool _isLoading = false;
  final List<int> _latencies = [];

  @override
  void initState() {
    super.initState();
    
    // Admin mendengarkan balasan 'pong' dari perangkat User
    _firestore
        .collection('realtime_test')
        .doc('two_devices')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && _sendTime != null) {
        final data = snapshot.data();
        // Jika User membalas dengan 'pong' untuk request ping yang sama
        if (data != null && data['status'] == 'pong' && data['timestamp'] == _sendTime) {
          final receivedTime = DateTime.now().millisecondsSinceEpoch;
          
          setState(() {
            final lat = receivedTime - _sendTime!;
            _latency = lat;
            if (_latencies.length < 15) {
              _latencies.add(lat);
            }
            _sendTime = null; // Reset status pengiriman
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _ping() async {
    if (_latencies.length >= 15) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    setState(() {
      _isLoading = true;
      _sendTime = now;
    });

    // Kirim sinyal ping ke database
    await _firestore
        .collection('realtime_test')
        .doc('two_devices')
        .set({
          'status': 'ping',
          'timestamp': now,
        });
  }

  @override
  Widget build(BuildContext context) {
    final total = _latencies.fold<int>(0, (acc, item) => acc + item);
    final average = _latencies.isNotEmpty ? total / _latencies.length : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Uji Latensi 2 Perangkat (Admin)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Petunjuk: Buka halaman pengujian di aplikasi User juga.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              'Percobaan: ${_latencies.length} / 15',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            if (_latency != null)
              Text(
                'Delay Terakhir: $_latency ms',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              )
            else
              const Text('Tekan tombol untuk menguji', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (_latencies.length >= 15) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Hasil Pengujian (15x)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Delay: $total ms', style: const TextStyle(fontSize: 15)),
                    Text('Rata-rata Delay: ${average.toStringAsFixed(2)} ms', style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: (_isLoading || _latencies.length >= 15) ? null : _ping,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Kirim Ping ke User'),
                ),
                if (_latencies.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _latencies.clear();
                        _latency = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
