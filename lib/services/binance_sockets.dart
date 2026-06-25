import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class BinanceSocketsService {
  // Ultra-fast multi-stream channel setup (BTC, ETH, SOL, BNB)
  Stream<Map<String, dynamic>> connectExchangeStreams() {
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/ethusdt@ticker/solusdt@ticker/bnbusdt@ticker/xrpusdt@ticker/adausdt@ticker/btcusdt@depth5'),
    );
    return channel.stream.map((snapshot) {
      return jsonDecode(snapshot) as Map<String, dynamic>;
    });
  }
}
