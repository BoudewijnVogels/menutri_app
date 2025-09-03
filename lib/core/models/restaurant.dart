// lib/core/models/restaurant.dart

class Restaurant {
  // --- Oorspronkelijke NL-velden ---
  final int id;
  final String naam;
  final String? beschrijving;
  final String? adres;
  final String? stad;
  final String? postcode;
  final String? telefoon;
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

  // Openingstijden toegevoegd zodat UI's _formatOpeningHours() kan werken
  final Map<String, dynamic>? openingHours;

  Restaurant({
    required this.id,
    required this.naam,
    this.beschrijving,
    this.adres,
    this.stad,
    this.postcode,
    this.telefoon,
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
    // probeer verschillende keys voor opening hours
    final oh = (json['opening_hours'] ?? json['openingHours'] ?? json['hours'])
        as Map<String, dynamic>?;

    return Restaurant(
      id: json['id'] as int,
      naam: json['naam'] as String? ?? json['name'] as String? ?? '',
      beschrijving:
          json['beschrijving'] as String? ?? json['description'] as String?,
      adres: json['adres'] as String? ?? json['address'] as String?,
      stad: json['stad'] as String?,
      postcode: json['postcode'] as String?,
      telefoon: json['telefoon'] as String? ?? json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      priceRange: json['price_range'] as String?,
      cuisineType:
          json['cuisine_type'] as String? ?? json['cuisine'] as String?,
      hasDelivery: (json['has_delivery'] as bool?) ??
          (json['delivery_available'] as bool?) ??
          false,
      hasTakeaway: (json['has_takeaway'] as bool?) ??
          (json['takeaway_available'] as bool?) ??
          false,
      isWheelchairAccessible: (json['wheelchair'] as bool?) ??
          (json['wheelchair_accessible'] as bool?) ??
          false,
      isOpen:
          (json['is_open_now'] as bool?) ?? (json['is_open'] as bool?) ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      photos: (json['photos'] is List)
          ? List<String>.from(json['photos'] as List)
          : (json['images'] is List)
              ? List<String>.from(json['images'] as List)
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      openingHours: oh,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'naam': naam,
      'beschrijving': beschrijving,
      'adres': adres,
      'stad': stad,
      'postcode': postcode,
      'telefoon': telefoon,
      'email': email,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'price_range': priceRange,
      'cuisine_type': cuisineType,
      'has_delivery': hasDelivery,
      'has_takeaway': hasTakeaway,
      'wheelchair': isWheelchairAccessible,
      'is_open_now': isOpen,
      'rating': rating,
      'review_count': reviewCount,
      'photos': photos,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (openingHours != null) 'opening_hours': openingHours,
    };
  }

  // ---------- Convenience helpers (NL) ----------
  String get fullAddress {
    final parts = <String>[];
    if (adres != null && adres!.isNotEmpty) parts.add(adres!);
    if (stad != null && stad!.isNotEmpty) parts.add(stad!);
    if (postcode != null && postcode!.isNotEmpty) parts.add(postcode!);
    return parts.join(', ');
  }

  String get priceRangeDisplay {
    switch (priceRange?.toLowerCase()) {
      case '€':
        return '€ (Budget)';
      case '€€':
        return '€€ (Gemiddeld)';
      case '€€€':
        return '€€€ (Duur)';
      case '€€€€':
        return '€€€€ (Luxe)';
      default:
        return 'Prijs onbekend';
    }
  }

  String get statusText => isOpen ? 'Open' : 'Gesloten';

  String get ratingDisplay =>
      (rating != null) ? '${rating!.toStringAsFixed(1)} ⭐' : 'Geen beoordeling';

  // ---------- Compatibiliteits-getters (EN) ----------
  // Hiermee werkt restaurant_detail_page.dart zonder aanpassingen.
  String get name => naam;
  String? get description => beschrijving;

  /// UI gebruikt `address` nullable; we geven 'adres' terug (niet fullAddress),
  /// omdat de UI al separate weergave van stad/postcode kan doen.
  String? get address => adres;

  String? get phone => telefoon;
  String? get primaryPhoto =>
      (photos != null && photos!.isNotEmpty) ? photos!.first : null;
  String? get imageUrl =>
      (photos != null && photos!.isNotEmpty) ? photos!.first : null;
  bool get deliveryAvailable => hasDelivery;
  bool get takeawayAvailable => hasTakeaway;

  /// In jouw model hebben we geen expliciete reserverings-plicht.
  /// UI verwacht de getter; default = false.
  bool get reservationRequired => false;

  /// UI verwacht een lijst; we mappen jouw enkele `cuisineType` naar een lijst.
  List<String> get cuisineTypes =>
      (cuisineType != null && cuisineType!.isNotEmpty)
          ? [cuisineType!]
          : const [];

  /// UI verwacht deze exact als Map<String, dynamic>?
  Map<String, dynamic>? get openingHoursCompat => openingHours;

  // Voor directe compatibiliteit met de UI die `_restaurant!.openingHours` aanroept:
  Map<String, dynamic>? get openingHoursAlias => openingHours;

  // (optioneel) Als jouw UI ooit `fullAddress` in EN verwacht:
  String get fullAddressEn => fullAddress;

  // ---------- Copy, equality, toString ----------
  Restaurant copyWith({
    int? id,
    String? naam,
    String? beschrijving,
    String? adres,
    String? stad,
    String? postcode,
    String? telefoon,
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
      naam: naam ?? this.naam,
      beschrijving: beschrijving ?? this.beschrijving,
      adres: adres ?? this.adres,
      stad: stad ?? this.stad,
      postcode: postcode ?? this.postcode,
      telefoon: telefoon ?? this.telefoon,
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
      'Restaurant(id: $id, naam: $naam, stad: $stad, rating: $rating)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Restaurant && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
