class StationFeedback {
  final String? uid;
  final String stationId;
  final String stationName;
  final String? areaId;
  final String areaName;
  final String category;
  final int rating;
  final String comments;
  final String phone;
  final String imageUrl;
  final bool isNegative;
  final String createdAt;

  StationFeedback({
    this.uid,
    required this.stationId,
    this.stationName = '',
    this.areaId,
    this.areaName = '',
    required this.category,
    required this.rating,
    this.comments = '',
    this.phone = '',
    this.imageUrl = '',
    this.isNegative = false,
    required this.createdAt,
  });

  factory StationFeedback.fromJson(Map<String, dynamic> json) => StationFeedback(
    uid: json['uid'],
    stationId: json['stationId'] ?? '',
    stationName: json['stationName'] ?? '',
    areaId: json['areaId'],
    areaName: json['areaName'] ?? '',
    category: json['category'] ?? '',
    rating: json['rating'] ?? 3,
    comments: json['comments'] ?? '',
    phone: json['phone'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    isNegative: json['isNegative'] ?? false,
    createdAt: json['createdAt'] ?? '',
  );
}

class FeedbackSummary {
  final String stationId;
  final int totalFeedback;
  final double averageRating;
  final int negativeCount;
  final int positiveCount;
  final Map<String, CategoryBreakdown> categoryBreakdown;

  FeedbackSummary({
    required this.stationId,
    required this.totalFeedback,
    required this.averageRating,
    required this.negativeCount,
    required this.positiveCount,
    required this.categoryBreakdown,
  });

  factory FeedbackSummary.fromJson(Map<String, dynamic> json) {
    final breakdown = <String, CategoryBreakdown>{};
    if (json['categoryBreakdown'] is Map) {
      (json['categoryBreakdown'] as Map).forEach((key, val) {
        breakdown[key.toString()] = CategoryBreakdown.fromJson(val);
      });
    }
    return FeedbackSummary(
      stationId: json['stationId'] ?? '',
      totalFeedback: json['totalFeedback'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      negativeCount: json['negativeCount'] ?? 0,
      positiveCount: json['positiveCount'] ?? 0,
      categoryBreakdown: breakdown,
    );
  }
}

class CategoryBreakdown {
  final int count;
  final double averageRating;

  CategoryBreakdown({required this.count, required this.averageRating});

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) => CategoryBreakdown(
    count: json['count'] ?? 0,
    averageRating: (json['averageRating'] ?? 0).toDouble(),
  );
}

const List<String> feedbackCategories = [
  'toilet_cleanliness', 'platform_cleanliness', 'waiting_room_cleanliness',
  'garbage_dustbin', 'smell_odour', 'water_booth_cleanliness',
  'staff_behaviour', 'other'
];

String feedbackCategoryLabel(String cat) {
  switch (cat) {
    case 'toilet_cleanliness': return 'Toilet Cleanliness';
    case 'platform_cleanliness': return 'Platform Cleanliness';
    case 'waiting_room_cleanliness': return 'Waiting Room Cleanliness';
    case 'garbage_dustbin': return 'Garbage / Dustbin';
    case 'smell_odour': return 'Smell / Odour';
    case 'water_booth_cleanliness': return 'Water Booth Cleanliness';
    case 'staff_behaviour': return 'Staff Behaviour';
    default: return 'Other';
  }
}
