import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/services/service_booking_service.dart';

// Read-only "what slots does this provider have open" preview for the
// service details screen — lets a prospective buyer see availability before
// deciding whether to make an offer at all. Purely informational: slots
// aren't tappable and nothing here selects or books anything — that still
// only happens later, inside the actual offer flow (ServiceSlotPicker).
//
// Only ever lands on / lets you browse to a day the provider's weekly
// schedule actually has open — closed weekdays are skipped over rather than
// shown as an empty "no slots" day, and an arrow disables itself once
// there's no further open day left in that direction.
class ServiceSlotsPreview extends StatefulWidget {
  final String serviceId;

  const ServiceSlotsPreview({super.key, required this.serviceId});

  @override
  State<ServiceSlotsPreview> createState() => _ServiceSlotsPreviewState();
}

class _ServiceSlotsPreviewState extends State<ServiceSlotsPreview> {
  final ServiceBookingService _service = ServiceBookingService();
  final DateFormat _dateFormat = DateFormat('EEE, MMM d');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  bool _loadingService = true;
  bool _loadingSlots = false;
  String? _error;

  Map<String, dynamic>? _serviceData;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  String? _unavailableReason;

  @override
  void initState() {
    super.initState();
    _init();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

  Set<int> get _availableWeekdays {
    final raw = _serviceData?['availabilitySlots'];
    if (raw is! List) return const {};

    final weekdays = <int>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final slot = Map<String, dynamic>.from(item);
      if (slot['isAvailable'] == false) continue;
      final weekday = _weekdayFromString(slot['dayOfWeek']?.toString());
      if (weekday != null) weekdays.add(weekday);
    }
    return weekdays;
  }

  DateTime get _upperBound {
    final now = DateTime.now();
    final raw = _serviceData?['validUntil']?.toString();
    final parsed = raw == null || raw.isEmpty
        ? null
        : DateTime.tryParse(raw)?.toLocal();
    return parsed != null && _dateOnly(parsed).isAfter(_dateOnly(now))
        ? _dateOnly(parsed)
        : DateTime(now.year + 3, now.month, now.day);
  }

  bool _isOpenDay(DateTime day) {
    final weekdays = _availableWeekdays;
    if (weekdays.isEmpty) return true;
    return weekdays.contains(day.weekday);
  }

  // Next (forwards) / previous (backwards) day the provider is actually
  // open on, staying within [today, validUntil]. Null when there is none.
  DateTime? _nextOpenDay(DateTime from, {required bool forward}) {
    final today = _dateOnly(DateTime.now());
    final bound = _upperBound;
    var cursor = _dateOnly(from);

    for (var i = 0; i < 366 * 3; i++) {
      cursor = forward
          ? cursor.add(const Duration(days: 1))
          : cursor.subtract(const Duration(days: 1));
      if (forward && cursor.isAfter(bound)) return null;
      if (!forward && cursor.isBefore(today)) return null;
      if (_isOpenDay(cursor)) return cursor;
    }
    return null;
  }

  Future<void> _init() async {
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
      });

      final today = _dateOnly(DateTime.now());
      final initialDate = _isOpenDay(today)
          ? today
          : (_nextOpenDay(today, forward: true) ?? today);
      await _loadSlotsForDate(initialDate);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingService = false;
        _error = _service.extractMessage(error);
      });
    }
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() {
      _loadingSlots = true;
      _selectedDate = _dateOnly(date);
    });

    try {
      final response = await _service.getAvailableSlots(
        serviceId: widget.serviceId,
        date: _service.dateOnly(_selectedDate),
      );
      final data = response['data'];
      List<Map<String, dynamic>> slots = [];
      String? unavailableReason;

      if (data is Map<String, dynamic> && data['slotDetails'] is List) {
        slots = (data['slotDetails'] as List).whereType<Map>().map((e) {
          final slot = Map<String, dynamic>.from(e);
          slot['startTime'] ??= slot['time'];
          slot['available'] ??= slot['isBookable'];
          return slot;
        }).toList();
        if (data['available'] == false) {
          unavailableReason =
              data['reason']?.toString() ??
              data['message']?.toString() ??
              'No slots available on this date';
        }
      } else if (data is List) {
        slots = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (data is Map<String, dynamic>) {
        if (data['available'] == false) {
          unavailableReason =
              data['reason']?.toString() ??
              data['message']?.toString() ??
              'No slots available on this date';
        }
        for (final source in [
          data['slots'],
          data['availableSlots'],
          data['items'],
        ]) {
          if (source is List) {
            slots = source
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            break;
          }
        }
      }

      // Only ever show slots that are actually bookable — an unavailable
      // (already-taken) slot has nothing useful to tell a prospective buyer
      // browsing this read-only preview.
      slots = slots.where(_slotAvailable).toList();

      if (!mounted) return;
      setState(() {
        _slots = slots;
        _unavailableReason = unavailableReason;
        _loadingSlots = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSlots = false;
        _slots = [];
        _unavailableReason = _service.extractMessage(error);
      });
    }
  }

  DateTime? _slotDateTime(Map<String, dynamic> slot) {
    final time = slot['startTime']?.toString() ?? slot['time']?.toString();
    return _service.parseTimeOfDay(_selectedDate, time);
  }

  String _slotLabel(Map<String, dynamic> slot) {
    final dt = _slotDateTime(slot);
    if (dt != null) return _timeFormat.format(dt);
    return slot['startTime']?.toString() ?? slot['time']?.toString() ?? 'Slot';
  }

  bool _slotAvailable(Map<String, dynamic> slot) {
    final available = slot['available'];
    if (available is bool) return available;
    return slot['isAvailable'] != false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingService) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Text(_error!, style: TextStyle(color: Colors.red.shade700));
    }

    final isToday = _dateOnly(DateTime.now()) == _selectedDate;
    final previousOpenDay = _nextOpenDay(_selectedDate, forward: false);
    final nextOpenDay = _nextOpenDay(_selectedDate, forward: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF2E5BFF), size: 20),
            SizedBox(width: 8),
            Text(
              'Available Slots',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: (!isToday && previousOpenDay != null)
                  ? () => _loadSlotsForDate(previousOpenDay)
                  : null,
              icon: const Icon(Icons.chevron_left),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Center(
                child: Text(
                  isToday ? 'Today' : _dateFormat.format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            IconButton(
              onPressed: nextOpenDay != null
                  ? () => _loadSlotsForDate(nextOpenDay)
                  : null,
              icon: const Icon(Icons.chevron_right),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingSlots)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_slots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _unavailableReason ?? 'No slots available on this date',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots.map((slot) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E5BFF)),
                ),
                child: Text(
                  _slotLabel(slot),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E5BFF),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
