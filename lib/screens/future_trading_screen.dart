import 'package:flutter/material.dart';
import '../services/binance_sockets.dart';

class FutureTradingScreen extends StatefulWidget {
  const FutureTradingScreen({super.key});

  @override
  State<FutureTradingScreen> createState() => _FutureTradingScreenState();
}

class _FutureTradingScreenState extends State<FutureTradingScreen> with SingleTickerProviderStateMixin {
  final _socketsService = BinanceSocketsService();
  
  // Navigation & Form State Systems
  String _activeExecutionTab = "OPEN"; // OPEN or CLOSE
  String _orderType = "MARKET";        // MARKET, LIMIT, STOP LIMIT, TRIGGER
  String _marginMode = "ISOLATED";    // CROSS or ISOLATED
  double _leverage = 20.0;
  double _selectedPercentage = 0.25;
  bool _tpSlEnabled = false;
  String _bottomActiveTab = "POSITIONS"; // POSITIONS, OPEN ORDERS, etc.

  // Reactive Stream Data State Controls
  double _currentMarketPrice = 92450.50;
  double _priceChangePercent = 2.45;
  List<dynamic> _bids = [];
  List<dynamic> _asks = [];

  // Controllers for Computational Precision
  final TextEditingController _priceController = TextEditingController(text: "92450.5");
  final TextEditingController _amountController = TextEditingController(text: "0.05");

