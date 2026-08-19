import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yempover_app/screens/AddCoinsScreen.dart';
import 'package:yempover_app/services/coin_service.dart';
import 'package:yempover_app/utils/wallet_balance_provider.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

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
  bool _hasLoadedOnce = false;

  final List<_WalletTransaction> _transactions = [];
  bool _transactionsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<WalletBalanceProvider>(
        context,
        listen: false,
      );
      provider.ensureLive();
      provider.addListener(_onLiveBalanceChanged);
    });
  }

  // Keeps the displayed balance current the instant a coin change happens
  // anywhere (top-up, redeem, escrow hold/release/refund) while this screen
  // is open, without waiting for a full _loadWallet() refetch.
  void _onLiveBalanceChanged() {
    if (!mounted) return;
    final live = Provider.of<WalletBalanceProvider>(
      context,
      listen: false,
    ).balance;
    if (live == null || live == _balance) return;
    setState(() {
      _hasWallet = true;
      _balance = live;
    });
  }

  Future<void> _loadWallet({bool keepExistingOnFailure = false}) async {
    final showFullScreenLoader = !_hasLoadedOnce;
    setState(() {
      if (showFullScreenLoader) _isLoading = true;
      if (!keepExistingOnFailure) _loadError = null;
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
          _loadError = null;
          _hasLoadedOnce = true;
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
        _loadError = null;
        _hasLoadedOnce = true;
      });
      await _loadTransactions();
    } catch (e) {
      if (!mounted) return;
      if (keepExistingOnFailure && _hasLoadedOnce) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _loadError = CoinService.friendlyNetworkMessage(e);
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
  void dispose() {
    Provider.of<WalletBalanceProvider>(
      context,
      listen: false,
    ).removeListener(_onLiveBalanceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadWallet(keepExistingOnFailure: true);
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
              'You need +${CoinFormat.amount(requiredAmount)} coins to complete this purchase.',
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
  final ScrollController _dateFilterScrollController = ScrollController();

  _TransactionsTab _selectedTab = _TransactionsTab.all;
  _TransactionDateFilter _dateFilter = _TransactionDateFilter.allTime;
  DateTime? _customFrom;
  DateTime? _customTo;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;
  String? _nextCursor;
  bool _hasMore = false;

  static const Color _accent = Color(0xFF6549E8);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTransactions(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _dateFilterScrollController.dispose();
    super.dispose();
  }

  void _ensureCustomChipVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dateFilterScrollController.hasClients) return;
      _dateFilterScrollController.animateTo(
        _dateFilterScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  String? get _apiTypeFilter {
    switch (_selectedTab) {
      case _TransactionsTab.all:
      case _TransactionsTab.processing:
      case _TransactionsTab.spent:
        return null;
      case _TransactionsTab.added:
        return 'ADD_FUNDS';
    }
  }

  String? get _apiStatusFilter {
    if (_selectedTab == _TransactionsTab.processing) return 'PENDING';
    return null;
  }

  ({DateTime? from, DateTime? to}) get _activeDateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_dateFilter) {
      case _TransactionDateFilter.allTime:
        return (from: null, to: null);
      case _TransactionDateFilter.today:
        return (from: today, to: today);
      case _TransactionDateFilter.last30Days:
        return (from: today.subtract(const Duration(days: 29)), to: today);
      case _TransactionDateFilter.custom:
        return (from: _customFrom, to: _customTo);
    }
  }

  bool get _hasDateFilter => _dateFilter != _TransactionDateFilter.allTime;

  String get _dateFilterSummary {
    final range = _activeDateRange;
    final fmt = DateFormat('d MMM yyyy');
    switch (_dateFilter) {
      case _TransactionDateFilter.allTime:
        return 'All time';
      case _TransactionDateFilter.today:
        return 'Today';
      case _TransactionDateFilter.last30Days:
        return 'Last 30 days';
      case _TransactionDateFilter.custom:
        if (range.from != null && range.to != null) {
          if (_isSameCalendarDay(range.from!, range.to!)) {
            return fmt.format(range.from!);
          }
          return '${fmt.format(range.from!)} – ${fmt.format(range.to!)}';
        }
        if (range.from != null) return 'From ${fmt.format(range.from!)}';
        if (range.to != null) return 'Until ${fmt.format(range.to!)}';
        return 'Custom range';
    }
  }

  bool _isSameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _txnMatchesDateFilter(_WalletTransaction txn) {
    final range = _activeDateRange;
    if (range.from == null && range.to == null) return true;
    final createdAt = txn.createdAt;
    if (createdAt == null) return true;

    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (range.from != null) {
      final fromDay = DateTime(range.from!.year, range.from!.month, range.from!.day);
      if (day.isBefore(fromDay)) return false;
    }
    if (range.to != null) {
      final toDay = DateTime(range.to!.year, range.to!.month, range.to!.day);
      if (day.isAfter(toDay)) return false;
    }
    return true;
  }

  List<_WalletTransaction> _applyFilters(List<_WalletTransaction> items) {
    var filtered = items;
    switch (_selectedTab) {
      case _TransactionsTab.spent:
        filtered = filtered
            .where((t) => t.type == _WalletTxnType.spent && !t.isProcessing)
            .toList();
        break;
      case _TransactionsTab.added:
        filtered = filtered
            .where((t) => !t.isProcessing)
            .toList();
        break;
      case _TransactionsTab.processing:
        filtered = filtered.where((t) => t.isProcessing).toList();
        break;
      case _TransactionsTab.all:
        break;
    }
    if (_hasDateFilter) {
      filtered = filtered.where(_txnMatchesDateFilter).toList();
    }
    return filtered;
  }

  String get _emptyTransactionsMessage {
    if (_hasDateFilter) return 'No transactions for selected dates';
    switch (_selectedTab) {
      case _TransactionsTab.processing:
        return 'No processing transactions';
      case _TransactionsTab.added:
        return 'No added transactions yet';
      case _TransactionsTab.spent:
        return 'No spent transactions yet';
      case _TransactionsTab.all:
        return 'No transactions yet';
    }
  }

  void _onDateFilterChanged(_TransactionDateFilter filter) {
    if (filter == _dateFilter) return;
    setState(() => _dateFilter = filter);
    if (filter == _TransactionDateFilter.custom) {
      _ensureCustomChipVisible();
    }
    _loadTransactions(reset: true);
  }

  void _clearDateFilter() {
    setState(() {
      _dateFilter = _TransactionDateFilter.allTime;
      _customFrom = null;
      _customTo = null;
    });
    _loadTransactions(reset: true);
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showModalBottomSheet<({DateTime from, DateTime to})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomDateRangePickerSheet(
        initialFrom: _customFrom ?? now.subtract(const Duration(days: 30)),
        initialTo: _customTo ?? now,
        maxDate: now,
        accent: _accent,
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _dateFilter = _TransactionDateFilter.custom;
      _customFrom = picked.from;
      _customTo = picked.to;
    });
    _ensureCustomChipVisible();
    _loadTransactions(reset: true);
  }

  Future<void> _loadTransactions({
    required bool reset,
    bool keepExistingOnFailure = false,
  }) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        if (!keepExistingOnFailure) _loadError = null;
        _nextCursor = null;
        _hasMore = false;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final range = _activeDateRange;
      final page = await widget.coinService.getTransactions(
        limit: 20,
        cursor: reset ? null : _nextCursor,
        type: _apiTypeFilter,
        status: _apiStatusFilter,
        fromDate: range.from,
        toDate: range.to,
      );

      var items = _applyFilters(
        page.transactions.map(_walletTxnFromApi).toList(),
      );

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
      final keepExisting = reset && _transactions.isNotEmpty;
      setState(() {
        if (!keepExisting) {
          _loadError = CoinService.friendlyNetworkMessage(e);
        }
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
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickCustomDateRange,
            icon: Icon(
              Icons.calendar_month_outlined,
              color: _hasDateFilter ? _accent : const Color(0xFF111827),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadTransactions(
          reset: true,
          keepExistingOnFailure: true,
        ),
        color: const Color(0xFF6549E8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildTabs(),
              const SizedBox(height: 14),
              _buildDateFilters(),
              if (_hasDateFilter) ...[
                const SizedBox(height: 10),
                _buildActiveDateBanner(),
              ],
              const SizedBox(height: 20),
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
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
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              _emptyTransactionsMessage,
                              style: const TextStyle(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            _buildTabChip('All', _TransactionsTab.all),
            const SizedBox(width: 10),
            _buildTabChip('Added', _TransactionsTab.added),
            const SizedBox(width: 10),
            _buildTabChip('Spent', _TransactionsTab.spent),
            const SizedBox(width: 10),
            _buildTabChip('Processing', _TransactionsTab.processing),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        controller: _dateFilterScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 2, right: 20),
        children: [
          _buildDateChip('All', _TransactionDateFilter.allTime),
          const SizedBox(width: 8),
          _buildDateChip('Today', _TransactionDateFilter.today),
          const SizedBox(width: 8),
          _buildDateChip('30 days', _TransactionDateFilter.last30Days),
          const SizedBox(width: 8),
          _buildDateChip(
            'Custom',
            _TransactionDateFilter.custom,
            onTap: () {
              _ensureCustomChipVisible();
              _pickCustomDateRange();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildDateChip(
    String label,
    _TransactionDateFilter filter, {
    VoidCallback? onTap,
  }) {
    final isSelected = _dateFilter == filter;
    return InkWell(
      onTap: onTap ?? () => _onDateFilterChanged(filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accent : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveDateBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0D8FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, color: _accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing: $_dateFilterSummary',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearDateFilter,
            child: const Text(
              'Clear',
              style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _tabUnselectedColor(_TransactionsTab tab) {
    switch (tab) {
      case _TransactionsTab.spent:
        return const Color(0xFFEF4444);
      case _TransactionsTab.added:
        return const Color(0xFF16A34A);
      case _TransactionsTab.processing:
        return const Color(0xFFF59E0B);
      case _TransactionsTab.all:
        return const Color(0xFF374151);
    }
  }

  Widget _buildTabChip(String label, _TransactionsTab tab) {
    final isSelected = tab == _selectedTab;

    return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _onTabChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.white : _tabUnselectedColor(tab),
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
                if (txn.isProcessing) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Text(
                      'Processing',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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

enum _TransactionsTab { all, added, spent, processing }

enum _TransactionDateFilter { allTime, today, last30Days, custom }

class _CustomDateRangePickerSheet extends StatefulWidget {
  final DateTime initialFrom;
  final DateTime initialTo;
  final DateTime maxDate;
  final Color accent;

  const _CustomDateRangePickerSheet({
    required this.initialFrom,
    required this.initialTo,
    required this.maxDate,
    required this.accent,
  });

  @override
  State<_CustomDateRangePickerSheet> createState() =>
      _CustomDateRangePickerSheetState();
}

class _CustomDateRangePickerSheetState extends State<_CustomDateRangePickerSheet> {
  late int _fromDay;
  late int _fromMonth;
  late int _fromYear;
  late int _toDay;
  late int _toMonth;
  late int _toYear;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _fromDay = widget.initialFrom.day;
    _fromMonth = widget.initialFrom.month;
    _fromYear = widget.initialFrom.year;
    _toDay = widget.initialTo.day;
    _toMonth = widget.initialTo.month;
    _toYear = widget.initialTo.year;
  }

  int get _minYear => 2020;

  int get _maxYear => widget.maxDate.year;

  List<int> get _yearOptions =>
      List.generate(_maxYear - _minYear + 1, (i) => _minYear + i);

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime _dateFrom(int day, int month, int year) =>
      DateTime(year, month, day);

  DateTime get _fromDate => _dateFrom(_fromDay, _fromMonth, _fromYear);

  DateTime get _toDate => _dateFrom(_toDay, _toMonth, _toYear);

  void _clampDayForMonth({required bool isFrom}) {
    final year = isFrom ? _fromYear : _toYear;
    final month = isFrom ? _fromMonth : _toMonth;
    final maxDay = _daysInMonth(year, month);
    if (isFrom) {
      if (_fromDay > maxDay) _fromDay = maxDay;
    } else if (_toDay > maxDay) {
      _toDay = maxDay;
    }
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6B7280),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: widget.accent, width: 1.5),
      ),
    );
  }

  Widget _buildDateDropdowns({
    required String title,
    required int day,
    required int month,
    required int year,
    required ValueChanged<int> onDayChanged,
    required ValueChanged<int> onMonthChanged,
    required ValueChanged<int> onYearChanged,
  }) {
    final days = List.generate(_daysInMonth(year, month), (i) => i + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: day,
                isExpanded: true,
                alignment: Alignment.center,
                decoration: _dropdownDecoration('DD'),
                items: days
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Center(
                          child: Text(
                            d.toString().padLeft(2, '0'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (context) => days
                    .map(
                      (d) => Center(
                        child: Text(
                          d.toString().padLeft(2, '0'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onDayChanged(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: month,
                isExpanded: true,
                alignment: Alignment.center,
                decoration: _dropdownDecoration('MM'),
                items: List.generate(12, (i) => i + 1)
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Center(
                          child: Text(
                            m.toString().padLeft(2, '0'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (context) => List.generate(12, (i) => i + 1)
                    .map(
                      (m) => Center(
                        child: Text(
                          m.toString().padLeft(2, '0'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onMonthChanged(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: year,
                isExpanded: true,
                alignment: Alignment.center,
                decoration: _dropdownDecoration('YYYY'),
                items: _yearOptions
                    .map(
                      (y) => DropdownMenuItem(
                        value: y,
                        child: Center(
                          child: Text(
                            '$y',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                selectedItemBuilder: (context) => _yearOptions
                    .map(
                      (y) => Center(
                        child: Text(
                          '$y',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onYearChanged(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _apply() {
    final from = _fromDate;
    final to = _toDate;
    final max = DateTime(
      widget.maxDate.year,
      widget.maxDate.month,
      widget.maxDate.day,
    );

    if (from.isAfter(max) || to.isAfter(max)) {
      setState(() => _errorText = 'Date cannot be in the future');
      return;
    }
    if (from.isAfter(to)) {
      setState(() => _errorText = 'Start date must be before end date');
      return;
    }

    Navigator.pop(context, (from: from, to: to));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.calendar_month, color: widget.accent),
                  const SizedBox(width: 8),
                  const Text(
                    'Custom date range',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDateDropdowns(
                title: 'From date',
                day: _fromDay,
                month: _fromMonth,
                year: _fromYear,
                onDayChanged: (d) => setState(() {
                  _fromDay = d;
                  _errorText = null;
                }),
                onMonthChanged: (m) => setState(() {
                  _fromMonth = m;
                  _clampDayForMonth(isFrom: true);
                  _errorText = null;
                }),
                onYearChanged: (y) => setState(() {
                  _fromYear = y;
                  _clampDayForMonth(isFrom: true);
                  _errorText = null;
                }),
              ),
              const SizedBox(height: 16),
              _buildDateDropdowns(
                title: 'To date',
                day: _toDay,
                month: _toMonth,
                year: _toYear,
                onDayChanged: (d) => setState(() {
                  _toDay = d;
                  _errorText = null;
                }),
                onMonthChanged: (m) => setState(() {
                  _toMonth = m;
                  _clampDayForMonth(isFrom: false);
                  _errorText = null;
                }),
                onYearChanged: (y) => setState(() {
                  _toYear = y;
                  _clampDayForMonth(isFrom: false);
                  _errorText = null;
                }),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    case 'PAY':
      type = _WalletTxnType.spent;
      title = 'Payment';
      break;
    default:
      type = isCredit ? _WalletTxnType.added : _WalletTxnType.spent;
      title = isCredit ? 'Coins Added' : 'Coins Spent';
  }

  DateTime? createdAt;
  final createdAtRaw = txn['createdAt']?.toString();
  if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
    try {
      createdAt = DateTime.parse(createdAtRaw).toLocal();
    } catch (_) {}
  }

  final status = txn['status']?.toString().toUpperCase() ?? 'COMPLETED';

  return _WalletTransaction(
    id: txn['id']?.toString(),
    title: title,
    subtitle: description,
    amount: CoinService.parseCoinAmount(txn['amount']),
    dateText: _formatWalletTxnDate(createdAtRaw),
    createdAt: createdAt,
    status: status,
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
  final DateTime? createdAt;
  final String status;
  final _WalletTxnType type;
  final Map<String, dynamic>? raw;

  const _WalletTransaction({
    this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateText,
    this.createdAt,
    required this.status,
    required this.type,
    this.raw,
  });

  bool get isProcessing => status == 'PENDING';
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
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                    ),
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
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
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
