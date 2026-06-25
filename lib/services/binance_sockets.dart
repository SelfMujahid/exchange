import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class BinanceSocketsService {
  // Multiplex WebSocket for Tickers & Raw Depth (Orderbook)
  Stream<Map<String, dynamic>> connectToExchange() {
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/ethusdt@ticker/solusdt@ticker/bnbusdt@ticker/btcusdt@depth5'),
    );
    return channel.stream.map((snapshot) => jsonDecode(snapshot) as Map<String, dynamic>);
  }
}
