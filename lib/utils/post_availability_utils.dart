/// Helpers to detect posts that should be hidden from feeds/lists.
class PostAvailabilityUtils {
  PostAvailabilityUtils._();

  static const Set<String> _unavailableStatuses = {
    'EXPIRED',
    'SOLD',
    'BARTERED',
    'DELETED',
    'ARCHIVED',
  };

  static bool isUnavailable({
    bool hasExpired = false,
    DateTime? validFrom,
    DateTime? validUntil,
    String? remainingTime,
    String? status,
    bool? isListed,
  }) {
    if (hasExpired) return true;

    if (isListed == false) return true;

    final normalizedStatus = (status ?? '').trim().toUpperCase();
    if (_unavailableStatuses.contains(normalizedStatus)) return true;

    final now = DateTime.now().toUtc();
    final from = validFrom?.toUtc();
    if (from != null && from.isAfter(now)) return true;

    final until = validUntil?.toUtc();
    if (until != null && !until.isAfter(now)) return true;

    final remaining = (remainingTime ?? '').trim().toLowerCase();
    if (remaining.contains('expired')) return true;

    return false;
  }

  /// True when the post detail API would reject with 410/404.
  static bool isApiUnavailableStatus(int? statusCode) {
    return statusCode == 410 || statusCode == 404;
  }
}
