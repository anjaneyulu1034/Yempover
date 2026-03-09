import 'package:Yempover_app/services/service_booking_service.dart';
import 'package:flutter/material.dart';

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

  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _providerAppointments = [];
  List<Map<String, dynamic>> _clientAppointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialProviderTab ? 0 : 1,
    );
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${action.toUpperCase()} successful'),
        ),
      );
      _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_service.extractMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Provider'),
            Tab(text: 'Client'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _loadAll,
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
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No appointments yet')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final status = item['status']?.toString() ?? 'UNKNOWN';
        final appointmentId = item['id']?.toString() ?? '';
        final serviceInfo = item['service'];
        final serviceTitle = serviceInfo is Map
            ? serviceInfo['title']?.toString() ?? 'Service'
            : item['serviceTitle']?.toString() ?? 'Service';
        final whenText = item['appointmentDate']?.toString() ?? '-';

        final actions = isProvider
            ? _providerActions(status)
            : _clientActions(status);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text('When: $whenText'),
                Text('Status: $status'),
                const SizedBox(height: 10),
                if (actions.isEmpty)
                  const Text('Read-only', style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    children: actions
                        .map(
                          (action) => OutlinedButton(
                            onPressed: appointmentId.isEmpty
                                ? null
                                : () => _handleAction(
                                    appointmentId: appointmentId,
                                    action: action,
                                  ),
                            child: Text(_label(action)),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _label(String action) {
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
}
