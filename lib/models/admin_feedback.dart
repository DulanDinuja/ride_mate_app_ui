class AdminFeedback {
  final int id;
  final int userId;
  final String userFullName;
  final int rating;
  final String category;
  final String feedbackText;
  final String? createdDate;

  const AdminFeedback({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.rating,
    required this.category,
    required this.feedbackText,
    this.createdDate,
  });

  factory AdminFeedback.fromJson(Map<String, dynamic> json) {
    return AdminFeedback(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userFullName: json['userFullName']?.toString() ?? 'Unknown User',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'General',
      feedbackText: json['feedbackText']?.toString() ?? '-',
      createdDate: json['createdDate']?.toString(),
    );
  }
}

