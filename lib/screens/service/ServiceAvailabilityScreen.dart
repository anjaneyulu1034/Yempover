import 'package:Yempover_app/screens/service/AppointmentsDashboardScreen.dart';
import 'package:Yempover_app/services/service_booking_service.dart';
import 'package:flutter/material.dart';

class ServiceAvailabilityScreen extends StatefulWidget {
  final String serviceId;
  final bool isInitialSetup;

  const ServiceAvailabilityScreen({
    super.key,
    required this.serviceId,
    this.isInitialSetup = false,
  });

  @override
  State<ServiceAvailabilityScreen> createState() =>
      _ServiceAvailabilityScreenState();
}

class _ServiceAvailabilityScreenState extends State<ServiceAvailabilityScreen> {
  final ServiceBookingService _service = ServiceBookingService();
  final TextEditingController _specialReasonController =
      TextEditingController();

  bool _savingAvailability = false;
  bool _savingSpecialDate = false;
  bool _published = false;
  DateTime? _specialDate;
  bool _specialIsAvailable = false;

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
    _specialReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(int index, String key) async {
    final initial = _days[index][key]?.toString() ?? '09:00';
    final chunks = initial.split(':');
    final hour = int.tryParse(chunks.first) ?? 9;
    final minute = int.tryParse(chunks.length > 1 ? chunks[1] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked == null) return;

    setState(() {
      _days[index][key] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  String? _validateDay(Map<String, dynamic> day) {
    if (day['isAvailable'] != true) return null;

    final start = day['startTime']?.toString() ?? '';
    final end = day['endTime']?.toString() ?? '';
    if (start.isEmpty || end.isEmpty)
      return '${day['dayOfWeek']}: start/end required';
    if (!_isAfter(end, start))
      return '${day['dayOfWeek']}: endTime must be after startTime';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _savingAvailability = true);

    try {
      await _service.setAvailability(
        serviceId: widget.serviceId,
        availabilitySlots: _days,
      );

      if (!mounted) return;
      setState(() => _published = widget.isInitialSetup);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Availability saved successfully')),
      );
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
        setState(() => _savingAvailability = false);
      }
    }
  }

  Future<void> _saveSpecialDate() async {
    if (_specialDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a special date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _savingSpecialDate = true);

    try {
      await _service.setSpecialDate(
        serviceId: widget.serviceId,
        date: _service.dateOnly(_specialDate!),
        isAvailable: _specialIsAvailable,
        reason: _specialReasonController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Special date updated')));
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
        setState(() => _savingSpecialDate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_published) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Live')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Service Live',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Your service is published and ready for bookings.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AppointmentsDashboardScreen(initialProviderTab: true),
                  ),
                ),
                child: const Text('View Appointments Dashboard'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Set Availability')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('One availability block per day is supported.'),
            const SizedBox(height: 12),
            ...List.generate(_days.length, (index) => _dayCard(index)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingAvailability ? null : _saveAvailability,
                child: _savingAvailability
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Availability'),
              ),
            ),
            const Divider(height: 28),
            const Text(
              'Special Dates (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 3),
                        initialDate: _specialDate ?? now,
                      );
                      if (picked == null) return;
                      setState(() => _specialDate = picked);
                    },
                    child: Text(
                      _specialDate == null
                          ? 'Choose date'
                          : _service.dateOnly(_specialDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    value: _specialIsAvailable,
                    items: const [
                      DropdownMenuItem(value: false, child: Text('Block Date')),
                      DropdownMenuItem(value: true, child: Text('Open Date')),
                    ],
                    onChanged: (value) {
                      setState(() => _specialIsAvailable = value ?? false);
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _specialReasonController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reason (optional)',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _savingSpecialDate ? null : _saveSpecialDate,
                child: _savingSpecialDate
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Special Date'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(int index) {
    final row = _days[index];
    final enabled = row['isAvailable'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row['dayOfWeek'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: enabled,
                  onChanged: (value) {
                    setState(() => row['isAvailable'] = value);
                  },
                ),
              ],
            ),
            if (enabled) ...[
              Row(
                children: [
                  Expanded(
                    child: _timeButton(
                      label: 'Start',
                      value: row['startTime'].toString(),
                      onTap: () => _pickTime(index, 'startTime'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _timeButton(
                      label: 'End',
                      value: row['endTime'].toString(),
                      onTap: () => _pickTime(index, 'endTime'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _timeButton(
                      label: 'Break Start',
                      value: (row['breakStartTime']?.toString().isEmpty ?? true)
                          ? 'Optional'
                          : row['breakStartTime'].toString(),
                      onTap: () => _pickTime(index, 'breakStartTime'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _timeButton(
                      label: 'Break End',
                      value: (row['breakEndTime']?.toString().isEmpty ?? true)
                          ? 'Optional'
                          : row['breakEndTime'].toString(),
                      onTap: () => _pickTime(index, 'breakEndTime'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: row['slotDurationMinutes'] as int,
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
                  setState(() => row['slotDurationMinutes'] = value);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Slot Duration',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }
}
