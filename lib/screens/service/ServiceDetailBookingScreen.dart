import 'package:Yempover_app/screens/service/AppointmentsDashboardScreen.dart';
import 'package:Yempover_app/screens/service/ServiceAvailabilityScreen.dart';
import 'package:Yempover_app/services/service_booking_service.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:flutter/material.dart';

class ServiceDetailBookingScreen extends StatefulWidget {
  final String serviceId;

  const ServiceDetailBookingScreen({super.key, required this.serviceId});

  @override
  State<ServiceDetailBookingScreen> createState() =>
      _ServiceDetailBookingScreenState();
}

class _ServiceDetailBookingScreenState
    extends State<ServiceDetailBookingScreen> {
  final ServiceBookingService _service = ServiceBookingService();
  final TokenService _tokenService = TokenService();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _loadingService = true;
  bool _loadingSlots = false;
  bool _booking = false;
  bool _loggedIn = false;
  String? _error;
  String? _currentUserId;

  Map<String, dynamic>? _serviceData;
  List<Map<String, dynamic>> _slots = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedSlot;

  int _duration = 30;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _loggedIn = await _tokenService.isLoggedIn();
    _currentUserId = await _tokenService.getUserId();
    await _loadService();
    await _loadSlotsForDate(_selectedDate);
  }

  Future<void> _loadService() async {
    setState(() {
      _loadingService = true;
      _error = null;
    });

    try {
      final response = await _service.getServiceDetail(widget.serviceId);
      final data = response['data'];
      Map<String, dynamic> parsed = {};

      if (data is Map<String, dynamic>) {
        parsed = data['service'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['service'])
            : Map<String, dynamic>.from(data);
      }

      if (!mounted) return;
      setState(() {
        _serviceData = parsed;
        _loadingService = false;
        _locationController.text = parsed['location']?.toString() ?? '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _service.extractMessage(error);
        _loadingService = false;
      });
    }
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() {
      _loadingSlots = true;
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedSlot = null;
    });

    try {
      final response = await _service.getAvailableSlots(
        serviceId: widget.serviceId,
        date: _service.dateOnly(_selectedDate),
      );
      final data = response['data'];
      List<Map<String, dynamic>> slots = [];

      if (data is List) {
        slots = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (data is Map<String, dynamic>) {
        final candidates = [
          data['slots'],
          data['availableSlots'],
          data['items'],
        ];
        for (final source in candidates) {
          if (source is List) {
            slots = source
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            break;
          }
        }
      }

      final now = DateTime.now();
      final isToday =
          now.year == _selectedDate.year &&
          now.month == _selectedDate.month &&
          now.day == _selectedDate.day;

      if (isToday) {
        slots = slots.where((slot) {
          final start = _slotDateTime(slot);
          return start == null || start.isAfter(now);
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSlots = false;
        _slots = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_service.extractMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool get _isOwner {
    final service = _serviceData;
    if (service == null) return false;

    final directPostedBy = service['postedById']?.toString();
    final directUserId = service['userId']?.toString();

    final provider = service['provider'];
    final providerId = provider is Map ? provider['id']?.toString() : null;

    return _currentUserId != null &&
        _currentUserId!.isNotEmpty &&
        (_currentUserId == directPostedBy ||
            _currentUserId == directUserId ||
            _currentUserId == providerId);
  }

  bool get _isValid {
    final service = _serviceData;
    if (service == null) return false;

    final isValid = service['isValid'];
    if (isValid is bool) return isValid;

    final hasExpired = service['hasExpired'];
    if (hasExpired is bool && hasExpired) return false;

    return service['isListed'] != false;
  }

  String get _invalidReason {
    final service = _serviceData;
    if (service == null) return 'Service unavailable';
    return service['invalidReason']?.toString() ??
        service['reason']?.toString() ??
        service['message']?.toString() ??
        'Service is not available for booking';
  }

  DateTime? _slotDateTime(Map<String, dynamic> slot) {
    final dateTimeCandidates = [
      slot['startDateTime'],
      slot['appointmentDate'],
      slot['dateTime'],
      slot['slotDateTime'],
    ];

    for (final raw in dateTimeCandidates) {
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed.toLocal();
    }

    final time = slot['startTime']?.toString() ?? slot['time']?.toString();
    return _service.parseTimeOfDay(_selectedDate, time);
  }

  String _slotLabel(Map<String, dynamic> slot) {
    final dt = _slotDateTime(slot);
    final end = slot['endTime']?.toString();

    if (dt != null) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      if (end != null && end.isNotEmpty) {
        return '$hh:$mm - $end';
      }
      return '$hh:$mm';
    }

    return slot['startTime']?.toString() ?? slot['time']?.toString() ?? 'Slot';
  }

  bool _slotAvailable(Map<String, dynamic> slot) {
    final available = slot['available'];
    if (available is bool) return available;
    return slot['isAvailable'] != false;
  }

  String? _slotReason(Map<String, dynamic> slot) {
    return slot['reason']?.toString() ?? slot['message']?.toString();
  }

  Future<void> _book() async {
    if (!_loggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_invalidReason), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _booking = true);

    try {
      await _loadSlotsForDate(_selectedDate);

      final selectedLabel = _slotLabel(_selectedSlot!);
      final currentSelected = _slots.where((slot) {
        return _slotLabel(slot) == selectedLabel && _slotAvailable(slot);
      }).toList();

      if (currentSelected.isEmpty) {
        throw Exception(
          'Selected slot is no longer available. Please pick another slot.',
        );
      }

      _selectedSlot = currentSelected.first;
      final dateTime = _slotDateTime(_selectedSlot!);
      if (dateTime == null) {
        throw Exception('Unable to resolve slot date/time');
      }

      final payloadDate = _service.isoWithOffset(dateTime);
      final duration =
          (_selectedSlot!['slotDurationMinutes'] as int?) ?? _duration;

      await _service.createAppointment(
        serviceId: widget.serviceId,
        appointmentDate: payloadDate,
        duration: duration,
        location: _locationController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment requested (REQUESTED)')),
      );

      await _loadSlotsForDate(_selectedDate);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_service.extractMessage(error)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _booking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Detail')),
      body: _loadingService
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final service = _serviceData ?? {};
    final provider = service['provider'];
    final providerName = provider is Map
        ? ((provider['name']?.toString() ?? '').isNotEmpty
              ? provider['name'].toString()
              : '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'
                    .trim())
        : 'Provider';

    final weekly = service['availabilitySlots'] is List
        ? (service['availabilitySlots'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    final canBook = _loggedIn && !_isOwner && _isValid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service['title']?.toString() ?? 'Service',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(service['description']?.toString() ?? '-'),
          const SizedBox(height: 10),
          Text('Provider: $providerName'),
          const SizedBox(height: 6),
          Text('Location: ${service['location'] ?? '-'}'),
          const SizedBox(height: 6),
          Text('Price: ${service['price'] ?? '-'}'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isValid ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_isValid ? 'Valid' : _invalidReason),
          ),
          const SizedBox(height: 20),
          const Text(
            'Weekly Availability',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (weekly.isEmpty)
            const Text('No weekly schedule found')
          else
            ...weekly.map(
              (slot) => Text(
                '${slot['dayOfWeek']}: ${slot['isAvailable'] == true ? '${slot['startTime']} - ${slot['endTime']}' : 'Unavailable'}',
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(now.year, now.month, now.day),
                      lastDate: DateTime(now.year + 3),
                    );
                    if (picked == null) return;
                    _loadSlotsForDate(picked);
                  },
                  child: Text('Date: ${_service.dateOnly(_selectedDate)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _loadingSlots
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _slots.map((slot) {
                    final available = _slotAvailable(slot);
                    final selected =
                        _selectedSlot != null &&
                        _slotLabel(_selectedSlot!) == _slotLabel(slot);
                    return ChoiceChip(
                      label: Text(_slotLabel(slot)),
                      selected: selected,
                      onSelected: available
                          ? (_) {
                              setState(() {
                                _selectedSlot = slot;
                                _duration =
                                    (slot['slotDurationMinutes'] as int?) ??
                                    _duration;
                              });
                            }
                          : null,
                    );
                  }).toList(),
                ),
          if (_selectedSlot != null && !_slotAvailable(_selectedSlot!))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _slotReason(_selectedSlot!) ?? 'Not available',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Location',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _duration,
            items: const [15, 30, 45, 60]
                .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _duration = value);
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Duration',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Notes',
            ),
          ),
          const SizedBox(height: 16),
          if (!_loggedIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login to book'),
              ),
            )
          else if (_isOwner)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceAvailabilityScreen(
                          serviceId: widget.serviceId,
                        ),
                      ),
                    ),
                    child: const Text('Manage Availability'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsDashboardScreen(
                          initialProviderTab: true,
                        ),
                      ),
                    ),
                    child: const Text('View Appointments'),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canBook && !_booking ? _book : null,
                child: _booking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(canBook ? 'Book Appointment' : _invalidReason),
              ),
            ),
          const SizedBox(height: 8),
          if (_slots.any(
            (slot) => !_slotAvailable(slot) && _slotReason(slot) != null,
          ))
            Text(
              _slotReason(
                    _slots.firstWhere(
                      (slot) =>
                          !_slotAvailable(slot) && _slotReason(slot) != null,
                      orElse: () => <String, dynamic>{},
                    ),
                  ) ??
                  '',
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
