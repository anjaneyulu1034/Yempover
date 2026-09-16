import 'package:yempover_app/models/service_availability_plan.dart';
import 'package:yempover_app/services/my_posts_service.dart';
import 'package:yempover_app/services/service_booking_service.dart';
import 'package:yempover_app/utils/api_exceptions.dart';
import 'package:yempover_app/utils/app_date_format.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';

class ServiceAvailabilityScreen extends StatefulWidget {
  final String serviceId;
  final bool isInitialSetup;
  final List<Map<String, dynamic>>? initialAvailabilitySlots;
  // When true, "Save" doesn't hit the network — it just pops with the
  // picked slots (List<Map<String, dynamic>>) so the caller can bundle them
  // into its own single create/update call instead of this screen saving
  // them separately.
  final bool pickerMode;
  // The post's own expiry (Timeline Post Expiry) — kept as a fallback for
  // callers that haven't fetched a plan yet; prefer `initialPlan`.
  final DateTime? expiryValidUntil;
  // The availabilityPlan already fetched by the caller (e.g. the Timeline
  // Post Expiry picker's preview call) — QA BUG-1: the server decides which
  // mode to render, not this screen. When null, the screen fetches its own.
  final AvailabilityPlan? initialPlan;
  // True only when the caller is CERTAIN the seller picked "No expiry" —
  // as opposed to `expiryValidUntil` merely being null, which for an
  // existing service can also mean "already expired, keep as-is" (a
  // sentinel the edit screen carries separately). Only set this when it's
  // unambiguous: a brand-new service with no expiry, or an edit where the
  // seller explicitly chose "No expiry". Used to fall back to the weekly
  // grid locally if the plan-preview call fails, without ever guessing
  // wrong for an expired listing.
  final bool knownNoExpiry;

  const ServiceAvailabilityScreen({
    super.key,
    this.serviceId = '',
    this.isInitialSetup = false,
    this.initialAvailabilitySlots,
    this.pickerMode = false,
    this.expiryValidUntil,
    this.initialPlan,
    this.knownNoExpiry = false,
  });

  @override
  State<ServiceAvailabilityScreen> createState() =>
      _ServiceAvailabilityScreenState();
}

class _ServiceAvailabilityScreenState extends State<ServiceAvailabilityScreen> {
  final ServiceBookingService _service = ServiceBookingService();
  final MyPostsService _myPostsService = MyPostsService();

  bool _savingAvailability = false;
  bool _loadingAvailability = false;
  bool _loadingPlan = false;
  bool _published = false;

  // QA BUG-1: which screen to render comes from the server, not a
  // client-side heuristic. Everything below is derived from this.
  AvailabilityPlan? _plan;
  bool get _isLoading => _loadingAvailability || _loadingPlan || _plan == null;

