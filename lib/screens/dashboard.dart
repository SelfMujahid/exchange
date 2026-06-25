import 'package:flutter/material.dart';
import '../services/binance_stream.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BinanceStreamService _streamService = BinanceStreamService();
  final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11), // Midnight Black Premium Slate
      appBar: AppBar(
        title: const Text(
          '⚡ ULTRA-FAST EXCHANGE', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 18, color: Colors.white)
        ),
        backgroundColor: const Color(0xFF12161A),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _streamService.btcTickerStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF0B90B)));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Network Connection Error', style: TextStyle(color: Colors.red)));
          }

          final data = snapshot.data!;
          final double price = double.parse(data['c'] ?? '0.0');
          final double priceChangePercent = double.parse(data['P'] ?? '0.0');
          final bool isGreen = priceChangePercent >= 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Market Ticket Component
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2329),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BTC / USDT (Live)', style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Text(
                            currencyFormatter.format(price),
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isGreen ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isGreen ? "+" : ""}${priceChangePercent.toStringAsFixed(2)}%',
                          style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Order Book Control Desk', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Advanced Fast Trading Terminals
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EBD85),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {},
                        child: const Text('INSTANT BUY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDF294A),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {},
                        child: const Text('INSTANT SELL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _streamService.closeStream();
    super.dispose();
  }
}
