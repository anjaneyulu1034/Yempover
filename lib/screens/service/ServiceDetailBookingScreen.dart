import 'package:yempover_app/screens/service/ServiceAvailabilityScreen.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/services/service_booking_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:yempover_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/widgets/app_text_field.dart';

enum ServiceDetailUiState { loadingService, serviceReady, serviceError }

enum _SlotPeriod { morning, afternoon, evening }

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
  final TradeChatService _tradeChatService = TradeChatService();
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
  _SlotPeriod _selectedSlotPeriod = _SlotPeriod.afternoon;

  int _duration = 30;
  bool _showDurationOptions = false;
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
    _tradeChatService.dispose();
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

      final initialBookingDate = _resolveInitialBookingDate(parsed);

      if (!mounted) return;
      setState(() {
        _serviceData = parsed;
        _selectedDate = initialBookingDate;
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

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int? _weekdayFromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = value.trim().toUpperCase();
    if (normalized.startsWith('MON')) return DateTime.monday;
    if (normalized.startsWith('TUE')) return DateTime.tuesday;
    if (normalized.startsWith('WED')) return DateTime.wednesday;
    if (normalized.startsWith('THU')) return DateTime.thursday;
    if (normalized.startsWith('FRI')) return DateTime.friday;
    if (normalized.startsWith('SAT')) return DateTime.saturday;
    if (normalized.startsWith('SUN')) return DateTime.sunday;
    return null;
  }

  Set<int> _availableWeekdays([Map<String, dynamic>? service]) {
    final source = service ?? _serviceData;
    if (source == null) return const {};

    final raw = source['availabilitySlots'];
    if (raw is! List) return const {};

    final weekdays = <int>{};
    for (final item in raw) {
      if (item is! Map) continue;

      final slot = Map<String, dynamic>.from(item);
      if (slot['isAvailable'] == false) continue;

      final weekday = _weekdayFromString(slot['dayOfWeek']?.toString());
      if (weekday != null) {
        weekdays.add(weekday);
      }
    }

    return weekdays;
  }

  DateTime? _nextAvailableDate({
    required DateTime from,
    required DateTime to,
    required Set<int> weekdays,
  }) {
    final start = _dateOnly(from);
    final end = _dateOnly(to);
    if (start.isAfter(end)) return null;

    if (weekdays.isEmpty) return start;

    var cursor = start;
    while (!cursor.isAfter(end)) {
      if (weekdays.contains(cursor.weekday)) {
        return cursor;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return null;
  }

  DateTime _resolveInitialBookingDate(Map<String, dynamic> service) {
    final now = _dateOnly(DateTime.now());

    final rawValidUntil = service['validUntil']?.toString();
    final parsedValidUntil = rawValidUntil == null || rawValidUntil.isEmpty
        ? null
        : DateTime.tryParse(rawValidUntil)?.toLocal();

    final upperBound =
        parsedValidUntil != null && _dateOnly(parsedValidUntil).isAfter(now)
        ? _dateOnly(parsedValidUntil)
        : DateTime(now.year + 3, now.month, now.day);

    final next = _nextAvailableDate(
      from: now,
      to: upperBound,
      weekdays: _availableWeekdays(service),
    );

    return next ?? now;
  }

  bool _isSelectableBookingDate(DateTime day, DateTime first, DateTime last) {
    final target = _dateOnly(day);
    final firstDate = _dateOnly(first);
    final lastDate = _dateOnly(last);

    if (target.isBefore(firstDate) || target.isAfter(lastDate)) {
      return false;
    }

    final weekdays = _availableWeekdays();
    if (weekdays.isEmpty) return true;

    return weekdays.contains(target.weekday);
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
        _selectedSlotPeriod = _defaultSlotPeriod(slots);
        if (_selectedSlot != null &&
            _periodForSlot(_selectedSlot!) != _selectedSlotPeriod) {
          _selectedSlot = null;
        }
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

  String? get _serviceOwnerId {
    final service = _serviceData;
    if (service == null) return null;

    final directPostedBy = service['postedById']?.toString();
    if (directPostedBy != null && directPostedBy.isNotEmpty) {
      return directPostedBy;
    }

    final directUserId = service['userId']?.toString();
    if (directUserId != null && directUserId.isNotEmpty) {
      return directUserId;
    }

    final provider = service['provider'];
    if (provider is Map) {
      final providerId = provider['id']?.toString();
      if (providerId != null && providerId.isNotEmpty) {
        return providerId;
      }
    }

    return null;
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

  _SlotPeriod _periodForSlot(Map<String, dynamic> slot) {
    final dt = _slotDateTime(slot);
    final hour = dt?.hour ??
        _service.parseTimeOfDay(
              _selectedDate,
              slot['startTime']?.toString() ?? slot['time']?.toString(),
            )?.hour ??
        12;
    if (hour < 12) return _SlotPeriod.morning;
    if (hour < 17) return _SlotPeriod.afternoon;
    return _SlotPeriod.evening;
  }

  _SlotPeriod _defaultSlotPeriod(List<Map<String, dynamic>> slots) {
    int count(_SlotPeriod p) =>
        slots.where((s) => _slotAvailable(s) && _periodForSlot(s) == p).length;

    final morning = count(_SlotPeriod.morning);
    final afternoon = count(_SlotPeriod.afternoon);
    final evening = count(_SlotPeriod.evening);

    if (afternoon > 0) return _SlotPeriod.afternoon;
    if (morning > 0) return _SlotPeriod.morning;
    if (evening > 0) return _SlotPeriod.evening;
    return _SlotPeriod.afternoon;
  }

  String _periodTitle(_SlotPeriod p) {
    switch (p) {
      case _SlotPeriod.morning:
        return 'Morning';
      case _SlotPeriod.afternoon:
        return 'Afternoon';
      case _SlotPeriod.evening:
        return 'Evening';
    }
  }

  List<Map<String, dynamic>> _slotsForPeriod(_SlotPeriod p) {
    return _slots.where((s) => _periodForSlot(s) == p).toList();
  }

  String _periodRangeLabel(_SlotPeriod p) {
    final items = _slotsForPeriod(p).where(_slotAvailable).toList()
      ..sort((a, b) {
        final ad = _slotDateTime(a);
        final bd = _slotDateTime(b);
        if (ad == null || bd == null) return 0;
        return ad.compareTo(bd);
      });

    if (items.isEmpty) return '';
    final first = _slotDateTime(items.first);
    final last = _slotDateTime(items.last);
    if (first == null || last == null) return '';
    return '${_timeFormat.format(first)} – ${_timeFormat.format(last)}';
  }

  Widget _buildPeriodTab(_SlotPeriod period, int count, bool selected) {
    final enabled = count > 0;
    final fg = selected ? const Color(0xFF2E5BFF) : const Color(0xFF374151);

    return Expanded(
      child: InkWell(
        onTap: enabled
            ? () {
                setState(() {
                  _selectedSlotPeriod = period;
                  if (_selectedSlot != null &&
                      _periodForSlot(_selectedSlot!) != period) {
                    _selectedSlot = null;
                  }
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF1FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2E5BFF)
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.8 : 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _periodTitle(period),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: enabled ? fg : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count slots',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled ? fg : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(Map<String, dynamic> slot) {
    final available = _slotAvailable(slot);
    final selectedSlot = _selectedSlot;
    final selected =
        selectedSlot != null && _slotLabel(selectedSlot) == _slotLabel(slot);

    final bg = selected
        ? const Color(0xFF2E5BFF)
        : available
            ? Colors.white
            : const Color(0xFFF3F4F6);
    final borderColor = selected
        ? const Color(0xFF2E5BFF)
        : const Color(0xFFE5E7EB);
    final fg = selected
        ? Colors.white
        : available
            ? const Color(0xFF111827)
            : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: available
          ? () {
              setState(() {
                _selectedSlot = slot;
                final rawDuration = slot['slotDurationMinutes'];
                _duration = rawDuration is int
                    ? rawDuration
                    : int.tryParse(rawDuration?.toString() ?? '') ?? _duration;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: selected ? 1.8 : 1.2),
        ),
        child: Text(
          _slotLabel(slot).replaceAll(RegExp(r'\s?[–-]\s?.*$'), ''),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }

  Widget _buildSlotPicker() {
    final morningCount =
        _slotsForPeriod(_SlotPeriod.morning).where(_slotAvailable).length;
    final afternoonCount =
        _slotsForPeriod(_SlotPeriod.afternoon).where(_slotAvailable).length;
    final eveningCount =
        _slotsForPeriod(_SlotPeriod.evening).where(_slotAvailable).length;

    final periodSlots = _slotsForPeriod(_selectedSlotPeriod)
        .where(_slotAvailable)
        .toList()
      ..sort((a, b) {
        final ad = _slotDateTime(a);
        final bd = _slotDateTime(b);
        if (ad == null || bd == null) return 0;
        return ad.compareTo(bd);
      });

    final rangeText = _periodRangeLabel(_selectedSlotPeriod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF2E5BFF)),
            SizedBox(width: 10),
            Text(
              'Pick a time slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildPeriodTab(
              _SlotPeriod.morning,
              morningCount,
              _selectedSlotPeriod == _SlotPeriod.morning,
            ),
            const SizedBox(width: 10),
            _buildPeriodTab(
              _SlotPeriod.afternoon,
              afternoonCount,
              _selectedSlotPeriod == _SlotPeriod.afternoon,
            ),
            const SizedBox(width: 10),
            _buildPeriodTab(
              _SlotPeriod.evening,
              eveningCount,
              _selectedSlotPeriod == _SlotPeriod.evening,
            ),
          ],
        ),
        if (rangeText.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '${_periodTitle(_selectedSlotPeriod)} : $rangeText',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: periodSlots.map(_buildSlotChip).toList(),
        ),
      ],
    );
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
      final quoteText = _quoteController.text.trim();
      final quote = double.tryParse(quoteText);
      if (quote == null || quote <= 0) {
        SnackbarUtils.showError(context, 'Please enter your quote price');
        return;
      }
      if (quoteText.length > Validators.maxAmountLength) {
        SnackbarUtils.showError(context, 'Quote price is too large');
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

      final displayDate = DateFormat(
        'dd MMM yyyy, h:mm a',
      ).format(dateTime.toLocal());

      final responderId = _serviceOwnerId;
      if (responderId == null || responderId.isEmpty) {
        throw Exception('Unable to find service owner for chat initiation.');
      }

      final currentUserId = _currentUserId;
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('Unable to identify current user. Please login again.');
      }

      final chat = await _tradeChatService.initiateChat(
        responderId: responderId,
        serviceId: widget.serviceId,
      );

      final quotedPrice = _isLookingForService
          ? double.tryParse(_quoteController.text.trim())
          : double.tryParse((_serviceData?['price'] ?? '').toString());

      if (quotedPrice != null && quotedPrice > 0) {
        await _tradeChatService.createPriceOffer(
          chatId: chat.id,
          price: quotedPrice,
          currency: 'INR',
        );
      } else {
        await _tradeChatService.createBarterOffer(
          chatId: chat.id,
          barterItemTitle: 'Service Proposal',
          barterItemDescription: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : 'Service proposal for ${_serviceData?['title'] ?? 'service'}',
        );
      }

      final details = <String>[
        'Service proposal submitted',
        'Date/Time: $displayDate',
        'Duration: $duration minutes',
      ];

      final location = _locationController.text.trim();
      if (location.isNotEmpty) {
        details.add('Location: $location');
      }

      final notes = _notesController.text.trim();
      if (notes.isNotEmpty) {
        details.add('Notes: $notes');
      }

      await _tradeChatService.sendMessage(
        chatId: chat.id,
        messageText: details.join('\n'),
      );

      final latestChat = await _tradeChatService.getChatById(chat.id);

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chat: latestChat,
            currentUserId: currentUserId,
            onChatUpdated: (_) {},
          ),
        ),
      );
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isValid ? Icons.check_circle : Icons.warning,
                                size: 16,
                                color: _isValid
                                    ? Colors.green[300]
                                    : Colors.orange[300],
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isValid ? 'Available' : _invalidReason,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
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
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.2,
                      ),
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
                        _buildCoinPriceRow(
                          'Price',
                          '${service['price'] ?? '-'}',
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
                            final firstDate = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final validUntil = _serviceValidUntil;
                            final upperBound =
                                validUntil != null && validUntil.isAfter(now)
                                ? DateTime(
                                    validUntil.year,
                                    validUntil.month,
                                    validUntil.day,
                                  )
                                : DateTime(now.year + 3);

                            final initialDate = _isLookingForService
                                ? _selectedDate
                                : (_isSelectableBookingDate(
                                        _selectedDate,
                                        firstDate,
                                        upperBound,
                                      )
                                      ? _selectedDate
                                      : (_nextAvailableDate(
                                              from: firstDate,
                                              to: upperBound,
                                              weekdays: _availableWeekdays(),
                                            ) ??
                                            firstDate));

                            final picked = await showDatePicker(
                              context: context,
                              initialEntryMode:
                                  DatePickerEntryMode.calendarOnly,
                              initialDate: initialDate,
                              firstDate: firstDate,
                              lastDate: upperBound,
                              selectableDayPredicate: (day) {
                                if (_isLookingForService) return true;
                                return _isSelectableBookingDate(
                                  day,
                                  firstDate,
                                  upperBound,
                                );
                              },
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
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1.2,
                              ),
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
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 1.2,
                                ),
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
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.2,
                                ),
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
                            _buildSlotPicker(),

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
                          decoration: AppInputDecoration.build(
                            label: 'Location',
                            prefixIcon: const Icon(Icons.location_on, size: 20),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Duration dropdown rendered inline so it always opens below.
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _showDurationOptions = !_showDurationOptions;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _showDurationOptions
                                        ? Colors.deepPurple
                                        : Colors.grey.shade400,
                                    width: _showDurationOptions ? 1.6 : 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 20,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Duration',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$_duration minutes',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _showDurationOptions
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_showDurationOptions) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.14),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: List.generate(4, (index) {
                                    final options = [15, 30, 45, 60];
                                    final value = options[index];
                                    final isSelected = _duration == value;
                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _duration = value;
                                              _showDurationOptions = false;
                                            });
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.deepPurple.withValues(
                                                      alpha: 0.08,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '$value minutes',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.w500,
                                                      color: isSelected
                                                          ? Colors.deepPurple
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.check,
                                                    color: Colors.deepPurple,
                                                    size: 18,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (index != options.length - 1)
                                          Divider(
                                            height: 1,
                                            color: Colors.grey.shade200,
                                          ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (_isLookingForService) ...[
                          TextField(
                            controller: _quoteController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters:
                                Validators.amountInputFormatters(),
                            decoration: AppInputDecoration.build(
                              label: 'Your Quote Price',
                              prefixIcon: coinInputPrefix(),
                              prefixIconConstraints: coinPrefixIconConstraints,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Notes Input
                        TextField(
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: AppInputDecoration.build(
                            label: 'Additional Notes',
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

  Widget _buildCoinPriceRow(String label, String value) {
    final display = value == '-' ? value : '$value coins';
    return Row(
      children: [
        const CoinIcon(size: 20, iconSize: 12),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            display,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
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
      final weeklySlots = _serviceData?['availabilitySlots'] is List
          ? (_serviceData!['availabilitySlots'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () async {
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceAvailabilityScreen(
                  serviceId: widget.serviceId,
                  initialAvailabilitySlots: weeklySlots,
                ),
              ),
            );
            if (saved == true && mounted) {
              await _loadService();
              if (!_isLookingForService) {
                await _loadSlotsForDate(_selectedDate);
              }
            }
          },
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
      );
    }

    final bookingButton = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canBookWithSelection && !_booking ? _book : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E5BFF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFF5F3EE),
          disabledForegroundColor: const Color(0xFF6B7280),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
                  Flexible(
                    child: Text(
                      !canBook
                          ? _invalidReason
                          : !_isLookingForService && _selectedSlot == null
                          ? 'Select a time slot'
                          : _isLookingForService
                          ? 'Send Proposal'
                          : 'Book Appointment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );

    return bookingButton;
  }
}
