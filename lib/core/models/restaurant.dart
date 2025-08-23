class Restaurant {
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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as int,
      naam: json['naam'] as String,
      beschrijving: json['beschrijving'] as String?,
      adres: json['adres'] as String?,
      stad: json['stad'] as String?,
      postcode: json['postcode'] as String?,
      telefoon: json['telefoon'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      priceRange: json['price_range'] as String?,
      cuisineType: json['cuisine_type'] as String?,
      hasDelivery: json['has_delivery'] as bool? ?? false,
      hasTakeaway: json['has_takeaway'] as bool? ?? false,
      isWheelchairAccessible: json['wheelchair'] as bool? ?? false,
      isOpen: json['is_open_now'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      photos: json['photos'] != null 
          ? List<String>.from(json['photos'] as List)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
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
    };
  }

  String get fullAddress {
    final parts = <String>[];
    if (adres != null && adres!.isNotEmpty) parts.add(adres!);
    if (stad != null && stad!.isNotEmpty) parts.add(stad!);
    if (postcode != null && postcode!.isNotEmpty) parts.add(postcode!);
    return parts.join(', ');
  }

  String get primaryPhoto {
    if (photos != null && photos!.isNotEmpty) {
      return photos!.first;
    }
    return ''; // Return empty string for placeholder
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

  String get statusText {
    return isOpen ? 'Open' : 'Gesloten';
  }

  String get ratingDisplay {
    if (rating != null) {
      return '${rating!.toStringAsFixed(1)} ⭐';
    }
    return 'Geen beoordeling';
  }

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
      isWheelchairAccessible: isWheelchairAccessible ?? this.isWheelchairAccessible,
      isOpen: isOpen ?? this.isOpen,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Restaurant(id: $id, naam: $naam, stad: $stad, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restaurant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

