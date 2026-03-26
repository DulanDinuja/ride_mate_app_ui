class AdminReport {
  final int id;
  final int userId;
  final String userFullName;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String? createdDate;

  const AdminReport({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    this.createdDate,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    return AdminReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      userFullName: json['userFullName']?.toString() ?? 'Unknown User',
      category: json['category']?.toString() ?? 'N/A',
      subject: json['subject']?.toString() ?? '-',
      description: json['description']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'PENDING',
      createdDate: json['createdDate']?.toString(),
    );
  }

  AdminReport copyWith({
    String? status,
  }) {
    return AdminReport(
      id: id,
      userId: userId,
      userFullName: userFullName,
      category: category,
      subject: subject,
      description: description,
      status: status ?? this.status,
      createdDate: createdDate,
    );
  }
}

