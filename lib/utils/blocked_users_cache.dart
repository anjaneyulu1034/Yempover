import 'package:flutter/foundation.dart';
import 'package:YemPover_app/models/favorites_response.dart';
import 'package:YemPover_app/services/blocked_user_service.dart';

/// Cached blocked-user IDs used to hide posts across the app.
class BlockedUsersCache extends ChangeNotifier {
  BlockedUsersCache._();

  static final BlockedUsersCache instance = BlockedUsersCache._();

  final BlockedUserService _service = BlockedUserService();
  Set<String> _ids = {};
  bool _loaded = false;
  Future<void>? _loading;

  bool isBlocked(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return _ids.contains(userId);
  }

  Future<void> ensureLoaded({bool force = false}) async {
    if (!force && _loaded) return;
    if (_loading != null && !force) {
      await _loading;
      return;
    }

    _loading = _reload();
    try {
      await _loading;
    } finally {
      _loading = null;
    }
  }

  Future<void> _reload() async {
    final users = await _service.getBlockedUsers(limit: 500);
    final next = users
        .map((u) => u.blockedId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final changed = !_setEquals(_ids, next);
    _ids = next;
    _loaded = true;
    if (changed) notifyListeners();
  }

  void add(String userId) {
    if (userId.isEmpty) return;
    if (_ids.add(userId)) {
      _loaded = true;
      notifyListeners();
    }
  }

  void remove(String userId) {
    if (_ids.remove(userId)) notifyListeners();
  }

  void invalidate() {
    _loaded = false;
  }

  List<FavoriteItem> filterFavorites(List<FavoriteItem> items) {
    return filterByOwner(items, _favoriteOwnerId);
  }

  List<T> filterByOwner<T>(List<T> items, String? Function(T item) ownerId) {
    return items.where((item) => !isBlocked(ownerId(item))).toList();
  }

  static String? _favoriteOwnerId(FavoriteItem favorite) {
    final fromPostedBy = favorite.post?.postedBy.id ?? '';
    if (fromPostedBy.isNotEmpty) return fromPostedBy;

    final fromPostedById = favorite.post?.postedById ?? '';
    if (fromPostedById.isNotEmpty) return fromPostedById;

    final legacy = favorite.postedBy.id;
    return legacy.isNotEmpty ? legacy : null;
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final id in a) {
      if (!b.contains(id)) return false;
    }
    return true;
  }
}
