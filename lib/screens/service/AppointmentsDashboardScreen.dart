// ignore: file_names
import 'package:Yempover_app/services/service_booking_service.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:Yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';
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

  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

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
        _providerAppointments = _extractList(provider);
        _clientAppointments = _extractList(client);
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
  }) async {
    try {
      switch (action) {
        case 'confirm':
          await _service.confirmAppointment(appointmentId);
          break;
        case 'cancel':
          await _service.cancelAppointment(appointmentId);
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
      case 'complete':
        return 'completed';
      case 'no-show':
        return 'marked as no-show';
      default:
        return action;
    }
  }

  List<String> _providerActions(String status) {
    switch (status) {
      case 'REQUESTED':
        return ['confirm', 'cancel'];
      case 'CONFIRMED':
        return ['complete', 'no-show', 'cancel'];
      default:
        return const [];
    }
  }

  List<String> _clientActions(String status) {
    if (status == 'REQUESTED' || status == 'CONFIRMED') {
      return ['cancel'];
    }
    return const [];
  }

  bool _isTerminalStatus(String status) {
    return status == 'CANCELLED_BY_CLIENT' ||
        status == 'CANCELLED_BY_SERVICE_PROVIDER' ||
        status == 'COMPLETED' ||
        status == 'NO_SHOW';
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
        backgroundColor: Colors.transparent,
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
                      Text('Provider'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 18),
                      SizedBox(width: 8),
                      Text('Client'),
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
              color: Colors.deepPurple,
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

  Widget _buildList(List<Map<String, dynamic>> items, bool isProvider) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
                  'No appointments yet',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final status = item['status']?.toString() ?? 'UNKNOWN';
        final appointmentId = item['id']?.toString() ?? '';
        final isChatLoading = _chatLoadingAppointmentId == appointmentId;
        final serviceInfo = item['service'];
        final serviceTitle = serviceInfo is Map
            ? serviceInfo['title']?.toString() ?? 'Service'
            : item['serviceTitle']?.toString() ?? 'Service';

        final appointmentDate = item['appointmentDate']?.toString();
        String formattedDate = '-';
        if (appointmentDate != null) {
          try {
            final date = DateTime.parse(appointmentDate);
            formattedDate = _dateFormat.format(date.toLocal());
          } catch (e) {
            formattedDate = appointmentDate;
          }
        }

        final actions = isProvider
            ? _providerActions(status)
            : _clientActions(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Status Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: _getStatusColor(status).withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: _getStatusColor(status),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (actions.isEmpty && _isTerminalStatus(status))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.work,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Service',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  serviceTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Date/Time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              size: 18,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date & Time',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Client/Provider Info (if available)
                      if (item['client'] != null ||
                          item['provider'] != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isProvider ? Icons.person : Icons.business,
                                size: 18,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isProvider ? 'Client' : 'Provider',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    isProvider
                                        ? _getClientName(item['client'])
                                        : _getProviderName(item['provider']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Actions
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isChatLoading
                                ? null
                                : () => _openAppointmentChat(item, isProvider),
                            icon: isChatLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                  ),
                            label: const Text('Message'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.deepPurple,
                              side: BorderSide(
                                color: Colors.deepPurple.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(double.infinity, 46),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: actions
                              .map(
                                (action) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: appointmentId.isEmpty
                                          ? null
                                          : () => _showActionDialog(
                                              action,
                                              appointmentId,
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _getActionColor(
                                          action,
                                        ).withValues(alpha: 0.1),
                                        foregroundColor: _getActionColor(
                                          action,
                                        ),
                                        elevation: 0,
                                        minimumSize: const Size(
                                          double.infinity,
                                          46,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          side: BorderSide(
                                            color: _getActionColor(
                                              action,
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _getActionIcon(action),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(_getActionLabel(action)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
}
