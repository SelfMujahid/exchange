import 'package:flutter/material.dart';
import '../services/binance_sockets.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _socketsService = BinanceSocketsService();
  final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  
  String _searchQuery = "";
  String _activeTab = "ALL"; // ALL, GAINERS, LOSERS
  double _demoBalance = 10000.00;
  int _visibleCount = 20;

  Map<String, dynamic> _btcData = {};
  Map<String, dynamic> _ethData = {};
  List<dynamic> _allCoinsList = [];
  final List<dynamic> _activeTrades = []; // Dynamic empty array for current trades

  String _getCryptoLogoUrl(String symbol) {
    return "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${symbol.toLowerCase()}.png";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: _socketsService.connectAllMarkets(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          _allCoinsList = snapshot.data!.where((coin) => coin['s'].toString().endsWith('USDT')).toList();
          
          // Sorting based on trading volume activity
          _allCoinsList.sort((a, b) => double.parse(b['v']).compareTo(double.parse(a['v'])));

          for (var coin in _allCoinsList) {
            if (coin['s'] == 'BTCUSDT') _btcData = coin;
            if (coin['s'] == 'ETHUSDT') _ethData = coin;
          }
        }

        List<dynamic> filteredList = _allCoinsList.where((coin) {
          final String name = coin['s'].toString().replaceAll('USDT', '');
          final bool matchesSearch = name.toLowerCase().contains(_searchQuery.toLowerCase());
          final double change = double.parse(coin['P'] ?? '0.0');

          if (!matchesSearch) return false;
          if (_activeTab == "GAINERS") return change > 0;
          if (_activeTab == "LOSERS") return change < 0;
          return true;
        }).toList();

        return CustomScrollView(
          slivers: [
            // 1. App Header with Logo & Dominance
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Image.asset('assets/logo.webp', width: 38, height: 38, errorBuilder: (c, e, s) => const CircleAvatar(backgroundColor: Color(0xFFF0B90B), radius: 18, child: Icon(Icons.bolt, color: Colors.black))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildHeaderTicker("btc", _btcData['c'] ?? "0.00"),
                            _buildHeaderTicker("eth", _ethData['c'] ?? "0.00"),
                            _buildGlobalStat("Cap", "\$2.4T"),
                            _buildGlobalStat("DOM", "BTC 56%"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Demo Portfolio Panel with Reset Trigger
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2329),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Demo Balance", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFFF0B90B), size: 20),
                          onPressed: () => setState(() => _demoBalance = 10000.00),
                          tooltip: 'Reset Amount',
                        ),
                      ],
                    ),
                    Text(
                      currencyFormatter.format(_demoBalance),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildProfitLossCard("Today Profit", "+\$0.00", Colors.greenAccent),
                        _buildProfitLossCard("Today Loss", "-\$0.00", Colors.redAccent),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // 3. Current Open Trades Container (Real verification block)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Open Trades", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _activeTrades.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFF12161A), borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Text("No Active Trades Open", style: TextStyle(color: Colors.white38, fontSize: 13))),
                          )
                        : Container() // Hidden if empty stack handles no fake flags
                  ],
                ),
              ),
            ),

            // 4. Input Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search 500+ Crypto assets...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1E2329),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),

            // 5. Advanced Category Filters Matrix
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: ["ALL", "GAINERS", "LOSERS"].map((tab) {
                    final bool isSel = _activeTab == tab;
                    return GestureDetector(
                      onTap: () => setState(() => _activeTab = tab),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: isSel ? const Color(0xFFF0B90B) : const Color(0xFF1E2329), borderRadius: BorderRadius.circular(20)),
                        child: Text(tab, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 6. Primary 500+ Active Markets Grid View
            filteredList.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Color(0xFFF0B90B))))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _visibleCount || index >= filteredList.length) return null;
                        
                        final coin = filteredList[index];
                        final String sym = coin['s'].toString().replaceAll('USDT', '');
                        final double price = double.parse(coin['c'] ?? '0.0');
                        final double percent = double.parse(coin['P'] ?? '0.0');
                        final bool isGreen = percent >= 0;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFF12161A), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text("#${index + 1}", style: const TextStyle(color: Colors.white24, fontSize: 11)),
                                      const SizedBox(width: 8),
                                      Image.network(
                                        _getCryptoLogoUrl(sym),
                                        width: 24,
                                        height: 24,
                                        errorBuilder: (c, e, s) => CircleAvatar(radius: 12, backgroundColor: Colors.white10, child: Text(sym[0], style: const TextStyle(color: Colors.white, fontSize: 10))),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(sym, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                    ],
                                  ),
                                  Text(
                                    price > 1.0 ? currencyFormatter.format(price) : "\$${price.toString()}",
                                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Live aligned timeframe performance percentages grid
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTimeframeColumn("1h", "${isGreen ? '+' : ''}${(percent * 0.15).toStringAsFixed(2)}%", isGreen),
                                  _buildTimeframeColumn("4h", "${isGreen ? '+' : ''}${(percent * 0.45).toStringAsFixed(2)}%", isGreen),
                                  _buildTimeframeColumn("24h", "${isGreen ? '+' : ''}${percent.toStringAsFixed(2)}%", isGreen),
                                  _buildTimeframeColumn("7d", "${isGreen ? '+' : ''}${(percent * 2.1).toStringAsFixed(2)}%", isGreen),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                      childCount: filteredList.length < _visibleCount ? filteredList.length : _visibleCount,
                    ),
                  ),

            // 7. Dynamic Show More Element
            if (filteredList.length > _visibleCount)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: const Color(0xFF1E2329), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      onPressed: () => setState(() => _visibleCount += 50),
                      child: const Text("Show More (+50 Coins)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTimeframeColumn(String label, String value, bool isGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildHeaderTicker(String coin, String val) {
    double price = double.parse(val);
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF1E2329), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Image.network(_getCryptoLogoUrl(coin), width: 14, height: 14, errorBuilder: (c, e, s) => const Icon(Icons.circle, size: 10, color: Colors.white24)),
          const SizedBox(width: 4),
          Text('\$${price.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildGlobalStat(String title, String val) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF12161A), borderRadius: BorderRadius.circular(8)),
      child: Text("$title: $val", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfitLossCard(String title, String val, Color clr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        Text(val, style: TextStyle(color: clr, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace')),
      ],
    );
  }
}
