// lib/models/service_availability_plan.dart
//
// Mirrors the `availabilityPlan` object the backend now returns from every
// service availability/expiry endpoint (Set Availability, create/edit
// service, availability-plan preview, available-slots, service detail).
// The server decides mode/durations/validation; this screen only renders
// what it sends (QA BUG-1..5).

class AppDateFormatConfig {
  final String date;
  final String dateShort;
  final String time;
  final String dateTime;
  final String rangeSeparator;
  final String timeZone;

  const AppDateFormatConfig({
    required this.date,
    required this.dateShort,
    required this.time,
    required this.dateTime,
    required this.rangeSeparator,
    required this.timeZone,
  });

  factory AppDateFormatConfig.fromJson(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return AppDateFormatConfig(
      date: j['date']?.toString() ?? 'EEE, d MMM yyyy',
      dateShort: j['dateShort']?.toString() ?? 'd MMM yyyy',
      time: j['time']?.toString() ?? 'h:mm a',
      dateTime: j['dateTime']?.toString() ?? 'EEE, d MMM yyyy, h:mm a',
      rangeSeparator: j['rangeSeparator']?.toString() ?? '–',
      timeZone: j['timeZone']?.toString() ?? 'Asia/Kolkata',
    );
  }
}

class DurationOption {
  final int minutes;
  final String label;
  final bool enabled;
  final String? disabledReason;
  final bool isDefault;

  const DurationOption({
    required this.minutes,
    required this.label,
    required this.enabled,
    this.disabledReason,
    required this.isDefault,
  });

  factory DurationOption.fromJson(Map<String, dynamic> json) {
    return DurationOption(
      minutes: _asInt(json['minutes']) ?? 0,
      label: json['label']?.toString() ?? '${json['minutes'] ?? ''} min',
      enabled: json['enabled'] != false,
      disabledReason: json['disabledReason']?.toString(),
      isDefault: json['isDefault'] == true,
    );
  }
}

class DayOff {
  final String dayOfWeek;
  final String dayLabel;

  const DayOff({required this.dayOfWeek, required this.dayLabel});

  factory DayOff.fromJson(Map<String, dynamic> json) {
    return DayOff(
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      dayLabel: json['dayLabel']?.toString() ?? '',
    );
  }
}

class AvailabilityDateRow {
  final String date; // "YYYY-MM-DD" — sent back verbatim on save.
  final String dateLabel;
  final String dayOfWeek;
  final String dayLabel;
  String startTime; // "HH:mm" — editable by the seller within the row.
  String endTime;
  final String startTimeLabel;
  final String endTimeLabel;
  final String rangeLabel;
  final int windowMinutes;
  final String windowLabel;
  final String label;
  final bool isFirst;
  final bool isLast;
  final bool isClippedAtStart;
  final bool isClippedAtExpiry;

  AvailabilityDateRow({
    required this.date,
    required this.dateLabel,
    required this.dayOfWeek,
    required this.dayLabel,
    required this.startTime,
    required this.endTime,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.rangeLabel,
    required this.windowMinutes,
    required this.windowLabel,
    required this.label,
    required this.isFirst,
    required this.isLast,
    required this.isClippedAtStart,
    required this.isClippedAtExpiry,
  });

  factory AvailabilityDateRow.fromJson(Map<String, dynamic> json) {
    return AvailabilityDateRow(
      date: json['date']?.toString() ?? '',
      dateLabel: json['dateLabel']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      dayLabel: json['dayLabel']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '00:00',
      endTime: json['endTime']?.toString() ?? '00:00',
      startTimeLabel: json['startTimeLabel']?.toString() ?? '',
      endTimeLabel: json['endTimeLabel']?.toString() ?? '',
      rangeLabel: json['rangeLabel']?.toString() ?? '',
      windowMinutes: _asInt(json['windowMinutes']) ?? 0,
      windowLabel: json['windowLabel']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      isFirst: json['isFirst'] == true,
      isLast: json['isLast'] == true,
      isClippedAtStart: json['isClippedAtStart'] == true,
      isClippedAtExpiry: json['isClippedAtExpiry'] == true,
    );
  }

  // Exactly the shape the save endpoints expect for AVAILABLE_NOW/DATE_RANGE
  // mode rows — `date` is sent back verbatim, never recomputed client-side.
  Map<String, dynamic> toSlotJson({required int slotDurationMinutes}) {
    return {
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': true,
      'slotDurationMinutes': slotDurationMinutes,
    };
  }
}

class AvailabilityPlan {
  final String mode; // AVAILABLE_NOW | DATE_RANGE | WEEKLY | EXPIRED
  final String modeLabel;

