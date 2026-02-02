class TradePost {
  final String id;
  final String title;
  final String category;
  final String location;
  final DateTime postedDateTime;
  final bool isOpenForBarter;
  final int views;
  final int openOffers;
  final String price;
  final String wishListCategory;
  final String returnDetails;
  final String transportationFlexibility;
  final String description;
  final List<String> images;
  final bool canClubItems;
  bool isSold;
  bool hasAcceptedOffer;

  TradePost({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.postedDateTime,
    required this.isOpenForBarter,
    required this.views,
    required this.openOffers,
    required this.price,
    required this.wishListCategory,
    required this.returnDetails,
    required this.transportationFlexibility,
    required this.description,
    required this.images,
    required this.canClubItems,
    required this.isSold,
    required this.hasAcceptedOffer,
  });
}
