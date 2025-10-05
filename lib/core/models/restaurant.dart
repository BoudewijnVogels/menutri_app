// lib/core/models/restaurant.dart

class Restaurant {
  // --- Definitieve Engelse velden ---
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? postalCode; // camelCase uitzonderlijk
  final String? phone;
  final String? email;
  final String? website;
  final double? latitude;
  final double? longitude;
  final String? priceRange;
  final String? cuisineType;
  final bool hasDelivery;
  final bool hasTakeaway;
  final bool isWheelchairAccessible;
  final bool isOpen;
  final double? rating;
  final int? reviewCount;
  final List<String>? photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Opening hours so UI's _formatOpeningHours() keeps working
  final Map<String, dynamic>? openingHours;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.postalCode,
    this.phone,
    this.email,
    this.website,
    this.latitude,
    this.longitude,
    this.priceRange,
    this.cuisineType,
    this.hasDelivery = false,
    this.hasTakeaway = false,
    this.isWheelchairAccessible = false,
    this.isOpen = false,
    this.rating,
    this.reviewCount,
    this.photos,
    this.createdAt,
    this.updatedAt,
    this.openingHours,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // try different keys for opening hours (fallback for migration)
    final oh = (json['opening_hours'] ?? json['openingHours'] ?? json['hours'])
        as Map<String, dynamic>?;

    return Restaurant(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postalCode'] as String?, // uitzondering camelCase
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      priceRange: json['price_range'] as String?,
      cuisineType: json['cuisine_type'] as String?,
      hasDelivery: json['has_delivery'] as bool? ?? false,
      hasTakeaway: json['has_takeaway'] as bool? ?? false,
      isWheelchairAccessible:
          json['is_wheelchair_accessible'] as bool? ?? false,
      isOpen: json['is_open'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      photos: (json['photos'] is List)
          ? List<String>.from(json['photos'] as List)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      openingHours: oh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'postalCode': postalCode, // uitzondering camelCase
      'phone': phone,
      'email': email,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'price_range': priceRange,
      'cuisine_type': cuisineType,
      'has_delivery': hasDelivery,
      'has_takeaway': hasTakeaway,
      'is_wheelchair_accessible': isWheelchairAccessible,
      'is_open': isOpen,
      'rating': rating,
      'review_count': reviewCount,
      'photos': photos,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (openingHours != null) 'opening_hours': openingHours,
    };
  }

  // ---------- Convenience helpers ----------
  String get fullAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }

  String get priceRangeDisplay {
    switch (priceRange?.toLowerCase()) {
      case '€':
        return '€ (Budget)';
      case '€€':
        return '€€ (Average)';
      case '€€€':
        return '€€€ (Expensive)';
      case '€€€€':
        return '€€€€ (Luxury)';
      default:
        return 'Price unknown';
    }
  }

  String get statusText => isOpen ? 'Open' : 'Closed';

  String get ratingDisplay =>
      (rating != null) ? '${rating!.toStringAsFixed(1)} ⭐' : 'No rating';

  String? get primaryPhoto =>
      (photos != null && photos!.isNotEmpty) ? photos!.first : null;

  String? get imageUrl =>
      (photos != null && photos!.isNotEmpty) ? photos!.first : null;

  bool get deliveryAvailable => hasDelivery;
  bool get takeawayAvailable => hasTakeaway;

  bool get reservationRequired => false;

  List<String> get cuisineTypes =>
      (cuisineType != null && cuisineType!.isNotEmpty)
          ? [cuisineType!]
          : const [];

  Map<String, dynamic>? get openingHoursCompat => openingHours;
  Map<String, dynamic>? get openingHoursAlias => openingHours;

  // ---------- Copy, equality, toString ----------
  Restaurant copyWith({
    int? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? postalCode,
    String? phone,
    String? email,
    String? website,
    double? latitude,
    double? longitude,
    String? priceRange,
    String? cuisineType,
    bool? hasDelivery,
    bool? hasTakeaway,
    bool? isWheelchairAccessible,
    bool? isOpen,
    double? rating,
    int? reviewCount,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? openingHours,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priceRange: priceRange ?? this.priceRange,
      cuisineType: cuisineType ?? this.cuisineType,
      hasDelivery: hasDelivery ?? this.hasDelivery,
      hasTakeaway: hasTakeaway ?? this.hasTakeaway,
      isWheelchairAccessible:
          isWheelchairAccessible ?? this.isWheelchairAccessible,
      isOpen: isOpen ?? this.isOpen,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      openingHours: openingHours ?? this.openingHours,
    );
  }

  @override
  String toString() =>
      'Restaurant(id: $id, name: $name, city: $city, rating: $rating)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Restaurant && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
