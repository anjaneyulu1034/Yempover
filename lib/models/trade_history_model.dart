import 'dart:convert';
import 'chats/trade_chat.dart' show BarterProductInfo;

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return <dynamic>[];
}

String _asString(dynamic value, [String defaultValue = '']) {
  if (value == null) return defaultValue;
  return value.toString();
}

int _asInt(dynamic value, [int defaultValue = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool _asBool(dynamic value, [bool defaultValue = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase().trim();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return defaultValue;
}

DateTime _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime(1970, 1, 1);
  return DateTime(1970, 1, 1);
}

class TradeHistoryResponse {
  final String status;
  final String message;
  final TradeStatsData data;

  TradeHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TradeHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TradeHistoryResponse(
      status: _asString(json['status']),
      message: _asString(json['message']),
      data: TradeStatsData.fromJson(_asMap(json['data'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data.toJson()};
  }
}

class TradeStatsData {
  final int totalTradesCompleted;
  final Breakdown breakdown;
  final Trades trades;
  final Subscription subscription;

  TradeStatsData({
    required this.totalTradesCompleted,
    required this.breakdown,
    required this.trades,
    required this.subscription,
  });

  factory TradeStatsData.fromJson(Map<String, dynamic> json) {
    return TradeStatsData(
      totalTradesCompleted: _asInt(json['totalTradesCompleted']),
      breakdown: Breakdown.fromJson(_asMap(json['breakdown'])),
      trades: Trades.fromJson(_asMap(json['trades'])),
      subscription: Subscription.fromJson(_asMap(json['subscription'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTradesCompleted': totalTradesCompleted,
      'breakdown': breakdown.toJson(),
      'trades': trades.toJson(),
      'subscription': subscription.toJson(),
    };
  }
}

class Breakdown {
  final int soldProducts;
  final int boughtProducts;
  final int soldServices;
  final int boughtServices;
  final int barterExchanges;

  Breakdown({
    required this.soldProducts,
    required this.boughtProducts,
    required this.soldServices,
    required this.boughtServices,
    required this.barterExchanges,
  });

  factory Breakdown.fromJson(Map<String, dynamic> json) {
    return Breakdown(
      soldProducts: _asInt(json['soldProducts']),
      boughtProducts: _asInt(json['boughtProducts']),
      soldServices: _asInt(json['soldServices']),
      boughtServices: _asInt(json['boughtServices']),
      barterExchanges: _asInt(json['barterExchanges']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soldProducts': soldProducts,
      'boughtProducts': boughtProducts,
      'soldServices': soldServices,
      'boughtServices': boughtServices,
      'barterExchanges': barterExchanges,
    };
  }
}

class Trades {
  final List<TradeItem> soldProducts;
  final List<TradeItem> boughtProducts;
  final List<TradeItem> soldServices;
  final List<TradeItem> boughtServices;
  final List<TradeItem> barterExchanges;

  Trades({
    required this.soldProducts,
    required this.boughtProducts,
    required this.soldServices,
    required this.boughtServices,
    required this.barterExchanges,
  });

  factory Trades.fromJson(Map<String, dynamic> json) {
    return Trades(
      soldProducts: _asList(json['soldProducts'])
          .whereType<Map>()
          .map((e) => TradeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      boughtProducts: _asList(json['boughtProducts'])
          .whereType<Map>()
          .map((e) => TradeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      soldServices: _asList(json['soldServices'])
          .whereType<Map>()
          .map((e) => TradeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      boughtServices: _asList(json['boughtServices'])
          .whereType<Map>()
          .map((e) => TradeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      // The backend already separates barter exchanges into their own
      // bucket (Transaction.type === 'BARTER'); tag each item explicitly
      // here rather than trying to re-derive "is this a barter trade" from
      // Product.barterStatus once items are flattened into one list — that
      // field only ever says whether a product is *open* for barter, not
      // whether a given completed trade was a barter or a cash sale.
      barterExchanges: _asList(json['barterExchanges'])
          .whereType<Map>()
          .map(
            (e) => TradeItem.fromJson(
              Map<String, dynamic>.from(e),
              isBarterExchange: true,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soldProducts': soldProducts.map((e) => e.toJson()).toList(),
      'boughtProducts': boughtProducts.map((e) => e.toJson()).toList(),
      'soldServices': soldServices.map((e) => e.toJson()).toList(),
      'boughtServices': boughtServices.map((e) => e.toJson()).toList(),
      'barterExchanges': barterExchanges.map((e) => e.toJson()).toList(),
    };
  }

  // Helper method to get all trades as a single list sorted by date
  List<TradeItem> getAllTrades() {
    final List<TradeItem> allTrades = [];
    allTrades.addAll(soldProducts);
    allTrades.addAll(boughtProducts);
    allTrades.addAll(soldServices);
    allTrades.addAll(boughtServices);
    allTrades.addAll(barterExchanges);

    // Sort by completed date (most recent first)
    allTrades.sort((a, b) => b.completedDate.compareTo(a.completedDate));

    return allTrades;
  }
}

// How a completed trade's value actually changed hands — a cleaner
// classification than the old Sold/Purchased/Barter split, which only says
// which bucket the backend sorted the trade into, not whether coins, barter
// items, or both were involved.
class ExchangeSummary {
  final String type; // COINS | BARTER | BARTER_PLUS_COINS
  final String label; // Coins | Barter | Barter + Coins
  final double? actualPrice;
  final double? coins;
  final double? priceDifference;
  final bool? viewerIsInitiator;

  ExchangeSummary({
    required this.type,
    required this.label,
    this.actualPrice,
    this.coins,
    this.priceDifference,
    this.viewerIsInitiator,
  });

  factory ExchangeSummary.fromJson(Map<String, dynamic> json) {
    return ExchangeSummary(
      type: _asString(json['type']),
      label: _asString(json['label']),
      actualPrice: _asNullableDouble(json['actualPrice']),
      coins: _asNullableDouble(json['coins']),
      priceDifference: _asNullableDouble(json['priceDifference']),
      viewerIsInitiator: json['viewerIsInitiator'] is bool
          ? json['viewerIsInitiator'] as bool
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'label': label,
      'actualPrice': actualPrice,
      'coins': coins,
      'priceDifference': priceDifference,
      'viewerIsInitiator': viewerIsInitiator,
    };
  }
}

class TradeItem {
  final String id;
  final DateTime completedDate;
  final OtherUser otherUser;
  final double? sellingPrice;
  final String? remarks;
  final String? initiatorRemarks;
  final String participantRemarks;
  final Product product;
  final bool isBarterExchange;
  // Snapshot of the actual item swapped on a barter/both offer — distinct
  // from `product`, which is only the listing the chat was opened on. Null
  // for pure sale deals, or for trades completed before this was tracked.
  final String? barterItemTitle;
  final String? barterItemDescription;
  final List<String> barterItemImages;
  // Same order as barterItemImages — pairs each image with the product it
  // came from so it can deep-link to that product's detail page.
  final List<String> barterProductIds;
  // The actually-swapped items, resolved server-side — same shape as a
  // trade-chat offer's barterProducts (id, title, images, price, status,
  // postedById). Empty for pure sale deals or trades that predate this.
  final List<BarterProductInfo> barterProducts;
  final bool? isMyBarterItem;
  // How this trade's value actually changed hands (Coins/Barter/Barter +
  // Coins) plus the actual/selling/difference price block. Null for trades
  // completed before this was tracked.
  final ExchangeSummary? exchangeSummary;

  TradeItem({
    required this.id,
    required this.completedDate,
    required this.otherUser,
    this.sellingPrice,
    this.remarks,
    this.initiatorRemarks,
    required this.participantRemarks,
    required this.product,
    this.isBarterExchange = false,
    this.barterItemTitle,
    this.barterItemDescription,
    this.barterItemImages = const [],
    this.barterProductIds = const [],
    this.barterProducts = const [],
    this.isMyBarterItem,
    this.exchangeSummary,
  });

  factory TradeItem.fromJson(
    Map<String, dynamic> json, {
    bool isBarterExchange = false,
  }) {
    return TradeItem(
      id: _asString(json['id']),
      completedDate: _asDateTime(json['completedDate']),
      otherUser: OtherUser.fromJson(_asMap(json['otherUser'])),
      sellingPrice: _asNullableDouble(json['sellingPrice']),
      remarks: json['remarks']?.toString(),
      initiatorRemarks: json['initiatorRemarks']?.toString(),
      participantRemarks: _asString(json['participantRemarks']),
      product: Product.fromJson(_asMap(json['product'])),
      isBarterExchange: isBarterExchange,
      barterItemTitle: json['barterItemTitle']?.toString(),
      barterItemDescription: json['barterItemDescription']?.toString(),
      barterItemImages: _asList(
        json['barterItemImages'],
      ).map((e) => e.toString()).toList(),
      barterProductIds: _asList(
        json['barterProductIds'],
      ).map((e) => e.toString()).toList(),
      barterProducts: _asList(json['barterProducts'])
          .whereType<Map>()
          .map((p) => BarterProductInfo.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      isMyBarterItem: json['isMyBarterItem'] is bool
          ? json['isMyBarterItem'] as bool
          : null,
      exchangeSummary: json['exchangeSummary'] is Map
          ? ExchangeSummary.fromJson(
              Map<String, dynamic>.from(json['exchangeSummary'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedDate': completedDate.toIso8601String(),
      'otherUser': otherUser.toJson(),
      'sellingPrice': sellingPrice,
      'remarks': remarks,
      'initiatorRemarks': initiatorRemarks,
      'participantRemarks': participantRemarks,
      'product': product.toJson(),
      'isBarterExchange': isBarterExchange,
      'barterItemTitle': barterItemTitle,
      'barterItemDescription': barterItemDescription,
      'barterItemImages': barterItemImages,
      'barterProductIds': barterProductIds,
      'barterProducts': barterProducts.map((p) => p.toJson()).toList(),
      'isMyBarterItem': isMyBarterItem,
      'exchangeSummary': exchangeSummary?.toJson(),
    };
  }

  // True once the backend has recorded a distinct swapped item for this
  // trade (added after the fix — older completed trades won't have this).
  bool get hasBarterItemSnapshot =>
      barterItemTitle != null && barterItemTitle!.trim().isNotEmpty;

  // Determine trade type based on who posted the product
  String getTradeType(String currentUserId) {
    if (isBarter) return 'Barter';
    if (product.postedById == currentUserId) {
      return 'Sold';
    } else {
      return 'Purchased';
    }
  }

  // Check if it's a barter trade
  bool get isBarter => isBarterExchange;

  // Get display price
  double? get displayPrice => sellingPrice ?? product.price;

  // Get trade type for display
  String getDisplayTradeType() {
    if (isBarter) return 'Barter';
    return product.postedById == otherUser.id ? 'Purchased' : 'Sold';
  }
}

class OtherUser {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;

  OtherUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
  });

  factory OtherUser.fromJson(Map<String, dynamic> json) {
    return OtherUser(
      id: _asString(json['id']),
      firstName: _asString(json['firstName']),
      lastName: _asString(json['lastName']),
      profileImage: json['profileImage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
    };
  }

  String get fullName => '$firstName $lastName';
}

class Product {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String status;
  final String barterStatus;
  final double? price;
  final String categoryId;
  final double? latitude;
  final double? longitude;
  final String location;
  final String postedById;
  final DateTime postedDate;
  final int viewCount;
  final bool isListed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    required this.barterStatus,
    this.price,
    required this.categoryId,
    this.latitude,
    this.longitude,
    required this.location,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    required this.isListed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asString(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      images: _asList(json['images']).map((e) => e.toString()).toList(),
      status: _asString(json['status']),
      barterStatus: _asString(json['barterStatus']),
      price: _asNullableDouble(json['price']),
      categoryId: _asString(json['categoryId']),
      latitude: _asNullableDouble(json['latitude']),
      longitude: _asNullableDouble(json['longitude']),
      location: _asString(json['location']),
      postedById: _asString(json['postedById']),
      postedDate: _asDateTime(json['postedDate']),
      viewCount: _asInt(json['viewCount']),
      isListed: _asBool(json['isListed']),
      createdAt: _asDateTime(json['createdAt']),
      updatedAt: _asDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'images': images,
      'status': status,
      'barterStatus': barterStatus,
      'price': price,
      'categoryId': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'postedById': postedById,
      'postedDate': postedDate.toIso8601String(),
      'viewCount': viewCount,
      'isListed': isListed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get primaryImage => images.isNotEmpty ? images.first : '';
}

class Subscription {
  final String planName;
  final DateTime startDate;
  final DateTime endDate;
  final bool isValid;

  Subscription({
    required this.planName,
    required this.startDate,
    required this.endDate,
    required this.isValid,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      planName: _asString(json['planName']),
      startDate: _asDateTime(json['startDate']),
      endDate: _asDateTime(json['endDate']),
      isValid: _asBool(json['isValid']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planName': planName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isValid': isValid,
    };
  }
}