  final bool hasExpiry;
  final DateTime? expiresAt;
  final String? expiresAtLabel;
  final String? expiresAtDateLabel;
  final int? remainingMinutes;
  final String? remainingLabel;

  final DateTime? windowStart;
  final String? windowStartLabel;
  final DateTime? windowEnd;
  final String? windowEndLabel;
  final String? windowLabel;

  final bool showAvailableNowCard;
  final bool showDateRows;
  final bool showWeeklyGrid;
  final bool showDayToggles;
  final bool allowsWeeklyRepeat;

  final List<AvailabilityDateRow> dates;
  final int dateCount;

  final DateTime? effectiveUntil;
  final String? effectiveUntilLabel;
  final List<DayOff> daysOff;
  final bool supportsDaysOff;
  final bool supportsHolidayImport;
  final bool supportsBookingHorizon;
  final int? bookingHorizonDays;

  final List<DurationOption> durationOptions;
  final int? defaultDurationMinutes;
  final int? maxDurationMinutes;
  final int? maxWindowMinutes;

  final bool canSave;
  final String? blockingReason;

  final bool hasSavedAvailability;
  final bool needsAvailabilitySetup;

  final AppDateFormatConfig dateFormat;

  const AvailabilityPlan({
    required this.mode,
    required this.modeLabel,
    required this.hasExpiry,
    this.expiresAt,
    this.expiresAtLabel,
    this.expiresAtDateLabel,
    this.remainingMinutes,
    this.remainingLabel,
    this.windowStart,
    this.windowStartLabel,
    this.windowEnd,
    this.windowEndLabel,
    this.windowLabel,
    required this.showAvailableNowCard,
    required this.showDateRows,
    required this.showWeeklyGrid,
    required this.showDayToggles,
    required this.allowsWeeklyRepeat,
    required this.dates,
    required this.dateCount,
    this.effectiveUntil,
    this.effectiveUntilLabel,
    required this.daysOff,
    required this.supportsDaysOff,
    required this.supportsHolidayImport,
    required this.supportsBookingHorizon,
    this.bookingHorizonDays,
    required this.durationOptions,
    this.defaultDurationMinutes,
    this.maxDurationMinutes,
    this.maxWindowMinutes,
    required this.canSave,
    this.blockingReason,
    required this.hasSavedAvailability,
    required this.needsAvailabilitySetup,
    required this.dateFormat,
  });

  bool get isExpired => mode == 'EXPIRED';
  bool get isWeekly => mode == 'WEEKLY';

  // Client-side fallback for the one case that's never actually ambiguous
  // even without a plan from the server: a brand-new service (no id yet)
  // with "no expiry" is always the recurring weekly schedule. Used only
  // when the availability-plan preview call itself fails, so the create
  // flow doesn't get stuck behind a blocking error over something the
  // client can already determine on its own.
  factory AvailabilityPlan.defaultWeekly() {
    return AvailabilityPlan(
      mode: 'WEEKLY',
      modeLabel: 'Weekly Schedule',
      hasExpiry: false,
      showAvailableNowCard: false,
      showDateRows: false,
      showWeeklyGrid: true,
      showDayToggles: true,
      allowsWeeklyRepeat: true,
      dates: const [],
      dateCount: 0,
      daysOff: const [],
      supportsDaysOff: false,
      supportsHolidayImport: false,
      supportsBookingHorizon: false,
      durationOptions: const [],
      defaultDurationMinutes: 30,
      canSave: true,
      hasSavedAvailability: false,
      needsAvailabilitySetup: true,
      dateFormat: AppDateFormatConfig.fromJson(null),
    );
  }

