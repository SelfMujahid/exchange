import 'package:flutter/material.dart';
import '../services/binance_sockets.dart';

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key});
  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> {
  final _socketsService = BinanceSocketsService();
  final Map<String, Map<String, dynamic>> _marketCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        title: const Text('MARKETS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: const Color(0xFF12161A),
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _socketsService.connectToExchange(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final streamData = snapshot.data!;
            if (streamData.containsKey('stream') && streamData['stream'].toString().contains('@ticker')) {
              final data = streamData['data'];
              final String sym = data['s'].toString().replaceAll('USDT', '');
              _marketCache[sym] = data;
            }
          }

          if (_marketCache.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF0B90B)));
          }

          final keys = _marketCache.keys.toList();

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final sym = keys[index];
              final data = _marketCache[sym]!;
              final double price = double.parse(data['c'] ?? '0.0');
              final double percent = double.parse(data['P'] ?? '0.0');
              final bool isGreen = percent >= 0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1E2329), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: Colors.white10, child: Text(sym, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Text('$sym/USDT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        const SizedBox(width: 16),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: isGreen ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text('${isGreen ? "+" : ""}${percent.toStringAsFixed(2)}%', style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
