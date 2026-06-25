class MarketTicker {
  final String symbol;
  final double price;
  final double percentage;
  final bool isGreen;

  MarketTicker({
    required this.symbol,
    required this.price,
    required this.percentage,
    required this.isGreen,
  });
}

class OrderBookEntry {
  final double price;
  final double amount;
  OrderBookEntry(this.price, this.amount);
}
