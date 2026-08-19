import 'package:yempover_app/models/ProductPostmain.dart';

/// A valid barter selection is either exactly one non-clubbable product, or
/// any number of clubbable products — never a mix (mirrors the backend rule
/// in resolveBarterProductOffer). Shared by the initial-offer picker
/// (OfferDeckScreen) and the counter-offer picker (ChatDetailScreen) so both
/// enforce it identically.
class ClubbingSelectionResult {
  final List<UserItem> items;
  // Set whenever the tap replaced an existing selection rather than simply
  // adding to it, so the caller can surface why the previous picks vanished.
  final String? hint;

  const ClubbingSelectionResult(this.items, {this.hint});
}

/// Returns the new selection after toggling [tapped] in/out of [current].
ClubbingSelectionResult applyClubbingSelection({
  required List<UserItem> current,
  required UserItem tapped,
}) {
  final alreadySelected = current.any((i) => i.id == tapped.id);
  if (alreadySelected) {
    return ClubbingSelectionResult(
      current.where((i) => i.id != tapped.id).toList(),
    );
  }

  if (current.isEmpty) {
    return ClubbingSelectionResult([tapped]);
  }

  final currentHasNonClubbable = current.any((i) => !i.isClubbable);

  // Non-clubbable must always be the sole selection; adding a clubbable
  // item to an existing non-clubbable one also starts a fresh selection —
  // either way this replaces rather than combines.
  if (!tapped.isClubbable || currentHasNonClubbable) {
    return ClubbingSelectionResult(
      [tapped],
      hint: "This item can't be combined with others.",
    );
  }

  return ClubbingSelectionResult([...current, tapped]);
}