  factory AvailabilityPlan.fromJson(Map<String, dynamic> json) {
    return AvailabilityPlan(
      mode: json['mode']?.toString() ?? 'WEEKLY',
      modeLabel: json['modeLabel']?.toString() ?? '',
      hasExpiry: json['hasExpiry'] == true,
      expiresAt: _asDateTime(json['expiresAt']),
      expiresAtLabel: json['expiresAtLabel']?.toString(),
      expiresAtDateLabel: json['expiresAtDateLabel']?.toString(),
      remainingMinutes: _asInt(json['remainingMinutes']),
      remainingLabel: json['remainingLabel']?.toString(),
      windowStart: _asDateTime(json['windowStart']),
      windowStartLabel: json['windowStartLabel']?.toString(),
      windowEnd: _asDateTime(json['windowEnd']),
      windowEndLabel: json['windowEndLabel']?.toString(),
      windowLabel: json['windowLabel']?.toString(),
      showAvailableNowCard: json['showAvailableNowCard'] == true,
      showDateRows: json['showDateRows'] == true,
      showWeeklyGrid: json['showWeeklyGrid'] == true,
      showDayToggles: json['showDayToggles'] == true,
      allowsWeeklyRepeat: json['allowsWeeklyRepeat'] == true,
      dates: _asList(json['dates'])
          .map((e) => AvailabilityDateRow.fromJson(e))
          .toList(),
      dateCount: _asInt(json['dateCount']) ?? 0,
      effectiveUntil: _asDateTime(json['effectiveUntil']),
      effectiveUntilLabel: json['effectiveUntilLabel']?.toString(),
      daysOff: _asList(
        json['daysOff'],
      ).map((e) => DayOff.fromJson(e)).toList(),
      supportsDaysOff: json['supportsDaysOff'] == true,
      supportsHolidayImport: json['supportsHolidayImport'] == true,
      supportsBookingHorizon: json['supportsBookingHorizon'] == true,
      bookingHorizonDays: _asInt(json['bookingHorizonDays']),
      durationOptions: _asList(
        json['durationOptions'],
      ).map((e) => DurationOption.fromJson(e)).toList(),
      defaultDurationMinutes: _asInt(json['defaultDurationMinutes']),
      maxDurationMinutes: _asInt(json['maxDurationMinutes']),
      maxWindowMinutes: _asInt(json['maxWindowMinutes']),
      canSave: json['canSave'] != false,
      blockingReason: json['blockingReason']?.toString(),
      hasSavedAvailability: json['hasSavedAvailability'] == true,
      needsAvailabilitySetup: json['needsAvailabilitySetup'] == true,
      dateFormat: AppDateFormatConfig.fromJson(
        json['dateFormat'] as Map<String, dynamic>?,
      ),
    );
  }
}

class AvailabilityConfirmation {
  final bool required;
  final String code;
  // REPLACE_WITH_AVAILABLE_NOW | REPLACE_WITH_DATES | REQUIRE_WEEKLY_SETUP | BLOCKED
  final String action;
  final String fromMode;
  final String fromModeLabel;
  final String toMode;
  final String toModeLabel;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  // Re-sent verbatim as `availabilitySlots` when the seller confirms.
  final List<Map<String, dynamic>> suggestedAvailability;
  final AvailabilityPlan? plan;

  const AvailabilityConfirmation({
    required this.required,
    required this.code,
    required this.action,
    required this.fromMode,
    required this.fromModeLabel,
    required this.toMode,
    required this.toModeLabel,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.suggestedAvailability,
    this.plan,
  });

  factory AvailabilityConfirmation.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'];
    return AvailabilityConfirmation(
      required: json['required'] != false,
      code: json['code']?.toString() ?? 'AVAILABILITY_MODE_CHANGE',
      action: json['action']?.toString() ?? '',
      fromMode: json['fromMode']?.toString() ?? '',
      fromModeLabel: json['fromModeLabel']?.toString() ?? '',
      toMode: json['toMode']?.toString() ?? '',
      toModeLabel: json['toModeLabel']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Update your availability?',
      message: json['message']?.toString() ?? '',
      confirmLabel: json['confirmLabel']?.toString() ?? 'Continue',
      cancelLabel: json['cancelLabel']?.toString() ?? 'Cancel',
      suggestedAvailability: _asList(json['suggestedAvailability']),
      plan: planJson is Map<String, dynamic>
          ? AvailabilityPlan.fromJson(planJson)
          : null,
    );
  }
}

class AvailabilityPlanResponse {
  final String? serviceId;
  final AvailabilityPlan plan;
  final AvailabilityPlan? currentPlan;
  final AvailabilityConfirmation? confirmation;

  const AvailabilityPlanResponse({
    this.serviceId,
    required this.plan,
    this.currentPlan,
    this.confirmation,
  });

  factory AvailabilityPlanResponse.fromJson(Map<String, dynamic> json) {
    final confirmationJson = json['confirmation'];
    final currentPlanJson = json['currentPlan'];
    return AvailabilityPlanResponse(
      serviceId: json['serviceId']?.toString(),
      plan: AvailabilityPlan.fromJson(
        (json['plan'] as Map<String, dynamic>?) ?? const {},
      ),
      currentPlan: currentPlanJson is Map<String, dynamic>
          ? AvailabilityPlan.fromJson(currentPlanJson)
          : null,
      confirmation: confirmationJson is Map<String, dynamic>
          ? AvailabilityConfirmation.fromJson(confirmationJson)
          : null,
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}
