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
  String _selectedTimeframe = "24h"; // 1h, 4h, 24h, 7d (Demo switching visuals)
  int _visibleCount = 20;

  Map<String, dynamic> _btcData = {};
  Map<String, dynamic> _ethData = {};
  List<dynamic> _allCoinsList = [];

  // Static list for crypto logos mapping to ensure ultra-fast rendering without loading delay
  String _getCryptoLogoUrl(String symbol) {
    return "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${symbol.toLowerCase()}.png";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: SafeArea(
        child: StreamBuilder<List<dynamic>>(
          stream: _socketsService.connectAllMarkets(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _allCoinsList = snapshot.data!.where((coin) => coin['s'].toString().endsWith('USDT')).toList();
              
              // Sort initially by volume/market cap logic estimation
              _allCoinsList.sort((a, b) => double.parse(b['v']).compareTo(double.parse(a['v'])));

              for (var coin in _allCoinsList) {
                if (coin['s'] == 'BTCUSDT') _btcData = coin;
                if (coin['s'] == 'ETHUSDT') _ethData = coin;
              }
            }

            // Filtering logic via Search & Tabs
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
                // 1. Premium Header Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo.webp', width: 40, height: 40, errorBuilder: (c, e, s) => const CircleAvatar(backgroundColor: Color(0xFFF0B90B), child: Icon(Icons.blur_on, color: Colors.black))),
                        const SizedBox(width: 12),
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

                // 2. Demo Portfolio Panel ($10,000)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E2329), Color(0xFF161A1E)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Demo Balance", style: TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 6),
                        const Text("\$10,000.00", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildProfitLossCard("Today Profit", "+\$342.10", Colors.greenAccent),
                            _buildProfitLossCard("Today Loss", "-\$12.40", Colors.redAccent),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // 3. Current Active Trades Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Current Open Trades", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF12161A), borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("BTC/USDT [LONG 10x]", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              Text("Margin: \$500.00", style: TextStyle(color: Colors.white70)),
                              Text("+12.45%", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // 4. Interactive Search Bar Element
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

                // 5. Navigation Sorting Filters & Timeframe Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
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
                            // Small Custom Timeframe Bar component
                            Row(
                              children: ["1h", "4h", "24h", "7d"].map((time) {
                                final bool isSel = _selectedTimeframe == time;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedTimeframe = time),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(time, style: TextStyle(color: isSel ? const Color(0xFFF0B90B) : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                );
                              }).toList(),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white10, height: 1),
                      ],
                    ),
                  ),
                ),

                // 6. 500+ Crypto Assets Render System via Pagination
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
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: const Color(0xFF12161A), borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text("#${index + 1}", style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      Image.network(
                                        _getCryptoLogoUrl(sym),
                                        width: 28,
                                        height: 28,
                                        errorBuilder: (c, e, s) => CircleAvatar(radius: 14, backgroundColor: Colors.white10, child: Text(sym[0], style: const TextStyle(color: Colors.white, fontSize: 10))),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(sym, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        price > 1.0 ? currencyFormatter.format(price) : "\$${price.toString()}",
                                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        width: 75,
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: isGreen ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                        child: Text('${isGreen ? "+" : ""}${percent.toStringAsFixed(2)}%', style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                          childCount: filteredList.length < _visibleCount ? filteredList.length : _visibleCount,
                        ),
                      ),

                // 7. Dynamic Show More (+50 Coins Selector) Button Trigger
                if (filteredList.length > _visibleCount)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(backgroundColor: const Color(0xFF1E2329), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => setState(() => _visibleCount += 50),
                          icon: const Icon(Icons.add, color: Color(0xFFF0B90B), size: 16),
                          label: const Text("Show More (+50 Coins)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderTicker(String coin, String val) {
    double price = double.parse(val);
    String logoUrl = _getCryptoLogoUrl(coin);
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF1E2329), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Image.network(logoUrl, width: 16, height: 16, errorBuilder: (c, e, s) => const Icon(Icons.circle, size: 12, color: Colors.white30)),
          const SizedBox(width: 6),
          Text('\$${price.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildGlobalStat(String title, String val) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF12161A), borderRadius: BorderRadius.circular(8)),
      child: Text("$title: $val", style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildProfitLossCard(String title, String val, Color clr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(color: clr, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
      ],
    );
  }
}
