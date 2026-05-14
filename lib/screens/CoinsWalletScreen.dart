import 'package:flutter/material.dart';

class CoinsWalletScreen extends StatefulWidget {
  final double? requiredAmount;

  const CoinsWalletScreen({super.key, this.requiredAmount});

  @override
  State<CoinsWalletScreen> createState() => _CoinsWalletScreenState();
}

class _CoinsWalletScreenState extends State<CoinsWalletScreen> {
  late final List<_WalletTransaction> _transactions = [
    _WalletTransaction(
      title: 'Coins Added',
      subtitle: 'Order #ORD12345',
      amount: 500,
      dateText: 'Today, 09:30 AM',
      type: _WalletTxnType.added,
    ),
    _WalletTransaction(
      title: 'Spent on Reward',
      subtitle: 'Amazon Gift Card',
      amount: 300,
      dateText: 'Yesterday, 04:20 PM',
      type: _WalletTxnType.spent,
    ),
    _WalletTransaction(
      title: 'Welcome Bonus',
      subtitle: 'Bonus',
      amount: 200,
      dateText: '22 May 2024',
      type: _WalletTxnType.reward,
    ),
    _WalletTransaction(
      title: 'Coins Added',
      subtitle: 'Order #ORD12300',
      amount: 400,
      dateText: '20 May 2024',
      type: _WalletTxnType.added,
    ),
    _WalletTransaction(
      title: 'Spent on Reward',
      subtitle: 'Flipkart Voucher',
      amount: 250,
      dateText: '18 May 2024',
      type: _WalletTxnType.spent,
    ),
    _WalletTransaction(
      title: 'Coins Added',
      subtitle: 'Order #ORD12250',
      amount: 300,
      dateText: '17 May 2024',
      type: _WalletTxnType.added,
    ),
    _WalletTransaction(
      title: 'Spent on Reward',
      subtitle: 'Netflix Gift Card',
      amount: 500,
      dateText: '15 May 2024',
      type: _WalletTxnType.spent,
    ),
    _WalletTransaction(
      title: 'Coins Added',
      subtitle: 'Order #ORD12200',
      amount: 600,
      dateText: '14 May 2024',
      type: _WalletTxnType.added,
    ),
    _WalletTransaction(
      title: 'Referral Bonus',
      subtitle: 'Referral Bonus',
      amount: 150,
      dateText: '12 May 2024',
      type: _WalletTxnType.reward,
    ),
    _WalletTransaction(
      title: 'Spent on Reward',
      subtitle: 'Swiggy Voucher',
      amount: 200,
      dateText: '10 May 2024',
      type: _WalletTxnType.spent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const totalCoins = 2450;
    const availableCoins = 1850;
    const pendingCoins = 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              if (widget.requiredAmount != null &&
                  widget.requiredAmount! > 0) ...[
                _buildRequiredAmountCard(widget.requiredAmount!),
                const SizedBox(height: 12),
              ],
              _buildWalletCard(totalCoins, availableCoins, pendingCoins),
              const SizedBox(height: 14),
              _buildActions(),
              const SizedBox(height: 18),
              _buildRedeemBanner(),
              const SizedBox(height: 22),
              _buildRecentTransactionsHeader(),
              const SizedBox(height: 10),
              ..._transactions.take(4).map(_buildTransactionTile),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF111827),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Wallets',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildRequiredAmountCard(double requiredAmount) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD7A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You need +\$${requiredAmount.toStringAsFixed(2)} to complete this purchase.',
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    int totalCoins,
    int availableCoins,
    int pendingCoins,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6F51FF), Color(0xFF5341DB)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Coins',
            style: TextStyle(color: Color(0xFFD8D4FF), fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$totalCoins',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC62B),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildSmallCoinCard('Available Coins', availableCoins),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSmallCoinCard('Pending Coins', pendingCoins),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCoinCard(String title, int value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x28FFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFFD8D4FF), fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 33,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.monetization_on,
                color: Color(0xFFFFC62B),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionTile(
          icon: Icons.add,
          iconBg: const Color(0xFFEDE8FF),
          iconColor: const Color(0xFF6549E8),
          label: 'Add Coins',
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.redeem_outlined,
          iconBg: const Color(0xFFE3F7EA),
          iconColor: const Color(0xFF26A269),
          label: 'Redeem',
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.receipt_long,
          iconBg: const Color(0xFFE6F0FF),
          iconColor: const Color(0xFF3B82F6),
          label: 'Transactions',
          onTap: _openTransactions,
        ),
        _ActionTile(
          icon: Icons.star_border,
          iconBg: const Color(0xFFFFEEE1),
          iconColor: const Color(0xFFFF7A1A),
          label: 'Rewards',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildRedeemBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Redeem your coins\nfor exciting rewards',
                  style: TextStyle(
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6549E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Explore Rewards'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFE0D5FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 42,
              color: Color(0xFF6549E8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(
          onPressed: _openTransactions,
          child: const Text(
            'View All',
            style: TextStyle(
              color: Color(0xFF6549E8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _openTransactions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WalletTransactionsScreen(transactions: _transactions),
      ),
    );
  }

  Widget _buildTransactionTile(_WalletTransaction txn) {
    final isCredit = txn.type != _WalletTxnType.spent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF2)),
      ),
      child: Row(
        children: [
          _buildTxnLeadingIcon(txn.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  txn.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${txn.amount}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isCredit
                      ? const Color(0xFF15A34A)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                txn.dateText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTxnLeadingIcon(_WalletTxnType type) {
    final Color bg;
    final Color iconColor;
    final IconData icon;

    switch (type) {
      case _WalletTxnType.added:
        bg = const Color(0xFFE9F8EF);
        iconColor = const Color(0xFF16A34A);
        icon = Icons.add_circle_outline;
        break;
      case _WalletTxnType.spent:
        bg = const Color(0xFFFFF0E8);
        iconColor = const Color(0xFFFB7A2A);
        icon = Icons.shopping_bag_outlined;
        break;
      case _WalletTxnType.reward:
        bg = const Color(0xFFEAF1FF);
        iconColor = const Color(0xFF3B82F6);
        icon = Icons.card_giftcard;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

class _WalletTransactionsScreen extends StatefulWidget {
  final List<_WalletTransaction> transactions;

  const _WalletTransactionsScreen({required this.transactions});

  @override
  State<_WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<_WalletTransactionsScreen> {
  _TransactionsTab _selectedTab = _TransactionsTab.all;

  @override
  Widget build(BuildContext context) {
    List<_WalletTransaction> filteredTransactions;
    switch (_selectedTab) {
      case _TransactionsTab.all:
        filteredTransactions = widget.transactions;
        break;
      case _TransactionsTab.added:
        filteredTransactions = widget.transactions
            .where(
              (t) =>
                  t.type == _WalletTxnType.added ||
                  t.type == _WalletTxnType.reward,
            )
            .toList();
        break;
      case _TransactionsTab.spent:
        filteredTransactions = widget.transactions
            .where((t) => t.type == _WalletTxnType.spent)
            .toList();
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8FB),
        elevation: 0,
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildTabs(),
            const SizedBox(height: 24),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: filteredTransactions.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == filteredTransactions.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          "You've reached the end",
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  return _TransactionListTile(txn: filteredTransactions[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabChip('All', _TransactionsTab.all),
          _buildTabChip('Added', _TransactionsTab.added),
          _buildTabChip('Spent', _TransactionsTab.spent),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, _TransactionsTab tab) {
    final isSelected = tab == _selectedTab;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6549E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (tab == _TransactionsTab.spent
                          ? const Color(0xFFEF4444)
                          : (tab == _TransactionsTab.added
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF374151))),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8E8ED)),
              ),
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionListTile extends StatelessWidget {
  final _WalletTransaction txn;

  const _TransactionListTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.type != _WalletTxnType.spent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF2)),
      ),
      child: Row(
        children: [
          _TransactionIcon(type: txn.type),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  txn.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${txn.amount}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: isCredit
                      ? const Color(0xFF15A34A)
                      : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                txn.dateText,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionIcon extends StatelessWidget {
  final _WalletTxnType type;

  const _TransactionIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color iconColor;
    final IconData icon;

    switch (type) {
      case _WalletTxnType.added:
        bg = const Color(0xFFE9F8EF);
        iconColor = const Color(0xFF16A34A);
        icon = Icons.add_circle_outline;
        break;
      case _WalletTxnType.spent:
        bg = const Color(0xFFFFF0E8);
        iconColor = const Color(0xFFFB7A2A);
        icon = Icons.shopping_bag_outlined;
        break;
      case _WalletTxnType.reward:
        bg = const Color(0xFFEAF1FF);
        iconColor = const Color(0xFF3B82F6);
        icon = Icons.card_giftcard;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

enum _WalletTxnType { added, spent, reward }

enum _TransactionsTab { all, added, spent }

class _WalletTransaction {
  final String title;
  final String subtitle;
  final int amount;
  final String dateText;
  final _WalletTxnType type;

  const _WalletTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateText,
    required this.type,
  });
}
