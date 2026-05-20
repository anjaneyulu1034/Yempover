import 'package:flutter/material.dart';
import 'package:YemPover_app/screens/AddCoinsScreen.dart';
import 'package:YemPover_app/services/coin_service.dart';

class CoinsWalletScreen extends StatefulWidget {
  final double? requiredAmount;

  const CoinsWalletScreen({super.key, this.requiredAmount});

  @override
  State<CoinsWalletScreen> createState() => _CoinsWalletScreenState();
}

class _CoinsWalletScreenState extends State<CoinsWalletScreen> {
  final CoinService _coinService = CoinService();

  int _balance = 0;
  String _currencyLabel = 'Barter Coins';
  bool _isLoading = true;
  String? _loadError;
  bool _hasWallet = false;

  final List<_WalletTransaction> _transactions = [];
  bool _transactionsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final wallet = await _coinService.getWallet();
      if (!mounted) return;

      if (wallet == null) {
        setState(() {
          _hasWallet = false;
          _balance = 0;
          _currencyLabel = 'Barter Coins';
          _isLoading = false;
        });
        await _loadTransactions();
        return;
      }

      final currency = wallet['currency']?.toString();
      setState(() {
        _hasWallet = true;
        _balance = CoinService.parseCoinAmount(wallet['balance']);
        _currencyLabel = currency == 'BARTER_COIN' || currency == null
            ? 'Barter Coins'
            : currency.replaceAll('_', ' ');
        _isLoading = false;
      });
      await _loadTransactions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _transactionsLoading = true);

    try {
      final page = await _coinService.getTransactions(limit: 20);
      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(page.transactions.map(_walletTxnFromApi));
        _transactionsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _transactionsLoading = false);
    }
  }

  Future<void> _openAddCoins() async {
    final result = await Navigator.of(context).push<AddCoinsResult>(
      MaterialPageRoute(builder: (_) => const AddCoinsScreen()),
    );

    if (result == null || !mounted) return;

    await _loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadWallet();
          },
          color: const Color(0xFF6549E8),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 56),
                      child: CircularProgressIndicator(
                        color: Color(0xFF6549E8),
                      ),
                    ),
                  )
                else if (_loadError != null)
                  _buildErrorState()
                else ...[
                  _buildWalletCard(_balance, _currencyLabel, _hasWallet),
                  const SizedBox(height: 16),
                  _buildAddCoinsButton(),
                  if (_transactionsLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6549E8),
                        ),
                      ),
                    )
                  else if (_transactions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildRecentTransactionsHeader(),
                    const SizedBox(height: 10),
                    ..._transactions.take(5).map(_buildTransactionTile),
                  ],
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDF2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
          const SizedBox(height: 12),
          const Text(
            'Could not load wallet',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6549E8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCoinsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openAddCoins,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Coins',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6549E8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
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

  Widget _buildWalletCard(int balance, String currencyLabel, bool hasWallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
          Text(
            currencyLabel,
            style: const TextStyle(color: Color(0xFFD8D4FF), fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$balance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC62B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          if (!hasWallet) ...[
            const SizedBox(height: 14),
            Text(
              'No wallet yet — tap Add Coins to create one',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
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
        builder: (_) => _WalletTransactionsScreen(coinService: _coinService),
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
  final CoinService coinService;

  const _WalletTransactionsScreen({required this.coinService});

  @override
  State<_WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<_WalletTransactionsScreen> {
  final List<_WalletTransaction> _transactions = [];
  final ScrollController _scrollController = ScrollController();

  _TransactionsTab _selectedTab = _TransactionsTab.all;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;
  String? _nextCursor;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTransactions(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String? get _apiTypeFilter {
    switch (_selectedTab) {
      case _TransactionsTab.all:
        return null;
      case _TransactionsTab.added:
        return 'ADD_FUNDS';
      case _TransactionsTab.spent:
        return null;
    }
  }

  Future<void> _loadTransactions({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _loadError = null;
        _nextCursor = null;
        _hasMore = false;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final page = await widget.coinService.getTransactions(
        limit: 20,
        cursor: reset ? null : _nextCursor,
        type: _apiTypeFilter,
      );

      var items = page.transactions
          .map(_walletTxnFromApi)
          .toList();

      if (_selectedTab == _TransactionsTab.spent) {
        items = items
            .where((t) => t.type == _WalletTxnType.spent)
            .toList();
      }

      if (!mounted) return;

      final lastId = page.transactions.isNotEmpty
          ? page.transactions.last['id']?.toString()
          : null;

      setState(() {
        if (reset) {
          _transactions
            ..clear()
            ..addAll(items);
        } else {
          _transactions.addAll(items);
        }
        _nextCursor = lastId;
        _hasMore = page.hasMore;
        _isLoading = false;
        _isLoadingMore = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadTransactions(reset: false);
    }
  }

  void _onTabChanged(_TransactionsTab tab) {
    if (tab == _selectedTab) return;
    setState(() => _selectedTab = tab);
    _loadTransactions(reset: true);
  }

  Future<void> _openTransactionDetail(_WalletTransaction txn) async {
    final id = txn.id;
    if (id == null || id.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransactionDetailSheet(
        coinService: widget.coinService,
        transactionId: id,
        fallback: txn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadTransactions(reset: true),
        color: const Color(0xFF6549E8),
        child: Padding(
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6549E8),
                        ),
                      )
                    : _loadError != null
                    ? _buildErrorState()
                    : _transactions.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              'No transactions yet',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _transactions.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (index == _transactions.length) {
                            if (_isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6549E8),
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: Text(
                                  _hasMore
                                      ? 'Scroll for more'
                                      : "You've reached the end",
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          final txn = _transactions[index];
                          return InkWell(
                            onTap: () => _openTransactionDetail(txn),
                            borderRadius: BorderRadius.circular(16),
                            child: _TransactionListTile(txn: txn),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _loadError ?? 'Failed to load transactions',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadTransactions(reset: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6549E8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
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
        onTap: () => _onTabChanged(tab),
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

String _formatWalletTxnDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return 'Just now';
  try {
    final date = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txnDay = DateTime(date.year, date.month, date.day);
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final time =
        '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    if (txnDay == today) return 'Today, $time';
    if (txnDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $time';
    }
    return '${date.day}/${date.month}/${date.year}, $time';
  } catch (_) {
    return 'Just now';
  }
}

_WalletTransaction _walletTxnFromApi(Map<String, dynamic> txn) {
  final direction = txn['direction']?.toString().toUpperCase() ?? 'CREDIT';
  final isCredit = direction == 'CREDIT';
  final transactionType = txn['transactionType']?.toString();
  final description =
      txn['description']?.toString().trim() ?? 'Wallet transaction';

  _WalletTxnType type;
  String title;
  switch (transactionType) {
    case 'ADD_FUNDS':
      type = _WalletTxnType.added;
      title = 'Coins Added';
      break;
    case 'REWARD':
      type = _WalletTxnType.reward;
      title = 'Reward';
      break;
    default:
      type = isCredit ? _WalletTxnType.added : _WalletTxnType.spent;
      title = isCredit ? 'Coins Added' : 'Coins Spent';
  }

  return _WalletTransaction(
    id: txn['id']?.toString(),
    title: title,
    subtitle: description,
    amount: CoinService.parseCoinAmount(txn['amount']),
    dateText: _formatWalletTxnDate(txn['createdAt']?.toString()),
    type: type,
    raw: txn,
  );
}

class _WalletTransaction {
  final String? id;
  final String title;
  final String subtitle;
  final int amount;
  final String dateText;
  final _WalletTxnType type;
  final Map<String, dynamic>? raw;

  const _WalletTransaction({
    this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateText,
    required this.type,
    this.raw,
  });
}

class _TransactionDetailSheet extends StatefulWidget {
  final CoinService coinService;
  final String transactionId;
  final _WalletTransaction fallback;

  const _TransactionDetailSheet({
    required this.coinService,
    required this.transactionId,
    required this.fallback,
  });

  @override
  State<_TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  Map<String, dynamic>? _txn;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final txn = await widget.coinService.getTransactionById(
        widget.transactionId,
      );
      if (!mounted) return;
      setState(() {
        _txn = txn;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _txn = widget.fallback.raw;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final txn = _txn ?? widget.fallback.raw ?? {};
    final amount = CoinService.parseCoinAmount(txn['amount']);
    final direction = txn['direction']?.toString().toUpperCase() ?? 'CREDIT';
    final isCredit = direction == 'CREDIT';
    final status = txn['status']?.toString() ?? '—';
    final balanceBefore = txn['balanceBefore']?.toString() ?? '—';
    final balanceAfter = txn['balanceAfter']?.toString() ?? '—';
    final description =
        txn['description']?.toString() ?? widget.fallback.subtitle;
    final type = txn['transactionType']?.toString() ?? '—';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6549E8)),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  '${isCredit ? '+' : '-'}$amount',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: isCredit
                        ? const Color(0xFF15A34A)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow('Type', type.replaceAll('_', ' ')),
                _detailRow('Status', status),
                _detailRow('Balance before', balanceBefore),
                _detailRow('Balance after', balanceAfter),
                if (txn['createdAt'] != null)
                  _detailRow(
                    'Date',
                    _formatWalletTxnDate(txn['createdAt']?.toString()),
                  ),
              ],
            ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
