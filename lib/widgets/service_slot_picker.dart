import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/services/service_booking_service.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';

enum _SlotPeriod { morning, afternoon, evening }

class SelectedServiceSlot {
  final DateTime dateTime;
  final int durationMinutes;

  const SelectedServiceSlot({
    required this.dateTime,
    required this.durationMinutes,
  });
}

// The same "pick a date, pick a time slot" section used by the Pure Coins
// (scheduled) service booking flow — reused here so a Barter / Barter+Coins
// offer on a service also books a real slot, instead of only Pure Coins
// deals reserving the provider's calendar.
class ServiceSlotPicker extends StatefulWidget {
  final String serviceId;
  final ValueChanged<SelectedServiceSlot?> onChanged;

  const ServiceSlotPicker({
    super.key,
    required this.serviceId,
    required this.onChanged,
  });

  @override
  State<ServiceSlotPicker> createState() => _ServiceSlotPickerState();
}

class _ServiceSlotPickerState extends State<ServiceSlotPicker> {
  final ServiceBookingService _service = ServiceBookingService();
  final DateFormat _dateFormat = DateFormat('EEEE, MMMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  bool _loadingService = true;
  bool _loadingSlots = false;
  String? _loadError;
  Map<String, dynamic>? _serviceData;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _proposedTime = const TimeOfDay(hour: 10, minute: 0);
  List<Map<String, dynamic>> _slots = [];
  String? _slotsUnavailableReason;
  Map<String, dynamic>? _selectedSlot;
  _SlotPeriod _selectedSlotPeriod = _SlotPeriod.afternoon;
  int _duration = 30;
  bool _showDurationOptions = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loadingService = true;
      _loadError = null;
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

      final initialDate = _resolveInitialBookingDate(parsed);
      if (!mounted) return;
      setState(() {
        _serviceData = parsed;
        _selectedDate = initialDate;
        _loadingService = false;
      });

      if (!_isLookingForService) {
        await _loadSlotsForDate(_selectedDate);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _service.extractMessage(error);
        _loadingService = false;
      });
    }
  }

  bool get _isLookingForService =>
      _serviceData?['status']?.toString() == 'LOOKING_FOR_SERVICE';

  DateTime? get _serviceValidUntil {
    final raw = _serviceData?['validUntil']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

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

  Set<int> _availableWeekdays() {
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
      if (weekdays.contains(cursor.weekday)) return cursor;
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

    final weekdays = <int>{};
    final raw = service['availabilitySlots'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final slot = Map<String, dynamic>.from(item);
        if (slot['isAvailable'] == false) continue;
        final weekday = _weekdayFromString(slot['dayOfWeek']?.toString());
        if (weekday != null) weekdays.add(weekday);
      }
    }

    final next = _nextAvailableDate(from: now, to: upperBound, weekdays: weekdays);
    return next ?? now;
  }

  bool _isSelectableBookingDate(DateTime day, DateTime first, DateTime last) {
    final target = _dateOnly(day);
    final firstDate = _dateOnly(first);
    final lastDate = _dateOnly(last);
    if (target.isBefore(firstDate) || target.isAfter(lastDate)) return false;

    final weekdays = _availableWeekdays();
    if (weekdays.isEmpty) return true;
    return weekdays.contains(target.weekday);
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() {
      _loadingSlots = true;
      _selectedDate = DateTime(date.year, date.month, date.day);
      _selectedSlot = null;
    });
    widget.onChanged(null);

    try {
      final response = await _service.getAvailableSlots(
        serviceId: widget.serviceId,
        date: _service.dateOnly(_selectedDate),
        duration: _duration,
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
          unavailableReason = data['reason']?.toString() ??
              data['message']?.toString() ??
              'No slots available on this date';
        }
      } else if (data is List) {
        slots = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (data is Map<String, dynamic>) {
        if (data['available'] == false) {
          unavailableReason = data['reason']?.toString() ??
              data['message']?.toString() ??
              'No slots available on this date';
        }
        for (final source in [data['slots'], data['availableSlots'], data['items']]) {
          if (source is List) {
            slots = source.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            break;
          }
        }
      }

      final now = DateTime.now();
      final isToday = now.year == _selectedDate.year &&
          now.month == _selectedDate.month &&
          now.day == _selectedDate.day;
      if (isToday) {
        final hadSlotsBeforeNowFilter = slots.isNotEmpty;
        slots = slots.where((slot) {
          final start = _slotDateTime(slot);
          return start == null || start.isAfter(now);
        }).toList();
        if (slots.isEmpty && hadSlotsBeforeNowFilter) {
          unavailableReason = 'No remaining slots for today. Please select another date.';
        }
      }

      if (!mounted) return;
      setState(() {
        _slots = slots;
        _slotsUnavailableReason = unavailableReason;
        _loadingSlots = false;
        _selectedSlotPeriod = _defaultSlotPeriod(slots);
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

  DateTime? _slotDateTime(Map<String, dynamic> slot) {
    final dateTimeCandidates = [
      slot['startDateTime'],
      slot['appointmentDate'],
      slot['dateTime'],
      slot['slotDateTime'],
    ];
    for (final raw in dateTimeCandidates) {
      if (raw == null) continue;
      final match = RegExp(r'T(\d{2}):(\d{2})').firstMatch(raw.toString());
      if (match == null) continue;
      final hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      if (hour == null || minute == null) continue;
      return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
    }
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

  _SlotPeriod _periodForSlot(Map<String, dynamic> slot) {
    final dt = _slotDateTime(slot);
    final hour = dt?.hour ?? 12;
    if (hour < 12) return _SlotPeriod.morning;
    if (hour < 17) return _SlotPeriod.afternoon;
    return _SlotPeriod.evening;
  }

  _SlotPeriod _defaultSlotPeriod(List<Map<String, dynamic>> slots) {
    int count(_SlotPeriod p) =>
        slots.where((s) => _slotAvailable(s) && _periodForSlot(s) == p).length;
    if (count(_SlotPeriod.afternoon) > 0) return _SlotPeriod.afternoon;
    if (count(_SlotPeriod.morning) > 0) return _SlotPeriod.morning;
    if (count(_SlotPeriod.evening) > 0) return _SlotPeriod.evening;
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

  List<Map<String, dynamic>> _slotsForPeriod(_SlotPeriod p) =>
      _slots.where((s) => _periodForSlot(s) == p).toList();

  void _selectSlot(Map<String, dynamic> slot) {
    final dt = _slotDateTime(slot);
    if (dt == null) return;
    final rawDuration = slot['slotDurationMinutes'];
    final duration = rawDuration is int
        ? rawDuration
        : int.tryParse(rawDuration?.toString() ?? '') ?? _duration;
    setState(() {
      _selectedSlot = slot;
      _duration = duration;
    });
    widget.onChanged(SelectedServiceSlot(dateTime: dt, durationMinutes: duration));
  }

  void _emitLookingForServiceSelection() {
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _proposedTime.hour,
      _proposedTime.minute,
    );
    widget.onChanged(SelectedServiceSlot(dateTime: dateTime, durationMinutes: _duration));
  }

  Widget _buildPeriodTab(_SlotPeriod period, int count, bool selected) {
    final enabled = count > 0;
    final fg = selected ? const Color(0xFF2E5BFF) : const Color(0xFF374151);
    return Expanded(
      child: InkWell(
        onTap: enabled
            ? () => setState(() {
                  _selectedSlotPeriod = period;
                  if (_selectedSlot != null && _periodForSlot(_selectedSlot!) != period) {
                    _selectedSlot = null;
                    widget.onChanged(null);
                  }
                })
            : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF1FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF2E5BFF) : const Color(0xFFE5E7EB),
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
    final selected = selectedSlot != null && _slotLabel(selectedSlot) == _slotLabel(slot);

    final bg = selected
        ? const Color(0xFF2E5BFF)
        : available
            ? Colors.white
            : const Color(0xFFF3F4F6);
    final borderColor = selected ? const Color(0xFF2E5BFF) : const Color(0xFFE5E7EB);
    final fg = selected
        ? Colors.white
        : available
            ? const Color(0xFF111827)
            : const Color(0xFF9CA3AF);

    return InkWell(
      onTap: available ? () => _selectSlot(slot) : null,
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
          _slotLabel(slot),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }

  Widget _buildSlotGrid() {
    final morningCount = _slotsForPeriod(_SlotPeriod.morning).where(_slotAvailable).length;
    final afternoonCount = _slotsForPeriod(_SlotPeriod.afternoon).where(_slotAvailable).length;
    final eveningCount = _slotsForPeriod(_SlotPeriod.evening).where(_slotAvailable).length;

    final periodSlots = _slotsForPeriod(_selectedSlotPeriod).toList()
      ..sort((a, b) {
        final ad = _slotDateTime(a);
        final bd = _slotDateTime(b);
        if (ad == null || bd == null) return 0;
        return ad.compareTo(bd);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildPeriodTab(_SlotPeriod.morning, morningCount, _selectedSlotPeriod == _SlotPeriod.morning),
            const SizedBox(width: 10),
            _buildPeriodTab(_SlotPeriod.afternoon, afternoonCount, _selectedSlotPeriod == _SlotPeriod.afternoon),
            const SizedBox(width: 10),
            _buildPeriodTab(_SlotPeriod.evening, eveningCount, _selectedSlotPeriod == _SlotPeriod.evening),
          ],
        ),
        const SizedBox(height: 12),
        if (periodSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No slots in this period',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
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

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _showDurationOptions = !_showDurationOptions),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showDurationOptions ? const Color(0xFF2E5BFF) : Colors.grey.shade400,
                width: _showDurationOptions ? 1.6 : 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, size: 20, color: Colors.grey[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 2),
                      Text('$_duration minutes', style: const TextStyle(fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                ),
                Icon(_showDurationOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600]),
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
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [15, 30, 45, 60].map((value) {
                final isSelected = _duration == value;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _duration = value;
                      _showDurationOptions = false;
                    });
                    if (!_isLookingForService) {
                      _loadSlotsForDate(_selectedDate);
                    } else {
                      _emitLookingForServiceSelection();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    color: isSelected ? const Color(0xFF2E5BFF).withValues(alpha: 0.08) : Colors.transparent,
                    child: Text(
                      '$value minutes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF2E5BFF) : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingService) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(_loadError!, style: TextStyle(color: Colors.red.shade700)),
      );
    }

    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final validUntil = _serviceValidUntil;
    final upperBound = validUntil != null && validUntil.isAfter(now)
        ? DateTime(validUntil.year, validUntil.month, validUntil.day)
        : DateTime(now.year + 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF2E5BFF)),
            SizedBox(width: 10),
            Text('Pick a time slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final initialDate = _isLookingForService
                ? _selectedDate
                : (_isSelectableBookingDate(_selectedDate, firstDate, upperBound)
                    ? _selectedDate
                    : (_nextAvailableDate(
                            from: firstDate,
                            to: upperBound,
                            weekdays: _availableWeekdays(),
                          ) ??
                          firstDate));

            final picked = await showDatePicker(
              context: context,
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: upperBound,
              selectableDayPredicate: (day) {
                if (_isLookingForService) return true;
                return _isSelectableBookingDate(day, firstDate, upperBound);
              },
            );
            if (picked == null) return;
            if (_isLookingForService) {
              setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
              _emitLookingForServiceSelection();
            } else {
              _loadSlotsForDate(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_dateFormat.format(_selectedDate), style: const TextStyle(fontSize: 15)),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLookingForService) ...[
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _proposedTime);
              if (picked == null) return;
              setState(() => _proposedTime = picked);
              _emitLookingForServiceSelection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 1.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Proposed time: ${_proposedTime.format(context)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_slots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 32, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    _slotsUnavailableReason ?? 'No slots available for selected date',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            _buildSlotGrid(),
          const SizedBox(height: 16),
        ],
        _buildDurationSelector(),
      ],
    );
  }
}