  // One row per calendar date — only populated/used in AVAILABLE_NOW /
  // DATE_RANGE mode, seeded straight from `_plan.dates` (already clipped to
  // now/expiry by the server).
  List<AvailabilityDateRow> _dateRows = [];
  int? _selectedDurationMinutes;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (widget.initialPlan != null) {
      _applyPlan(widget.initialPlan!);
    } else {
      await _loadPlan();
    }
    if (!widget.isInitialSetup) {
      await _loadExistingAvailability();
    }
  }

  Future<void> _loadPlan() async {
    setState(() => _loadingPlan = true);
    try {
      final response = await _myPostsService.getServiceAvailabilityPlan(
        serviceId: widget.serviceId.isNotEmpty ? widget.serviceId : null,
        validUntil: widget.expiryValidUntil?.toUtc().toIso8601String(),
      );
      if (!mounted) return;
      _applyPlan(response.plan);
    } catch (error) {
      if (!mounted) return;
      // "No expiry" is never ambiguous — it's always the recurring weekly
      // schedule — so don't block on a server round trip that has nothing
      // left to resolve beyond what's already known client-side. This is
      // safe for a brand-new service (no id yet, no expiry set), and for an
      // edit ONLY when the caller has confirmed the seller actually chose
      // "No expiry" (`knownNoExpiry`) rather than `expiryValidUntil` simply
      // being null for some other reason (e.g. an already-expired listing
      // being left as-is, which must still show the expired-state card).
      final safeToDefaultWeekly =
          (widget.serviceId.isEmpty && widget.expiryValidUntil == null) ||
          widget.knownNoExpiry;
      if (safeToDefaultWeekly) {
        _applyPlan(AvailabilityPlan.defaultWeekly());
      } else {
        SnackbarUtils.showError(context, _messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  void _applyPlan(AvailabilityPlan plan) {
    setState(() {
      _plan = plan;
      _selectedDurationMinutes = plan.defaultDurationMinutes;
      _dateRows = plan.dates
          .map(
            (r) => AvailabilityDateRow(
              date: r.date,
              dateLabel: r.dateLabel,
              dayOfWeek: r.dayOfWeek,
              dayLabel: r.dayLabel,
              startTime: r.startTime,
              endTime: r.endTime,
              startTimeLabel: r.startTimeLabel,
              endTimeLabel: r.endTimeLabel,
              rangeLabel: r.rangeLabel,
              windowMinutes: r.windowMinutes,
              windowLabel: r.windowLabel,
              label: r.label,
              isFirst: r.isFirst,
              isLast: r.isLast,
              isClippedAtStart: r.isClippedAtStart,
              isClippedAtExpiry: r.isClippedAtExpiry,
            ),
          )
          .toList();
    });
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

    if (widget.serviceId.isEmpty) return;

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
        SnackbarUtils.showError(context, _messageFor(error));
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

  Future<void> _pickDateRowTime(int rowIndex, bool isStart) async {
    final row = _dateRows[rowIndex];
    final initial = isStart ? row.startTime : row.endTime;
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

    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        row.startTime = value;
      } else {
        row.endTime = value;
      }
    });
  }

  String _formatTime(String timeString) {
    return AppDateFormat.timeOfDay(timeString);
  }

  // Backend-authored messages (QA BUG-3/4) are shown verbatim; only generic/
  // unexpected errors get the sanitizer's network/auth-oriented rewriting.
  String _messageFor(Object error) {
    if (error is ApiCodedException || error is AvailabilityChangeRequiredException) {
      return error.toString();
    }
    return _service.extractMessage(error);
  }

  Future<void> _saveAvailability() async {
    final plan = _plan;
    if (plan == null) return;

    // Server is authoritative (QA BUG-2/3) — this screen only builds the
    // payload shape the mode calls for, it doesn't re-validate it.
    final List<Map<String, dynamic>> payload;
    if (plan.showWeeklyGrid) {
      // `_days` rows default break times to '' (not null) so the "Not set"
      // UI state has a stable value to check .isEmpty against — but the
      // backend validator only treats undefined/null as "no break", and
      // rejects '' against the HH:mm pattern. Left as '', saving ANY day
      // fails validation for every row, not just the one being changed.
      payload = _days.map((day) {
        final normalized = Map<String, dynamic>.from(day);
        final breakStart = normalized['breakStartTime']?.toString() ?? '';
        final breakEnd = normalized['breakEndTime']?.toString() ?? '';
        normalized['breakStartTime'] = breakStart.isEmpty ? null : breakStart;
        normalized['breakEndTime'] = breakEnd.isEmpty ? null : breakEnd;
        return normalized;
      }).toList();
    } else {
      final duration = _selectedDurationMinutes ?? plan.defaultDurationMinutes ?? 15;
      payload = _dateRows
          .map((r) => r.toSlotJson(slotDurationMinutes: duration))
          .toList();
    }

    if (widget.pickerMode) {
      Navigator.pop(context, payload);
      return;
    }

    setState(() => _savingAvailability = true);

    try {
      final response = await _service.setAvailability(
        serviceId: widget.serviceId,
        availabilitySlots: payload,
      );

      if (!mounted) return;

      final data = response['data'];
      final planJson = data is Map<String, dynamic>
          ? data['availabilityPlan']
          : null;
      if (planJson is Map<String, dynamic>) {
        _applyPlan(AvailabilityPlan.fromJson(planJson));
      }

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
      SnackbarUtils.showError(context, _messageFor(error));
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final plan = _plan!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(plan),
          const SizedBox(height: 20),

          if (plan.isExpired)
            _buildExpiredCard(plan)
          else if (plan.showAvailableNowCard)
            _buildAvailableNowCard(plan)
          else if (plan.showDateRows)
            _buildDateRows(plan)
          else if (plan.showWeeklyGrid)
            _buildWeeklyGrid(plan),

          const SizedBox(height: 20),

          if (!plan.isExpired) _buildSaveButton(plan),
        ],
      ),
    );
  }

  Widget _buildHeader(AvailabilityPlan plan) {
    return Container(
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
              const Icon(Icons.schedule, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                plan.showWeeklyGrid ? 'Weekly Schedule' : plan.modeLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.showWeeklyGrid
                ? 'Set your regular weekly availability. One availability block per day is supported.'
                : "This post expires soon, so it's a one-time window instead of a repeating weekly schedule.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredCard(AvailabilityPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'This post has expired',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.blockingReason ??
                'Extend the Timeline Post Expiry to set availability again.',
            style: TextStyle(color: Colors.red.shade900, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }

  // QA BUG-1 / BUG-2: a single (or, when the window crosses midnight,
  // multi-row) non-editable window the seller can't get wrong — there's
  // nothing to toggle. Duration is still user-choosable, from the plan's
  // options only.
  Widget _buildAvailableNowCard(AvailabilityPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 12),
              const SizedBox(width: 8),
              const Text(
                'Available now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (plan.expiresAtLabel != null)
            Text(
              'This post expires ${plan.expiresAtLabel} — set your window automatically below instead of a repeating weekly schedule.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 16),
          if (_dateRows.isEmpty)
            Text(
              plan.blockingReason ?? 'Expiry too short for any appointment.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (_dateRows.length == 1)
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.deepPurple.shade300),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.windowLabel ?? _dateRows.first.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          else
            // Window crosses midnight — one row per calendar date, per spec.
            ..._dateRows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      row.isClippedAtExpiry ? Icons.flag : Icons.schedule,
                      size: 16,
                      color: Colors.deepPurple.shade300,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 16),
          const Text(
            'Appointment Duration',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildDurationChips(plan),
        ],
      ),
    );
  }

  // QA BUG-1: one card per calendar date inside the expiry window, editable
  // start/end time, no day toggle and no weekly-repeat concept.
  Widget _buildDateRows(AvailabilityPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _dateRows.length; i++) ...[
          _buildDateRowCard(i),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        const Text(
          'Appointment Duration',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildDurationChips(plan),
      ],
    );
  }

  Widget _buildDateRowCard(int index) {
    final row = _dateRows[index];
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, size: 18, color: Colors.deepPurple.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.dateLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (row.isClippedAtExpiry)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    'Ends at expiry',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w600,
                    ),
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
                  value: row.startTime,
                  onTap: () => _pickDateRowTime(index, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeField(
                  label: 'End',
                  value: row.endTime,
                  onTap: () => _pickDateRowTime(index, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChips(AvailabilityPlan plan) {
    final options = plan.durationOptions.isNotEmpty
        ? plan.durationOptions
        : const [
            DurationOption(minutes: 15, label: '15 min', enabled: true, isDefault: true),
            DurationOption(minutes: 30, label: '30 min', enabled: true, isDefault: false),
            DurationOption(minutes: 45, label: '45 min', enabled: true, isDefault: false),
            DurationOption(minutes: 60, label: '1 hr', enabled: true, isDefault: false),
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final selected = _selectedDurationMinutes == option.minutes;
        final chip = ChoiceChip(
          label: Text(option.label),
          selected: selected,
          onSelected: option.enabled
              ? (value) {
                  if (!value) return;
                  setState(() => _selectedDurationMinutes = option.minutes);
                }
              : null,
          selectedColor: Colors.deepPurple.shade100,
          labelStyle: TextStyle(
            color: option.enabled ? Colors.black87 : Colors.grey.shade400,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
          backgroundColor: option.enabled ? null : Colors.grey.shade100,
        );
        if (option.enabled || option.disabledReason == null) return chip;
        return Tooltip(message: option.disabledReason!, child: chip);
      }).toList(),
    );
  }

  Widget _buildSaveButton(AvailabilityPlan plan) {
    final canSave = plan.canSave;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!canSave && plan.blockingReason != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              plan.blockingReason!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_savingAvailability || !canSave)
                ? null
                : _saveAvailability,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save),
                      const SizedBox(width: 8),
                      Text(
                        plan.showWeeklyGrid
                            ? 'Save Weekly Schedule'
                            : 'Save Availability',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyGrid(AvailabilityPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan.effectiveUntilLabel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.event_busy, size: 18, color: Colors.amber.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.effectiveUntilLabel!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (plan.daysOff.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.weekend, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Days off: ${plan.daysOff.map((d) => d.dayLabel).join(', ')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...List.generate(_days.length, (index) => _buildDayCard(index, plan)),
      ],
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

  Widget _buildDayCard(int index, AvailabilityPlan plan) {
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
                        _buildDayDurationDropdown(row, plan),
                      ],
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildDayDurationDropdown(
    Map<String, dynamic> row,
    AvailabilityPlan plan,
  ) {
    final options = plan.durationOptions.isNotEmpty
        ? plan.durationOptions
        : const [
            DurationOption(minutes: 15, label: '15 minutes', enabled: true, isDefault: true),
            DurationOption(minutes: 30, label: '30 minutes', enabled: true, isDefault: false),
            DurationOption(minutes: 45, label: '45 minutes', enabled: true, isDefault: false),
            DurationOption(minutes: 60, label: '60 minutes', enabled: true, isDefault: false),
          ];
    final current = row['slotDurationMinutes'] as int;
    // A previously-saved duration might not be one of the plan's current
    // options (e.g. expiry shortened since) — keep it selectable so the
    // dropdown doesn't crash, the server is what actually enforces this.
    final values = options.map((o) => o.minutes).toSet();
    if (!values.contains(current)) {
      values.add(current);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<int>(
        initialValue: current,
        items: values.map((minutes) {
          final option = options.firstWhere(
            (o) => o.minutes == minutes,
            orElse: () => DurationOption(
              minutes: minutes,
              label: '$minutes minutes',
              enabled: true,
              isDefault: false,
            ),
          );
          return DropdownMenuItem(
            value: minutes,
            enabled: option.enabled,
            child: Text(
              option.enabled
                  ? option.label
                  : '${option.label}${option.disabledReason != null ? ' (${option.disabledReason})' : ''}',
              style: TextStyle(
                color: option.enabled ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => row['slotDurationMinutes'] = value);
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                  isOptional && value == 'Not set' ? value : _formatTime(value),
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
