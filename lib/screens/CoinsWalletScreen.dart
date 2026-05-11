import 'package:YemPover_app/services/coin_service.dart';
import 'package:flutter/material.dart';

class CoinsWalletScreen extends StatefulWidget {
  final double? requiredAmount;

  const CoinsWalletScreen({super.key, this.requiredAmount});

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
      appBar: AppBar(title: const Text('Wallet Coins')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.requiredAmount != null &&
                      widget.requiredAmount! > 0)
                    _buildRequiredAmountCard(widget.requiredAmount!),
                  if (widget.requiredAmount != null &&
                      widget.requiredAmount! > 0)
                    const SizedBox(height: 12),
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
                  const SizedBox(height: 18),
                  _buildQuickAddCoinsSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildRequiredAmountCard(double requiredAmount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You need +\$${requiredAmount.toStringAsFixed(2)} to complete this purchase.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(dynamic balance, dynamic purchased, dynamic spent) {
    final normalizedBalance = balance is num
        ? balance.toDouble()
        : double.tryParse(balance.toString()) ?? 0.0;

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
              '\$${normalizedBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              '${normalizedBalance.toStringAsFixed(0)} Coins (1 Coin = \$1 USD)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
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

  Widget _buildQuickAddCoinsSection() {
    const amounts = [10, 20, 50, 100];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Add Coins',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '1 Coin = \$1 USD',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amounts.map((amount) {
            return OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Top-up for \$$amount is UI-ready. Connect backend flow next.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: Text('Add \$$amount'),
            );
          }).toList(),
        ),
      ],
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
