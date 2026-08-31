import 'package:yempover_app/services/service_booking_service.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServiceAvailabilityScreen extends StatefulWidget {
  final String serviceId;
  final bool isInitialSetup;
  final List<Map<String, dynamic>>? initialAvailabilitySlots;
  // When true, "Save" doesn't hit the network — it just pops with the
  // picked slots (List<Map<String, dynamic>>) so the caller can bundle them
  // into its own single create/update call instead of this screen saving
  // them separately.
  final bool pickerMode;

  const ServiceAvailabilityScreen({
    super.key,
    this.serviceId = '',
    this.isInitialSetup = false,
    this.initialAvailabilitySlots,
    this.pickerMode = false,
  });

  @override
  State<ServiceAvailabilityScreen> createState() =>
      _ServiceAvailabilityScreenState();
}

class _ServiceAvailabilityScreenState extends State<ServiceAvailabilityScreen> {
  final ServiceBookingService _service = ServiceBookingService();

  bool _savingAvailability = false;
  bool _loadingAvailability = false;
  bool _published = false;

  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    if (!widget.isInitialSetup) {
      _loadExistingAvailability();
    }
  }

  Future<bool> _handleWillPop() async {
    if (widget.pickerMode || !widget.isInitialSetup || _published) {
      return true;
    }

    SnackbarUtils.showInfo(
      context,
      'Please save availability to publish your service.',
    );
    return false;
  }

  final List<Map<String, dynamic>> _days = [
    _dayRow('MONDAY'),
    _dayRow('TUESDAY'),
    _dayRow('WEDNESDAY'),
    _dayRow('THURSDAY'),
    _dayRow('FRIDAY'),
    _dayRow('SATURDAY'),
    _dayRow('SUNDAY'),
  ];

  static Map<String, dynamic> _dayRow(String day) {
    return {
      'dayOfWeek': day,
      'isAvailable': false,
      'startTime': '09:00',
      'endTime': '17:00',
      'breakStartTime': '',
      'breakEndTime': '',
      'slotDurationMinutes': 30,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _normalizeTime(dynamic value, {String fallback = '09:00'}) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return fallback;

    if (raw.contains('T')) {
      try {
        final dt = DateTime.parse(raw);
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return fallback;
      }
    }

    final chunks = raw.split(':');
    if (chunks.length >= 2) {
      final hour = int.tryParse(chunks[0]) ?? 9;
      final minute = int.tryParse(chunks[1]) ?? 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return fallback;
  }

  String _optionalTime(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    return _normalizeTime(value);
  }

  void _applyAvailabilitySlots(List<Map<String, dynamic>> slots) {
    for (final slot in slots) {
      if (slot['isSpecialDate'] == true) continue;

      final dayName = slot['dayOfWeek']?.toString().trim().toUpperCase();
      if (dayName == null || dayName.isEmpty) continue;

      final index = _days.indexWhere((day) => day['dayOfWeek'] == dayName);
      if (index == -1) continue;

      _days[index] = {
        'dayOfWeek': dayName,
        'isAvailable': slot['isAvailable'] != false,
        'startTime': _normalizeTime(slot['startTime'], fallback: '09:00'),
        'endTime': _normalizeTime(slot['endTime'], fallback: '17:00'),
        'breakStartTime': _optionalTime(slot['breakStartTime']),
        'breakEndTime': _optionalTime(slot['breakEndTime']),
        'slotDurationMinutes':
            slot['slotDurationMinutes'] is int
            ? slot['slotDurationMinutes'] as int
            : int.tryParse(slot['slotDurationMinutes']?.toString() ?? '') ??
                  30,
      };
    }
  }

  Future<void> _loadExistingAvailability() async {
    final seeded = widget.initialAvailabilitySlots;
    if (seeded != null && seeded.isNotEmpty) {
      setState(() => _applyAvailabilitySlots(seeded));
      return;
    }

    setState(() => _loadingAvailability = true);

    try {
      final response = await _service.getServiceDetail(widget.serviceId);
      final data = response['data'];
      Map<String, dynamic> service = {};

      if (data is Map<String, dynamic>) {
        service = data['service'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['service'])
            : Map<String, dynamic>.from(data);
      }

      final raw = service['availabilitySlots'];
      if (raw is List && mounted) {
        final slots = raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        setState(() => _applyAvailabilitySlots(slots));
      }
    } catch (error) {
      if (mounted) {
        SnackbarUtils.showError(context, _service.extractMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAvailability = false);
      }
    }
  }

  Future<void> _pickTime(int index, String key) async {
    final initial = _days[index][key]?.toString() ?? '09:00';
    final chunks = initial.split(':');
    final hour = int.tryParse(chunks.first) ?? 9;
    final minute = int.tryParse(chunks.length > 1 ? chunks[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.deepPurple),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _days[index][key] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  String _formatTime(String timeString) {
    try {
      final chunks = timeString.split(':');
      final hour = int.parse(chunks[0]);
      final minute = int.parse(chunks[1]);
      final time = DateTime(2000, 1, 1, hour, minute);
      return _timeFormat.format(time);
    } catch (e) {
      return timeString;
    }
  }

  String? _validateDay(Map<String, dynamic> day) {
    if (day['isAvailable'] != true) return null;

    final start = day['startTime']?.toString() ?? '';
    final end = day['endTime']?.toString() ?? '';
    if (start.isEmpty || end.isEmpty) {
      return '${day['dayOfWeek']}: start/end required';
    }
    if (!_isAfter(end, start)) {
      return '${day['dayOfWeek']}: endTime must be after startTime';
    }

    final breakStart = day['breakStartTime']?.toString() ?? '';
    final breakEnd = day['breakEndTime']?.toString() ?? '';

    if (breakStart.isNotEmpty || breakEnd.isNotEmpty) {
      if (breakStart.isEmpty || breakEnd.isEmpty) {
        return '${day['dayOfWeek']}: both break times required';
      }
      if (!_isAfter(breakEnd, breakStart)) {
        return '${day['dayOfWeek']}: breakEndTime must be after breakStartTime';
      }
      if (_isAfter(start, breakStart) || _isAfter(breakEnd, end)) {
        return '${day['dayOfWeek']}: break must be within working hours';
      }
    }

    return null;
  }

  bool _isAfter(String left, String right) {
    final l = left.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    final r = right.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    return (l[0] * 60 + l[1]) > (r[0] * 60 + r[1]);
  }

  Future<void> _saveAvailability() async {
    for (final day in _days) {
      final error = _validateDay(day);
      if (error != null) {
        SnackbarUtils.showError(context, error);
        return;
      }
    }

    if (widget.pickerMode) {
      Navigator.pop(context, _days);
      return;
    }

    setState(() => _savingAvailability = true);

    try {
      await _service.setAvailability(
        serviceId: widget.serviceId,
        availabilitySlots: _days,
      );

      if (!mounted) return;
      setState(() => _published = widget.isInitialSetup);
      SnackbarUtils.showSuccess(context, 'Availability saved successfully');

      Future.microtask(() {
        if (!mounted) return;
        if (widget.isInitialSetup) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          Navigator.pop(context, true);
        }
      });
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(context, _service.extractMessage(error));
    } finally {
      if (mounted) {
        setState(() => _savingAvailability = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_published) {
      return _buildPublishedScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text(
            'Set Availability',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          automaticallyImplyLeading:
              widget.pickerMode || !widget.isInitialSetup || _published,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: _loadingAvailability
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly Schedule Header
              Container(
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
                    const Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Weekly Schedule',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set your regular weekly availability. One availability block per day is supported.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Days Cards
              ...List.generate(_days.length, (index) => _buildDayCard(index)),

              const SizedBox(height: 20),

              // Save Weekly Schedule Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savingAvailability ? null : _saveAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _savingAvailability
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Save Weekly Schedule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublishedScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Service Published',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Service Live!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Your service is published and ready for bookings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
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
                      Icon(Icons.home),
                      SizedBox(width: 8),
                      Text(
                        'Go to Home',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(int index) {
    final row = _days[index];
    final enabled = row['isAvailable'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.deepPurple.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getDayIcon(row['dayOfWeek']),
              color: enabled ? Colors.deepPurple : Colors.grey,
              size: 20,
            ),
          ),
          title: Text(
            _formatDayName(row['dayOfWeek']),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.black87 : Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: enabled
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_formatTime(row['startTime'])} - ${_formatTime(row['endTime'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : null,
          trailing: Switch(
            value: enabled,
            onChanged: (value) {
              setState(() => row['isAvailable'] = value);
            },
            activeThumbColor: Colors.deepPurple,
          ),
          children: enabled
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Working Hours
                        const Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Working Hours',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeField(
                                label: 'Start',
                                value: row['startTime'].toString(),
                                onTap: () => _pickTime(index, 'startTime'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimeField(
                                label: 'End',
                                value: row['endTime'].toString(),
                                onTap: () => _pickTime(index, 'endTime'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Break Time
                        const Row(
                          children: [
                            Icon(
                              Icons.free_breakfast,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Break Time (Optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTimeField(
                                label: 'Break Start',
                                value:
                                    (row['breakStartTime']
                                            ?.toString()
                                            .isEmpty ??
                                        true)
                                    ? 'Not set'
                                    : _formatTime(
                                        row['breakStartTime'].toString(),
                                      ),
                                onTap: () => _pickTime(index, 'breakStartTime'),
                                isOptional: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTimeField(
                                label: 'Break End',
                                value:
                                    (row['breakEndTime']?.toString().isEmpty ??
                                        true)
                                    ? 'Not set'
                                    : _formatTime(
                                        row['breakEndTime'].toString(),
                                      ),
                                onTap: () => _pickTime(index, 'breakEndTime'),
                                isOptional: true,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Slot Duration
                        const Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 18,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Appointment Duration',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<int>(
                            initialValue: row['slotDurationMinutes'] as int,
                            items: const [15, 30, 45, 60]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text('$value minutes'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(
                                () => row['slotDurationMinutes'] = value,
                              );
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isOptional && value == 'Not set'
                        ? FontWeight.normal
                        : FontWeight.w600,
                    color: isOptional && value == 'Not set'
                        ? Colors.grey
                        : Colors.black87,
                  ),
                ),
                Icon(Icons.edit, size: 16, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDayIcon(String day) {
    switch (day) {
      case 'MONDAY':
        return Icons.calendar_view_day;
      case 'TUESDAY':
        return Icons.calendar_view_day;
      case 'WEDNESDAY':
        return Icons.calendar_view_day;
      case 'THURSDAY':
        return Icons.calendar_view_day;
      case 'FRIDAY':
        return Icons.calendar_view_day;
      case 'SATURDAY':
        return Icons.calendar_view_week;
      case 'SUNDAY':
        return Icons.calendar_view_month;
      default:
        return Icons.calendar_today;
    }
  }

  String _formatDayName(String day) {
    return day.substring(0, 1) + day.substring(1).toLowerCase();
  }
}
