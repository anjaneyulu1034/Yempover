// lib/utils/api_exceptions.dart
//
// Typed exceptions for backend errors that carry a machine-readable `code`
// (and sometimes structured `details`), so callers can branch reliably
// instead of string-matching `message`. The message itself is always
// backend-authored and meant to be shown to the user VERBATIM (QA BUG-3) —
// never pass it through ErrorMessageUtils.sanitize, which is tuned for
// garbling raw network/auth errors, not for the availability/expiry
// validation copy these codes carry.
import 'package:yempover_app/models/service_availability_plan.dart';

class ApiCodedException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final int? statusCode;

  ApiCodedException(this.message, {this.code, this.details, this.statusCode});

  @override
  String toString() => message;
}

// Thrown when a save is refused with 409 AVAILABILITY_MODE_CHANGE — the
// expiry change would swap the availability mode and the seller hasn't
// confirmed yet (QA BUG-4). `confirmation` is the dialog to show; nothing
// was written on the server.
class AvailabilityChangeRequiredException implements Exception {
  final String message;
  final AvailabilityConfirmation confirmation;

  AvailabilityChangeRequiredException(this.message, this.confirmation);

  @override
  String toString() => message;
}
