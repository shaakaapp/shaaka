class UserProfile {
  final int? id;
  final String fullName;
  final String mobileNumber;
  final String? gender;
  final String category;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? locationUrl;
  final String? profilePicUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.fullName,
    required this.mobileNumber,
    this.gender,
    required this.category,
    this.addressLine,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.latitude,
    this.longitude,
    this.locationUrl,
    this.profilePicUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      gender: json['gender'],
      category: json['category'] ?? '',
      addressLine: json['address_line'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      latitude: (json['latitude'] != null) ? (json['latitude'] as num).toDouble() : null,
      longitude: (json['longitude'] != null) ? (json['longitude'] as num).toDouble() : null,
      locationUrl: json['location_url'],
      profilePicUrl: json['profile_pic_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      'gender': gender,
      'category': category,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'location_url': locationUrl,
      'profile_pic_url': profilePicUrl,
    };
  }
}

