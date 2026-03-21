import 'package:Yempover_app/screens/service/AppointmentsDashboardScreen.dart';
import 'package:Yempover_app/screens/service/ServiceAvailabilityScreen.dart';
import 'package:Yempover_app/services/service_booking_service.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ServiceDetailUiState { loadingService, serviceReady, serviceError }

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
  final TextEditingController _quoteController = TextEditingController();

  bool _loadingSlots = false;
  bool _booking = false;
  bool _loggedIn = false;
  String? _error;
  String? _currentUserId;

  Map<String, dynamic>? _serviceData;
  List<Map<String, dynamic>> _slots = [];
  String? _slotsUnavailableReason;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _proposedTime = const TimeOfDay(hour: 10, minute: 0);
  Map<String, dynamic>? _selectedSlot;

  int _duration = 30;
  ServiceDetailUiState _serviceUiState = ServiceDetailUiState.loadingService;

  final DateFormat _dateFormat = DateFormat('EEEE, MMMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    _quoteController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _loggedIn = await _tokenService.isLoggedIn();
    _currentUserId = await _tokenService.getUserId();
    await _loadService();
    if (!_isLookingForService) {
      await _loadSlotsForDate(_selectedDate);
    }
  }

  Future<void> _loadService() async {
    setState(() {
      _serviceUiState = ServiceDetailUiState.loadingService;
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
        _serviceUiState = ServiceDetailUiState.serviceReady;
        _locationController.text = parsed['location']?.toString() ?? '';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _service.extractMessage(error);
        _serviceUiState = ServiceDetailUiState.serviceError;
      });
    }
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    if (_isLookingForService) {
      setState(() {
        _selectedDate = DateTime(date.year, date.month, date.day);
        _loadingSlots = false;
        _slots = const [];
        _slotsUnavailableReason = null;
      });
      return;
    }

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
      String? unavailableReason;

      if (data is List) {
        if (data.isNotEmpty && data.first is String) {
          slots = data
              .whereType<String>()
              .map(
                (t) => <String, dynamic>{
                  'startTime': t,
                  'available': true,
                  'slotDurationMinutes': _duration,
                },
              )
              .toList();
        } else {
          slots = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } else if (data is Map<String, dynamic>) {
        final available = data['available'];
        if (available == false) {
          unavailableReason =
              data['reason']?.toString() ??
              data['message']?.toString() ??
              'No slots available on this date';
        }

        final candidates = [
          data['slots'],
          data['availableSlots'],
          data['items'],
        ];
        for (final source in candidates) {
          if (source is List) {
            if (source.isNotEmpty && source.first is String) {
              slots = source
                  .whereType<String>()
                  .map(
                    (t) => <String, dynamic>{
                      'startTime': t,
                      'available': true,
                      'slotDurationMinutes': _duration,
                    },
                  )
                  .toList();
            } else {
              slots = source
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
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
        final hadSlotsBeforeNowFilter = slots.isNotEmpty;
        slots = slots.where((slot) {
          final start = _slotDateTime(slot);
          return start == null || start.isAfter(now);
        }).toList();

        if (slots.isEmpty && hadSlotsBeforeNowFilter) {
          unavailableReason =
              'No remaining slots for today. Please select another date.';
        }
      }

      if (!mounted) return;
      setState(() {
        _slots = slots;
        _slotsUnavailableReason = unavailableReason;
        _loadingSlots = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSlots = false;
        _slots = [];
        _slotsUnavailableReason = null;
      });
      SnackbarUtils.showError(context, _service.extractMessage(error));
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

  bool get _isLookingForService {
    final status = _serviceData?['status']?.toString();
    return status == 'LOOKING_FOR_SERVICE';
  }

  DateTime? get _serviceValidUntil {
    final raw = _serviceData?['validUntil']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
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
      if (end != null && end.isNotEmpty) {
        return '${_timeFormat.format(dt)} - $end';
      }
      return _timeFormat.format(dt);
    }

    return slot['startTime']?.toString() ?? slot['time']?.toString() ?? 'Slot';
  }

  String? _slotKey(Map<String, dynamic> slot) {
    final dt = _slotDateTime(slot);
    if (dt != null) {
      return '${dt.hour}:${dt.minute}';
    }

    final raw = slot['startTime']?.toString() ?? slot['time']?.toString();
    if (raw == null || raw.isEmpty) return null;

    final parsed = _service.parseTimeOfDay(_selectedDate, raw);
    if (parsed != null) {
      return '${parsed.hour}:${parsed.minute}';
    }

    return raw;
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

    if (!_isLookingForService && _selectedSlot == null) {
      SnackbarUtils.showError(context, 'Please select a time slot');
      return;
    }

    if (_isLookingForService) {
      final quote = double.tryParse(_quoteController.text.trim());
      if (quote == null || quote <= 0) {
        SnackbarUtils.showError(context, 'Please enter your quote price');
        return;
      }
    }

    if (!_isValid) {
      SnackbarUtils.showError(context, _invalidReason);
      return;
    }

    setState(() => _booking = true);

    try {
      late final DateTime dateTime;
      late final int duration;

      if (_isLookingForService) {
        dateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _proposedTime.hour,
          _proposedTime.minute,
        );
        duration = _duration;
      } else {
        final previouslySelectedSlot = _selectedSlot;
        if (previouslySelectedSlot == null) {
          throw Exception('Please select a slot');
        }

        await _loadSlotsForDate(_selectedDate);

        final selectedKey = _slotKey(previouslySelectedSlot);
        final currentSelected = _slots.where((slot) {
          if (!_slotAvailable(slot)) return false;
          if (selectedKey != null) {
            return _slotKey(slot) == selectedKey;
          }
          return _slotLabel(slot) == _slotLabel(previouslySelectedSlot);
        }).toList();

        if (currentSelected.isEmpty) {
          throw Exception(
            'Selected slot is no longer available. Please pick another slot.',
          );
        }

        final matchedSlot = currentSelected.first;
        _selectedSlot = matchedSlot;
        final resolved = _slotDateTime(matchedSlot);
        if (resolved == null) {
          throw Exception('Unable to resolve slot date/time');
        }
        dateTime = resolved;

        final rawDuration = matchedSlot['slotDurationMinutes'];
        duration = rawDuration is int
            ? rawDuration
            : int.tryParse(rawDuration?.toString() ?? '') ?? _duration;
      }

      final payloadDate = _service.isoWithOffset(dateTime);

      await _service.createAppointment(
        serviceId: widget.serviceId,
        appointmentDate: payloadDate,
        duration: duration,
        location: _locationController.text.trim(),
        proposedPrice: _isLookingForService
            ? double.tryParse(_quoteController.text.trim())
            : null,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Appointment requested successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppointmentsDashboardScreen(
                    initialProviderTab: false,
                  ),
                ),
              );
            },
          ),
        ),
      );

      if (!_isLookingForService) {
        await _loadSlotsForDate(_selectedDate);
      }
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(context, _service.extractMessage(error));
    } finally {
      if (mounted) {
        setState(() => _booking = false);
      }
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
          'Service Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _serviceUiState == ServiceDetailUiState.loadingService
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading service details...'),
                ],
              ),
            )
          : _serviceUiState == ServiceDetailUiState.serviceError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'Unable to load service',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadService,
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
    final canBookWithSelection =
        canBook && (_isLookingForService || _selectedSlot != null);

    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2FF7), Color(0xFFAD00FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                service['title']?.toString() ?? 'Service',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isValid ? Icons.check_circle : Icons.warning,
                                size: 16,
                                color: _isValid
                                    ? Colors.green[300]
                                    : Colors.orange[300],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isValid ? 'Available' : _invalidReason,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Service Info Grid
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person, 'Provider', providerName),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow(
                          Icons.location_on,
                          'Location',
                          service['location'] ?? '-',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Price',
                          '${service['price'] ?? '-'}',
                          isPrice: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.description, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          service['description']?.toString() ?? '-',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Weekly Availability
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              'Weekly Availability',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (weekly.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No weekly schedule found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          )
                        else
                          ...weekly.map(
                            (slot) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: slot['isAvailable'] == true
                                          ? Colors.green
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      slot['dayOfWeek']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    slot['isAvailable'] == true
                                        ? '${slot['startTime']} - ${slot['endTime']}'
                                        : 'Unavailable',
                                    style: TextStyle(
                                      color: slot['isAvailable'] == true
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Booking Section
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 8),
                            Text(
                              _isLookingForService
                                  ? 'Send Service Proposal'
                                  : 'Book Appointment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Date Selection
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final validUntil = _serviceValidUntil;
                            final upperBound =
                                validUntil != null && validUntil.isAfter(now)
                                ? DateTime(
                                    validUntil.year,
                                    validUntil.month,
                                    validUntil.day,
                                  )
                                : DateTime(now.year + 3);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(now.year, now.month, now.day),
                              lastDate: upperBound,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.deepPurple,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked == null) return;
                            if (_isLookingForService) {
                              setState(() {
                                _selectedDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                );
                              });
                            } else {
                              _loadSlotsForDate(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _dateFormat.format(_selectedDate),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_isLookingForService) ...[
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _proposedTime,
                              );
                              if (picked == null) return;
                              setState(() => _proposedTime = picked);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Proposed time: ${_proposedTime.format(context)}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Text(
                              'For this request, send your proposed completion date/time and quote to the requester.',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Available Time Slots',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_loadingSlots)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_slots.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _slotsUnavailableReason ??
                                        'No slots available for selected date',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _slots.map((slot) {
                                final available = _slotAvailable(slot);
                                final selectedSlot = _selectedSlot;
                                final selected =
                                    selectedSlot != null &&
                                    _slotLabel(selectedSlot) ==
                                        _slotLabel(slot);
                                return InkWell(
                                  onTap: available
                                      ? () {
                                          setState(() {
                                            _selectedSlot = slot;
                                            final rawDuration =
                                                slot['slotDurationMinutes'];
                                            _duration = rawDuration is int
                                                ? rawDuration
                                                : int.tryParse(
                                                        rawDuration
                                                                ?.toString() ??
                                                            '',
                                                      ) ??
                                                      _duration;
                                          });
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.deepPurple
                                          : available
                                          ? Colors.grey[50]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? Colors.deepPurple
                                            : available
                                            ? Colors.grey[300]!
                                            : Colors.grey[200]!,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: Colors.deepPurple
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      _slotLabel(slot),
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : available
                                            ? Colors.black87
                                            : Colors.grey[500],
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                          if (_selectedSlot != null &&
                              !_slotAvailable(_selectedSlot!))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.red[700],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _slotReason(_selectedSlot!) ??
                                            'Not available',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 20),

                        // Location Input
                        TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.deepPurple,
                              ),
                            ),
                            labelText: 'Location',
                            prefixIcon: const Icon(Icons.location_on, size: 20),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Duration Dropdown
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<int>(
                            initialValue: _duration,
                            items: const [15, 30, 45, 60]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('$e minutes'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _duration = value);
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              labelText: 'Duration',
                              prefixIcon: const Icon(Icons.timer, size: 20),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_isLookingForService) ...[
                          TextField(
                            controller: _quoteController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.deepPurple,
                                ),
                              ),
                              labelText: 'Your Quote Price',
                              prefixIcon: const Icon(
                                Icons.currency_rupee,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Notes Input
                        TextField(
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.deepPurple,
                              ),
                            ),
                            labelText: 'Additional Notes',
                            prefixIcon: const Icon(Icons.note, size: 20),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: _buildBottomButton(canBook, canBookWithSelection),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isPrice = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isPrice ? FontWeight.w600 : FontWeight.normal,
              color: isPrice ? Colors.deepPurple : Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(bool canBook, bool canBookWithSelection) {
    if (!_loggedIn) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login),
              SizedBox(width: 8),
              Text(
                'Login to Book',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (_isOwner) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ServiceAvailabilityScreen(serviceId: widget.serviceId),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule),
                  SizedBox(width: 8),
                  Text(
                    'Manage Availability',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month),
                  SizedBox(width: 8),
                  Text(
                    'View Appointments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final bookingButton = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canBookWithSelection && !_booking ? _book : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _booking
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    !canBook
                        ? Icons.block
                        : !_isLookingForService && _selectedSlot == null
                        ? Icons.access_time
                        : _isLookingForService
                        ? Icons.send
                        : Icons.check_circle,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    !canBook
                        ? _invalidReason
                        : !_isLookingForService && _selectedSlot == null
                        ? 'Select a Time Slot'
                        : _isLookingForService
                        ? 'Send Proposal'
                        : 'Book Appointment',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );

    return bookingButton;
  }
}
