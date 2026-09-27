// ignore: file_names
import 'package:yempover_app/services/service_booking_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsDashboardScreen extends StatefulWidget {
  final bool initialProviderTab;

  const AppointmentsDashboardScreen({
    super.key,
    this.initialProviderTab = true,
  });

  @override
  State<AppointmentsDashboardScreen> createState() =>
      _AppointmentsDashboardScreenState();
}

class _AppointmentsDashboardScreenState
    extends State<AppointmentsDashboardScreen>
    with SingleTickerProviderStateMixin {
  final ServiceBookingService _service = ServiceBookingService();
  final TradeChatService _chatService = TradeChatService();
  final TokenService _tokenService = TokenService();

  late final TabController _tabController;
  bool _loading = true;
  String? _chatLoadingAppointmentId;
  String? _currentUserId;
  String? _error;
  List<Map<String, dynamic>> _providerAppointments = [];
  List<Map<String, dynamic>> _clientAppointments = [];
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';

  void _sortAppointmentsDesc(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final dateAStr = a['slotDate']?.toString() ?? a['appointmentDate']?.toString() ?? a['createdAt']?.toString() ?? '';
      final timeAStr = a['slotTime']?.toString() ?? a['time']?.toString() ?? '';
      final dateBStr = b['slotDate']?.toString() ?? b['appointmentDate']?.toString() ?? b['createdAt']?.toString() ?? '';
      final timeBStr = b['slotTime']?.toString() ?? b['time']?.toString() ?? '';

      final dtA = DateTime.tryParse('$dateAStr $timeAStr'.trim()) ?? DateTime.tryParse(dateAStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTime.tryParse('$dateBStr $timeBStr'.trim()) ?? DateTime.tryParse(dateBStr) ?? DateTime.fromMillisecondsSinceEpoch(0);

      return dtB.compareTo(dtA);
    });
  }

  // Formats a slot for display from the server's own wall-clock date/time
  // strings (or a regex extraction of a raw ISO string as fallback) — never
  // via DateTime.parse(...).toLocal()/.toUtc(), which re-interprets the
  // digits against the device's timezone and is what previously turned a
  // 12:30 booking into 5:30.
  String _formatSlot({String? date, String? time, String? fallbackIso}) {
    var d = (date != null && date.isNotEmpty) ? date : null;
    var t = (time != null && time.isNotEmpty) ? time : null;
    if (d == null && fallbackIso != null) {
      d = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(fallbackIso)?.group(1);
    }
    if (t == null && fallbackIso != null) {
      t = RegExp(r'T(\d{2}:\d{2})').firstMatch(fallbackIso)?.group(1);
    }
    if (d == null) return fallbackIso ?? '-';

    final dateParts = d.split('-');
    if (dateParts.length != 3) return fallbackIso ?? d;
    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null || month < 1 || month > 12) {
      return fallbackIso ?? d;
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateText = '${months[month - 1]} $day, $year';
    if (t == null) return dateText;

    final timeParts = t.split(':');
    if (timeParts.length != 2) return dateText;
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return dateText;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final timeText = '$displayHour:${minute.toString().padLeft(2, '0')} $period';

    return '$dateText • $timeText';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialProviderTab ? 0 : 1,
    );
    _loadCurrentUser();
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = await _tokenService.getUserId();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final provider = await _service.getProviderAppointments();
      final client = await _service.getClientAppointments();

      if (!mounted) return;

      setState(() {
        final prov = _extractList(provider);
        final cl = _extractList(client);
        _sortAppointmentsDesc(prov);
        _sortAppointmentsDesc(cl);
        _providerAppointments = prov;
        _clientAppointments = cl;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _service.extractMessage(error);
      });
    }
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final keys = ['appointments', 'items', 'list', 'rows'];
      for (final key in keys) {
        final val = data[key];
        if (val is List) {
          return val
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }

  Future<void> _handleAction({
    required String appointmentId,
    required String action,
    String? reason,
  }) async {
    try {
      switch (action) {
        case 'confirm':
          await _service.confirmAppointment(appointmentId);
          break;
        case 'cancel':
          await _service.cancelAppointment(appointmentId);
          break;
        case 'reject':
          await _service.rejectAppointment(appointmentId, reason: reason);
          break;
        case 'complete':
          await _service.completeAppointment(appointmentId);
          break;
        case 'no-show':
          await _service.noShowAppointment(appointmentId);
          break;
      }

      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        'Appointment ${_getActionPastTense(action)} successfully',
      );
      _loadAll();
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(context, _service.extractMessage(error));
    }
  }

  String? _extractServiceId(Map<String, dynamic> item) {
    final direct = item['serviceId']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final service = item['service'];
    if (service is Map) {
      final id = service['id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }

  String? _readNestedId(dynamic source, List<String> keys) {
    if (source is! Map) return null;

    for (final key in keys) {
      final value = source[key];
      if (value == null) continue;

      if (value is Map) {
        final nestedId = value['id']?.toString();
        if (nestedId != null && nestedId.isNotEmpty) return nestedId;
      }

      final id = value.toString();
      if (id.isNotEmpty && id != 'null') return id;
    }

    return null;
  }

  Future<String?> _resolveResponderIdWithFallback(
    Map<String, dynamic> item,
    bool isProviderTab,
    String serviceId,
    String currentUserId,
  ) async {
    final keyCandidates = isProviderTab
        ? <String>[
            'clientId',
            'requestedById',
            'bookedById',
            'customerId',
            'userId',
          ]
        : <String>[
            'providerId',
            'postedById',
            'serviceProviderId',
            'ownerId',
            'userId',
          ];

    final mapCandidates = isProviderTab
        ? <String>['client', 'requestedBy', 'bookedBy', 'customer']
        : <String>['provider', 'serviceProvider', 'owner', 'postedBy'];

    // 1) Try direct keys on appointment payload
    final directId = _readNestedId(item, keyCandidates);
    if (directId != null && directId != currentUserId) {
      return directId;
    }

    // 2) Try nested participant objects on appointment payload
    final nestedId = _readNestedId(item, mapCandidates);
    if (nestedId != null && nestedId != currentUserId) {
      return nestedId;
    }

    // 3) Try inside service object from appointment payload
    final service = item['service'];
    final serviceObjectId = _readNestedId(service, [
      'postedById',
      'providerId',
      'userId',
      'ownerId',
      'provider',
      'postedBy',
    ]);
    if (serviceObjectId != null && serviceObjectId != currentUserId) {
      return serviceObjectId;
    }

    // 4) Fallback: fetch service detail and use owner/provider from there.
    try {
      final detail = await _service.getServiceDetail(serviceId);
      final data = detail['data'];
      if (data is Map) {
        final serviceData = data['service'] is Map ? data['service'] : data;
        final fallbackId = _readNestedId(serviceData, [
          'postedById',
          'providerId',
          'userId',
          'ownerId',
          'provider',
          'postedBy',
        ]);
        if (fallbackId != null && fallbackId != currentUserId) {
          return fallbackId;
        }
      }
    } catch (_) {
      // Keep null and show user-facing message at call site.
    }

    return null;
  }

  Future<void> _openAppointmentChat(
    Map<String, dynamic> item,
    bool isProviderTab,
  ) async {
    final appointmentId = item['id']?.toString() ?? '';
    if (appointmentId.isEmpty) return;
    if (_chatLoadingAppointmentId == appointmentId) return;

    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      SnackbarUtils.showLoginDialog(context);
      return;
    }

    final currentUserId = _currentUserId ?? await _tokenService.getUserId();
    if (currentUserId == null || currentUserId.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'Unable to identify current user. Please login again.',
      );
      return;
    }

    final serviceId = _extractServiceId(item);
    if (serviceId == null || serviceId.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'Unable to open chat for this appointment.',
      );
      return;
    }

    final responderId = await _resolveResponderIdWithFallback(
      item,
      isProviderTab,
      serviceId,
      currentUserId,
    );
    if (responderId == null || responderId.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'Unable to find chat participant. Please try after refreshing appointments.',
      );
      return;
    }

    setState(() => _chatLoadingAppointmentId = appointmentId);

    try {
      final chat = await _chatService.initiateChat(
        responderId: responderId,
        serviceId: serviceId,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chat: chat,
            currentUserId: currentUserId,
            onChatUpdated: (_) {},
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _chatLoadingAppointmentId = null);
      }
    }
  }

  String _getActionPastTense(String action) {
    switch (action) {
      case 'confirm':
        return 'confirmed';
      case 'cancel':
        return 'cancelled';
      case 'reject':
        return 'rejected';
      case 'complete':
        return 'completed';
      case 'no-show':
        return 'marked as no-show';
      default:
        return action;
    }
  }

  // Preferred order regardless of which are actually available.
  static const List<String> _actionOrder = [
    'confirm',
    'reject',
    'reschedule',
    'cancel',
    'complete',
    'no-show',
  ];

  // Drives button visibility off the server's `actions` object when present
  // (the source of truth — it already accounts for who's viewing and what
  // status allows). Falls back to the old hardcoded status-based rules only
  // for appointments loaded before this field existed.
  List<String> _actionsForItem(Map<String, dynamic> item, bool isProvider) {
    final actions = item['actions'];
    if (actions is Map) {
      const keyForAction = {
        'confirm': 'canConfirm',
        'reject': 'canReject',
        'reschedule': 'canReschedule',
        'cancel': 'canCancel',
        'complete': 'canComplete',
        'no-show': 'canMarkNoShow',
      };
      return _actionOrder
          .where((action) => actions[keyForAction[action]] == true)
          .toList();
    }

    final status = item['status']?.toString() ?? 'UNKNOWN';
    return isProvider
        ? _legacyProviderActions(status)
        : _legacyClientActions(status);
  }

  List<String> _legacyProviderActions(String status) {
    switch (status) {
      case 'REQUESTED':
        return ['confirm', 'reject'];
      case 'CONFIRMED':
        return ['complete', 'no-show', 'cancel'];
      default:
        return const [];
    }
  }

  List<String> _legacyClientActions(String status) {
    if (status == 'REQUESTED' || status == 'CONFIRMED') {
      return ['cancel'];
    }
    return const [];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'REQUESTED':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'NO_SHOW':
        return Colors.deepOrange;
      case 'CANCELLED_BY_CLIENT':
      case 'CANCELLED_BY_SERVICE_PROVIDER':
      case 'REJECTED_BY_SERVICE_PROVIDER':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'REQUESTED':
        return Icons.access_time;
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'COMPLETED':
        return Icons.done_all;
      case 'NO_SHOW':
        return Icons.person_off;
      case 'CANCELLED_BY_CLIENT':
      case 'CANCELLED_BY_SERVICE_PROVIDER':
        return Icons.cancel;
      case 'REJECTED_BY_SERVICE_PROVIDER':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'confirm':
        return 'Confirm';
      case 'cancel':
        return 'Cancel';
      case 'reject':
        return 'Reject';
      case 'reschedule':
        return 'Reschedule Slot';
      case 'complete':
        return 'Complete';
      case 'no-show':
        return 'No Show';
      default:
        return action;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'confirm':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'reject':
        return Colors.red;
      case 'reschedule':
        return Colors.indigo;
      case 'complete':
        return Colors.blue;
      case 'no-show':
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.deepPurple,
              indicatorWeight: 3,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center, size: 18),
                      SizedBox(width: 8),
                      Text('My Offers'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 8),
                      Text('My Requests'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading appointments...'),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadAll,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: const Color(0xFF2E5BFF),
              backgroundColor: Colors.white,
              elevation: 0,
              strokeWidth: 2.2,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_providerAppointments, true),
                  _buildList(_clientAppointments, false),
                ],
              ),
            ),
    );
  }

  List<Map<String, dynamic>> _getFilteredList(
    List<Map<String, dynamic>> items,
  ) {
    var result = items;
    if (_selectedStatusFilter != 'ALL') {
      result = result.where((item) {
        final st = (item['status']?.toString() ?? '').toUpperCase();
        if (_selectedStatusFilter == 'CANCELLED') {
          return st.startsWith('CANCELLED') || st.startsWith('REJECTED');
        }
        return st == _selectedStatusFilter;
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((item) {
        final serviceInfo = item['service'];
        final title = (serviceInfo is Map ? serviceInfo['title'] : item['serviceTitle'])?.toString().toLowerCase() ?? '';
        final statusStr = (item['status']?.toString() ?? '').toLowerCase();
        final clientName = _getClientName(item['client']).toLowerCase();
        final providerName = _getProviderName(item['provider']).toLowerCase();
        return title.contains(q) || statusStr.contains(q) || clientName.contains(q) || providerName.contains(q);
      }).toList();
    }
    return result;
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedStatusFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.white : Colors.grey[800],
        ),
      ),
      selected: selected,
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey[200],
      onSelected: (val) {
        if (val) {
          setState(() => _selectedStatusFilter = value);
        }
      },
    );
  }

  Widget _buildEmptyState(bool isProvider) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isProvider ? Icons.business_center : Icons.event_busy,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No appointments found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isProvider
                    ? 'When clients book your services,\nthey will appear here'
                    : 'Book a service to see your\nappointments here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item, bool isProvider) {
    final status = item['status']?.toString() ?? 'UNKNOWN';
    final serviceInfo = item['service'];
    final serviceTitle = serviceInfo is Map
        ? serviceInfo['title']?.toString() ?? 'Service'
        : item['serviceTitle']?.toString() ?? 'Service';
    final formattedDate = _formatSlot(
      date: item['slotDate']?.toString(),
      time: item['slotTime']?.toString(),
      fallbackIso: item['appointmentDate']?.toString(),
    );
    final statusLabel = item['statusLabel']?.toString() ?? status;
    final otherName = isProvider
        ? _getClientName(item['client'])
        : _getProviderName(item['provider']);

    return InkWell(
      onTap: () => _showAppointmentDetailsModal(item, isProvider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(status), size: 12, color: _getStatusColor(status)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Service Title
            Text(
              serviceTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Person Name
            Row(
              children: [
                Icon(
                  isProvider ? Icons.person_outline : Icons.business_outlined,
                  size: 12,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    otherName,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Tap for Details',
                style: TextStyle(fontSize: 9, color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetailsModal(
    Map<String, dynamic> item,
    bool isProvider,
  ) {
    final status = item['status']?.toString() ?? 'UNKNOWN';
    final appointmentId = item['id']?.toString() ?? '';
    final serviceInfo = item['service'];
    final serviceTitle = serviceInfo is Map
        ? serviceInfo['title']?.toString() ?? 'Service'
        : item['serviceTitle']?.toString() ?? 'Service';
    final formattedDate = _formatSlot(
      date: item['slotDate']?.toString(),
      time: item['slotTime']?.toString(),
      fallbackIso: item['appointmentDate']?.toString(),
    );
    final statusLabel = item['statusLabel']?.toString() ?? status;
    final actions = _actionsForItem(item, isProvider);
    final otherName = isProvider
        ? _getClientName(item['client'])
        : _getProviderName(item['provider']);
    final isChatLoading = _chatLoadingAppointmentId == appointmentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(status), size: 14, color: _getStatusColor(status)),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                serviceTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isProvider ? Icons.person : Icons.business,
                    size: 18,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isProvider ? 'Client' : 'Provider'}: $otherName',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Action buttons
              if (actions.isNotEmpty) ...[
                const Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Column(
                  children: actions.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(modalContext);
                            _dispatchAction(action, appointmentId, item);
                          },
                          icon: Icon(_getActionIcon(action), size: 18),
                          label: Text(_getActionLabel(action)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getActionColor(action),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Open Chat button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isChatLoading
                      ? null
                      : () {
                          Navigator.pop(modalContext);
                          _openAppointmentChat(item, isProvider);
                        },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Open Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> rawItems, bool isProvider) {
    final filteredItems = _getFilteredList(rawItems);

    return Column(
      children: [
        // Auto search & Status filters
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Auto search by service, status or name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  fillColor: Colors.grey[100],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All'),
                    const SizedBox(width: 6),
                    _buildFilterChip('REQUESTED', 'Requested'),
                    const SizedBox(width: 6),
                    _buildFilterChip('CONFIRMED', 'Confirmed'),
                    const SizedBox(width: 6),
                    _buildFilterChip('COMPLETED', 'Completed'),
                    const SizedBox(width: 6),
                    _buildFilterChip('CANCELLED', 'Cancelled'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid View or Empty State
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState(isProvider)
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.88,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildGridCard(item, isProvider);
                  },
                ),
        ),
      ],
    );
  }

  String _getClientName(dynamic client) {
    if (client is Map) {
      final explicitName = client['name']?.toString().trim();
      if (explicitName != null && explicitName.isNotEmpty) return explicitName;
      final fullName =
          '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'.trim();
      return fullName.isNotEmpty ? fullName : 'Client';
    }
    return 'Client';
  }

  String _getProviderName(dynamic provider) {
    if (provider is Map) {
      final explicitName = provider['name']?.toString().trim();
      if (explicitName != null && explicitName.isNotEmpty) {
        return explicitName;
      }
      final fullName =
          '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
      return fullName.isNotEmpty ? fullName : 'Provider';
    }
    return 'Provider';
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'confirm':
        return Icons.check;
      case 'cancel':
        return Icons.close;
      case 'reject':
        return Icons.block;
      case 'reschedule':
        return Icons.edit_calendar;
      case 'complete':
        return Icons.done_all;
      case 'no-show':
        return Icons.person_off;
      default:
        return Icons.arrow_forward;
    }
  }

  void _showActionDialog(String action, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${_getActionLabel(action)} Appointment'),
        content: Text(
          'Are you sure you want to ${action.toLowerCase()} this appointment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAction(appointmentId: appointmentId, action: action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActionColor(action),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(_getActionLabel(action)),
          ),
        ],
      ),
    );
  }

  void _dispatchAction(
    String action,
    String appointmentId,
    Map<String, dynamic> item,
  ) {
    switch (action) {
      case 'reject':
        _showRejectDialog(appointmentId);
        break;
      case 'reschedule':
        _openReschedulePicker(item);
        break;
      default:
        _showActionDialog(action, appointmentId);
    }
  }

  void _showRejectDialog(String appointmentId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Booking Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let the client know why you're declining this request.",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.pop(dialogContext);
              _handleAction(
                appointmentId: appointmentId,
                action: 'reject',
                reason: reason.isEmpty ? null : reason,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  static const List<String> _weekdayNames = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  // Only shows/allows dates+times the provider actually saved as available
  // (via GET .../reschedule-options) — the server is the source of truth,
  // so the picker never offers a slot that would 400. Rebuilt around the
  // real single-day response shape: {current, weeklyAvailability,
  // specialDates, availability:{slotDetails,...}} — the date picker is
  // built locally from weeklyAvailability + specialDates, and a fresh call
  // is made each time the user picks a different date.
  Future<void> _openReschedulePicker(Map<String, dynamic> item) async {
    final appointmentId = item['id']?.toString() ?? '';
    if (appointmentId.isEmpty) return;

    bool initialized = false;
    bool loading = true;
    String? loadError;
    Map<String, dynamic>? current;
    List<Map<String, dynamic>> weeklyAvailability = [];
    List<Map<String, dynamic>> specialDates = [];
    Map<String, dynamic>? availability;
    DateTime? selectedDate;
    String? selectedSlot;
    int? duration;
    bool submitting = false;
    final notesController = TextEditingController();
    final dayFormat = DateFormat('EEE, MMM d');

    bool isDateSelectable(DateTime date) {
      final dateKey = _service.dateOnly(date);
      for (final special in specialDates) {
        if ((special['date']?.toString() ?? '').startsWith(dateKey)) {
          return special['isAvailable'] == true;
        }
      }
      final dayName = _weekdayNames[date.weekday - 1];
      return weeklyAvailability.any(
        (d) => d['dayOfWeek'] == dayName && d['isAvailable'] == true,
      );
    }

    Future<void> loadForDate(
      DateTime? date,
      void Function(void Function()) setSheetState,
    ) async {
      setSheetState(() => loading = true);
      try {
        final response = await _service.getRescheduleOptionsForAppointment(
          appointmentId,
          date: date != null ? _service.dateOnly(date) : null,
        );
        final data = response['data'];
        final map = data is Map ? Map<String, dynamic>.from(data) : {};
        final currentMap = map['current'] is Map
            ? Map<String, dynamic>.from(map['current'])
            : null;
        final availabilityMap = map['availability'] is Map
            ? Map<String, dynamic>.from(map['availability'])
            : null;
        final weekly = (map['weeklyAvailability'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        final special = (map['specialDates'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        DateTime resolvedDate = date ?? DateTime.now();
        if (date == null) {
          final selectedDateStr = map['selectedDate']?.toString();
          if (selectedDateStr != null) {
            try {
              resolvedDate = DateTime.parse(selectedDateStr);
            } catch (_) {}
          }
        }

        setSheetState(() {
          current ??= currentMap;
          weeklyAvailability = weekly;
          specialDates = special;
          availability = availabilityMap;
          selectedDate = resolvedDate;
          duration ??= currentMap?['durationMinutes'] is num
              ? (currentMap!['durationMinutes'] as num).toInt()
              : null;
          // Pre-select the currently-held slot (isCurrent) the first time
          // through, or the just-picked date's own slot if it carries one.
          final slotDetails =
              (availabilityMap?['slotDetails'] as List?)
                  ?.whereType<Map>()
                  .toList() ??
              const [];
          final currentSlot = slotDetails.firstWhere(
            (s) => s['isCurrent'] == true,
            orElse: () => const {},
          );
          if (currentSlot.isNotEmpty) {
            selectedSlot = currentSlot['time']?.toString();
          } else if (date != null) {
            // A fresh date the user picked has no "current" slot to default
            // to — clear any stale selection from the previous day.
            selectedSlot = null;
          } else {
            selectedSlot = currentMap?['time']?.toString();
          }
          loading = false;
          loadError = null;
        });
      } catch (e) {
        setSheetState(() {
          loading = false;
          loadError = _service.extractMessage(e);
        });
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (!initialized) {
              initialized = true;
              Future.microtask(() => loadForDate(null, setSheetState));
            }

            final slotDetails =
                (availability?['slotDetails'] as List?)
                    ?.whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList() ??
                const <Map<String, dynamic>>[];

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reschedule Slot',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only days and times the provider has saved as available are shown.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    if (loading && current == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (weeklyAvailability.isEmpty && specialDates.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          loadError ??
                              'The provider has not saved any availability yet.',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else ...[
                      const Text(
                        'Date',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 60)),
                            selectableDayPredicate: isDateSelectable,
                          );
                          if (picked == null) return;
                          await loadForDate(picked, setSheetState);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedDate != null
                                    ? dayFormat.format(selectedDate!)
                                    : 'Pick a date',
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Time',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (slotDetails.isEmpty)
                        Text(
                          availability?['reason']?.toString() ??
                              'No free slots on this day.',
                          style: const TextStyle(color: Colors.red),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: slotDetails.map((slot) {
                            final time = slot['time']?.toString() ?? '';
                            final status = slot['status']?.toString() ?? '';
                            final isCurrent = slot['isCurrent'] == true;
                            final isBookable =
                                slot['isBookable'] == true || isCurrent;
                            final isSelected = selectedSlot == time;
                            // QA BUG-5/6: show the actual appointment window
                            // ("9:00 AM – 2:00 PM"), never the raw 24-hour
                            // start time the server stores it as.
                            final displayLabel =
                                slot['label']?.toString() ??
                                slot['startTimeLabel']?.toString() ??
                                time;
                            final label = isCurrent
                                ? '$displayLabel (current)'
                                : displayLabel;
                            return Tooltip(
                              message: !isBookable
                                  ? (slot['reason']?.toString() ??
                                        (status.isNotEmpty
                                            ? status
                                            : 'Not available'))
                                  : '',
                              child: ChoiceChip(
                                label: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: !isBookable ? Colors.grey : null,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: !isBookable
                                    ? null
                                    : (_) => setSheetState(
                                        () => selectedSlot = time,
                                      ),
                                backgroundColor: !isBookable
                                    ? Colors.grey.shade100
                                    : null,
                                selectedColor: Colors.indigo.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Reason (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (selectedDate == null ||
                                  selectedSlot == null ||
                                  submitting)
                              ? null
                              : () async {
                                  setSheetState(() => submitting = true);
                                  try {
                                    final response = await _service
                                        .rescheduleAppointment(
                                          appointmentId,
                                          appointmentDate: _service.dateOnly(
                                            selectedDate!,
                                          ),
                                          appointmentTime: selectedSlot!,
                                          duration: duration,
                                          reason: notesController.text.trim(),
                                        );
                                    if (!mounted) return;
                                    Navigator.pop(sheetContext);
                                    final appointmentData = response['data'];
                                    final appt = appointmentData is Map
                                        ? appointmentData['appointment']
                                        : null;
                                    final requiresReconfirmation =
                                        appt is Map &&
                                        appt['requiresReconfirmation'] == true;
                                    SnackbarUtils.showSuccess(
                                      context,
                                      requiresReconfirmation
                                          ? 'Slot rescheduled — the booking is back to Pending for the provider to re-confirm.'
                                          : 'Slot rescheduled successfully',
                                    );
                                    _loadAll();
                                  } catch (e) {
                                    setSheetState(() => submitting = false);
                                    if (!mounted) return;
                                    SnackbarUtils.showError(
                                      context,
                                      _service.extractMessage(e),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Confirm Reschedule'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
