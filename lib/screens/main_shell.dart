import 'package:flutter/material.dart';
import 'markets_screen.dart';
import 'trade_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const MarketsScreen(),
    const TradeScreen(),
    const Scaffold(body: Center(child: Text('Wallets Core (Secure Node)', style: TextStyle(color: Colors.white70)))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF12161A),
        selectedItemColor: const Color(0xFFF0B90B), // Binance Gold
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Markets'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horizontal_circle), label: 'Trade'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallets'),
        ],
      ),
    );
  }
}
