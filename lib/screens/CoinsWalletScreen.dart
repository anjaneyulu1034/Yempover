import 'package:YemPover_app/services/coin_service.dart';
import 'package:flutter/material.dart';

class CoinsWalletScreen extends StatefulWidget {
  const CoinsWalletScreen({super.key});

  @override
  State<CoinsWalletScreen> createState() => _CoinsWalletScreenState();
}

class _CoinsWalletScreenState extends State<CoinsWalletScreen> {
  final CoinService _coinService = CoinService();
  bool _isLoading = true;
  bool _isBuying = false;

  Map<String, dynamic> _wallet = {};
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _coinService.getWallet(),
        _coinService.getPackages(),
        _coinService.getTransactions(),
      ]);

      if (!mounted) return;
      setState(() {
        _wallet = results[0] as Map<String, dynamic>;
        _packages = results[1] as List<Map<String, dynamic>>;
        _transactions = results[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buyPackage(Map<String, dynamic> pkg) async {
    if (_isBuying) return;

    setState(() {
      _isBuying = true;
    });

    try {
      await _coinService.purchaseCoins(
        coinPackageId: pkg['id']?.toString() ?? '',
        countryCode: pkg['countryCode']?.toString(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coins purchased successfully')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isBuying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _wallet['balance'] ?? 0;
    final purchased = _wallet['totalPurchased'] ?? 0;
    final spent = _wallet['totalSpent'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Barter Coins')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWalletCard(balance, purchased, spent),
                  const SizedBox(height: 16),
                  const Text(
                    'Buy Coins',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._packages.map(_buildPackageCard),
                  const SizedBox(height: 18),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_transactions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('No coin transactions yet'),
                      ),
                    )
                  else
                    ..._transactions.take(10).map(_buildTransactionTile),
                ],
              ),
      ),
    );
  }

  Widget _buildWalletCard(dynamic balance, dynamic purchased, dynamic spent) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wallet Balance',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              '$balance Coins',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Purchased: $purchased',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Spent: $spent',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final coins = pkg['coinAmount'] ?? 0;
    final price = pkg['price'] ?? 0;
    final currency = (pkg['currency'] ?? '').toString().toUpperCase();
    final country = pkg['countryCode'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text('${pkg['name'] ?? 'Coin Pack'} ($country)'),
        subtitle: Text('$coins Coins · $price $currency'),
        trailing: ElevatedButton(
          onPressed: _isBuying ? null : () => _buyPackage(pkg),
          child: const Text('Buy'),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> txn) {
    final isCredit = (txn['type'] ?? '').toString().toUpperCase() == 'CREDIT';
    final amount = txn['amount'] ?? 0;
    final reason = txn['reason'] ?? '-';
    final createdAt = txn['createdAt']?.toString() ?? '';

    return Card(
      child: ListTile(
        leading: Icon(
          isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: isCredit ? Colors.green : Colors.red,
        ),
        title: Text(reason.toString()),
        subtitle: Text(createdAt.isNotEmpty ? createdAt.substring(0, 10) : '-'),
        trailing: Text(
          '${isCredit ? '+' : '-'}$amount',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCredit ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
