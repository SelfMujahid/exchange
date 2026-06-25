import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class BinanceSocketsService {
  // All market tickers fetch block
  Stream<List<dynamic>> connectAllMarkets() {
    final channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/!ticker@arr'),
    );
    return channel.stream.map((snapshot) {
      return jsonDecode(snapshot) as List<dynamic>;
    });
  }
}