  // Simulated Mock Account Positions Engine
  bool _hasActivePosition = true;
  String _positionSide = "LONG";
  double _positionEntryPrice = 91800.00;
  double _positionAmount = 0.125;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_rebuildTerminalMetrics);
    _amountController.addListener(_rebuildTerminalMetrics);
  }

  void _rebuildTerminalMetrics() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _priceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Mathematical Calculations
    double inputPrice = double.tryParse(_priceController.text) ?? _currentMarketPrice;
    if (_orderType == "MARKET") inputPrice = _currentMarketPrice;
    double inputAmount = double.tryParse(_amountController.text) ?? 0.0;
    
    double notionalValue = inputPrice * inputAmount;
    double marginRequired = _leverage > 0 ? (notionalValue / _leverage) : 0.0;
    double liquidationPrice = _positionSide == "LONG"
        ? inputPrice * (1 - (1 / _leverage) + 0.0035)
        : inputPrice * (1 + (1 / _leverage) - 0.0035);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB), // Premium Matte Milk White Background
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _socketsService.connectExchangeStreams(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final streamData = snapshot.data!;
              if (streamData['stream'] == 'btcusdt@depth5') {
                _bids = streamData['data']['bids'] ?? [];
                _asks = streamData['data']['asks'] ?? [];
              } else if (streamData['stream'] == 'btcusdt@ticker') {
                final tick = streamData['data'];
                _currentMarketPrice = double.tryParse(tick['c'] ?? '92450.5') ?? 92450.5;
                _priceChangePercent = double.tryParse(tick['P'] ?? '2.45') ?? 2.45;
              }
            }

            return Column(
              children: [
                _buildTopHeaderArea(),
                _buildMarketInfoStrip(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column Block: Order Book & Recent Trades UI
                              Expanded(flex: 11, child: _buildMarketDataPanel()),
                              const SizedBox(width: 12),
                              // Right Column Block: Tactical Interactive Trading Panel Controls
                              Expanded(flex: 13, child: _buildTradingFormPanel(marginRequired, liquidationPrice)),
                            ],
                          ),
                        ),
                        _buildBottomNavigationTabs(),
                        _buildPositionCardWorkspace(liquidationPrice, marginRequired),
                      ],
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

  // ==========================================
  // TOP HEADER UI AREA
  // ==========================================
  Widget _buildTopHeaderArea() {
    final bool isGreen = _priceChangePercent >= 0;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F2F6), borderRadius: BorderRadius.circular(4)),
                child: const Text("Spot/Bot", style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              const Text("BTCUSDT", style: TextStyle(color: Color(0xFF1E2329), fontWeight: FontWeight.w900, fontSize: 16)),
              const Spacer(),
              Text(
                _currentMarketPrice.toStringAsFixed(1),
                style: TextStyle(color: isGreen ? const Color(0xFF0ECB81) : const Color(0xFFF6465D), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 6),
              Text(
                "${isGreen ? '+' : ''}${_priceChangePercent.toStringAsFixed(2)}%",
                style: TextStyle(color: isGreen ? const Color(0xFF0ECB81) : const Color(0xFFF6465D), fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.search, size: 18, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderSubIndex("Mark", _currentMarketPrice.toStringAsFixed(1)),
              _buildHeaderSubIndex("Index", (_currentMarketPrice - 1.20).toStringAsFixed(1)),
              _buildHeaderSubIndex("Funding/Countdown", "0.0100% / 04:12:33"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderSubIndex(String label, String value) {
    return Row(
      children: [
        Text("$label ", style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ==========================================
  // MARKET METRICS STATISTICS INFO STRIP
  // ==========================================
  Widget _buildMarketInfoStrip() {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F2F6),
        border: Border(bottom: BorderSide(color: Color(0xEFEFEFEF))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStripItem("24h High", "\$${(_currentMarketPrice * 1.03).toStringAsFixed(1)}"),
          _buildStripDivider(),
          _buildStripItem("24h Low", "\$${(_currentMarketPrice * 0.97).toStringAsFixed(1)}"),
          _buildStripDivider(),
          _buildStripItem("24h Vol(BTC)", "42.15K"),
          _buildStripDivider(),
          _buildStripItem("Open Interest", "1.24B"),
        ],
      ),
    );
  }

  Widget _buildStripItem(String label, String val) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(val, style: const TextStyle(color: Colors.black87, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStripDivider() => Container(width: 1, color: Colors.black.withOpacity(0.05), margin: const EdgeInsets.symmetric(vertical: 10));

  // ==========================================
  // ORDER BOOK MATRIX PANELS
  // ==========================================
  Widget _buildMarketDataPanel() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Price", style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("Amount", style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          // Asks (Sellers Profile Stack)
          Column(
            children: List.generate(6, (index) {
              String p = (_currentMarketPrice + (6 - index) * 2.5).toStringAsFixed(1);
              String amt = (0.012 + index * 0.034).toStringAsFixed(3);
              return _buildDataBookRow(p, amt, const Color(0xFFF6465D).withOpacity(0.06), const Color(0xFFF6465D));
            }),
          ),
          // Spread Indicator Block
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: const Color(0xFFF9F9FB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_currentMarketPrice.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87, fontFamily: 'monospace')),
                const Text("Spread 0.5", style: TextStyle(fontSize: 9, color: Colors.black38, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Bids (Buyers Profile Stack)
          Column(
            children: List.generate(6, (index) {
              String p = (_currentMarketPrice - (index + 1) * 2.5).toStringAsFixed(1);
              String amt = (0.542 - index * 0.08).toStringAsFixed(3);
              return _buildDataBookRow(p, amt, const Color(0xFF0ECB81).withOpacity(0.06), const Color(0xFF0ECB81));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDataBookRow(String price, String amount, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(price, style: TextStyle(color: textColor, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          Text(amount, style: const TextStyle(color: Colors.black54, fontSize: 10, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  // ==========================================
  // PROFESSIONAL INTERACTIVE TRADING CONTROLS
  // ==========================================
  Widget _buildTradingFormPanel(double cost, double estLiq) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs Matrix Setup (Open / Close Grid)
        Row(
          children: ["OPEN", "CLOSE"].map((tab) {
            final bool isSel = _activeExecutionTab == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeExecutionTab = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black12),
                  ),
                  alignment: Alignment.center,
                  child: Text(tab, style: TextStyle(color: isSel ? Colors.white : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Cross / Isolated Mode Select System Toggle Switch
        Row(
          children: ["CROSS", "ISOLATED"].map((mode) {
            final bool isSel = _marginMode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _marginMode = mode),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF1E2329) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  alignment: Alignment.center,
                  child: Text(mode, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Leverage Highlight Parameters Slider Node
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black.withOpacity(0.03))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Leverage Metric", style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.w500)),
                  Text("${_leverage.toInt()}x", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 11)),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                  activeTrackColor: const Color(0xFFF0B90B),
                  inactiveTrackColor: Colors.black12,
                  thumbColor: const Color(0xFFF0B90B),
                ),
                child: Slider(
                  value: _leverage,
                  min: 1,
                  max: 125,
                  onChanged: (val) => setState(() => _leverage = val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Order Execution Selector Engine Row Tab
        Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["MARKET", "LIMIT", "TRIGGER"].map((type) {
              final bool isSel = _orderType == type;
              return GestureDetector(
                onTap: () => setState(() => _orderType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isSel ? const Color(0xFFF1F2F6) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                  child: Text(type, style: TextStyle(color: isSel ? Colors.black : Colors.black38, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        if (_orderType != "MARKET") ...[
          _buildCompactInputField(_priceController, "Price (USDT)"),
          const SizedBox(height: 6),
        ],
        _buildCompactInputField(_amountController, "Amount (BTC)"),
        const SizedBox(height: 8),

        // Tactical Percentage Shortcut Blocks Grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [0.25, 0.50, 0.75, 1.00].map((pct) {
            final bool isSel = _selectedPercentage == pct;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPercentage = pct;
                  _amountController.text = (pct * 0.25).toStringAsFixed(2);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFF0B90B).withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isSel ? const Color(0xFFF0B90B) : Colors.black12),
                ),
                child: Text("${(pct * 100).toInt()}%", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Protection Mechanism Toggle Parameters Switch Block
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("TP/SL Protection", style: TextStyle(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold)),
            Transform.scale(
              scale: 0.65,
              child: Switch(
                value: _tpSlEnabled,
                activeColor: const Color(0xFFF0B90B),
                onChanged: (val) => setState(() => _tpSlEnabled = val),
              ),
            )
          ],
        ),
        const SizedBox(height: 6),

        // Live Calculated Cost Metrics Console Output
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
          child: Column(
            children: [
              _buildFormMetricRow("Cost Margin", "\$${cost.toStringAsFixed(2)}"),
              const SizedBox(height: 3),
              _buildFormMetricRow("Est. Liq Price", "\$${estLiq.toStringAsFixed(1)}"),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Flash Core Trigger Execution Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0ECB81),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: () => setState(() => _hasActivePosition = true),
                child: const Text("Long / Buy", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF6465D),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                onPressed: () => setState(() => _hasActivePosition = true),
                child: const Text("Short / Sell", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildCompactInputField(TextEditingController ctrl, String hint) {
    return Container(
      height: 34,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black.withOpacity(0.06))),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFormMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }

  // ==========================================
  // BOTTOM WORKSPACE NAVIGATION TAB CONSOLE
  // ==========================================
  Widget _buildBottomNavigationTabs() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ["POSITIONS", "OPEN ORDERS", "HISTORY", "ASSETS"].map((tab) {
          final bool isSel = _bottomActiveTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _bottomActiveTab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isSel ? const Color(0xFFF0B90B) : Colors.transparent, width: 2)),
              ),
              child: Text(
                tab,
                style: TextStyle(color: isSel ? Colors.black : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // PROFESSIONAL CRYPTO EXCHANGE POSITION CARD UI
  // ==========================================
  Widget _buildPositionCardWorkspace(double liq, double margin) {
    if (!_hasActivePosition || _bottomActiveTab != "POSITIONS") {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Text("Zero Active Margin Exposures", style: TextStyle(color: Colors.black26, fontSize: 11, fontWeight: FontWeight.w500)),
      );
    }

    double priceDiff = _currentMarketPrice - _positionEntryPrice;
    double pnlPercent = (priceDiff / _positionEntryPrice) * _leverage * 100;
    double pnlUsdt = (_positionEntryPrice * _positionAmount) * (pnlPercent / 100) / _leverage;
    final bool isGreen = pnlPercent >= 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF0ECB81).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                    child: const Text("BTCUSDT Long 20x", style: TextStyle(color: Color(0xFF0ECB81), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _hasActivePosition = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFF1F2F6), borderRadius: BorderRadius.circular(4)),
                  child: Text("Flash Close", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.7))),
                ),
              )
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPositionMetricsNode("Position Size", "${_positionAmount.toStringAsFixed(3)} BTC"),
              _buildPositionMetricsNode("Margin Used", "\$${(margin + 450).toStringAsFixed(2)}"),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Unrealized PNL (ROI %)", style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    "${isGreen ? '+' : ''}${pnlPercent.toStringAsFixed(2)}% (${isGreen ? '+' : ''}\$${pnlUsdt.toStringAsFixed(2)})",
                    style: TextStyle(color: isGreen ? const Color(0xFF0ECB81) : const Color(0xFFF6465D), fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              )
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider(color: Color(0xFFF1F2F6))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPositionMetricsNode("Entry Price", "\$${_positionEntryPrice.toStringAsFixed(1)}"),
              _buildPositionMetricsNode("Mark Price", "\$${_currentMarketPrice.toStringAsFixed(1)}"),
              _buildPositionMetricsNode("Est. Liq Price", "\$${(liq - 850).toStringAsFixed(1)}", valColor: const Color(0xFFF6465D)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPositionMetricsNode(String label, String value, {Color valColor = Colors.black87}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}
