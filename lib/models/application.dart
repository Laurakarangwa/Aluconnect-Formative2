class ApplicationModel {
  final String id;
  final String opportunityId;
  final String startupId;
  final String studentId;
  final String studentName;
  final String faculty;
  final String intakeYear;
  final String schoolEmail;
  final String phoneNumber;
  final String? coverLetterUrl;
  final String? cvUrl;
  final String status;
  final DateTime appliedAt;

  const ApplicationModel({
    required this.id,
    required this.opportunityId,
    required this.startupId,
    required this.studentId,
    required this.studentName,
    required this.faculty,
    required this.intakeYear,
    required this.schoolEmail,
    required this.phoneNumber,
    this.coverLetterUrl,
    this.cvUrl,
    this.status = 'pending',
    required this.appliedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opportunityId': opportunityId,
      'startupId': startupId,
      'studentId': studentId,
      'studentName': studentName,
      'faculty': faculty,
      'intakeYear': intakeYear,
      'schoolEmail': schoolEmail,
      'phoneNumber': phoneNumber,
      'coverLetterUrl': coverLetterUrl,
      'cvUrl': cvUrl,
      'status': status,
      'appliedAt': appliedAt.toIso8601String(),
    };
  }

  factory ApplicationModel.fromMap(Map<String, dynamic> map) {
    return ApplicationModel(
      id: map['id'] as String,
      opportunityId: map['opportunityId'] as String,
      startupId: map['startupId'] as String? ?? 'demo-startup',
      studentId: map['studentId'] as String,
      studentName: map['studentName'] as String,
      faculty: map['faculty'] as String,
      intakeYear: map['intakeYear'] as String,
      schoolEmail: map['schoolEmail'] as String,
      phoneNumber: map['phoneNumber'] as String,
      coverLetterUrl: map['coverLetterUrl'] as String?,
      cvUrl: map['cvUrl'] as String?,
      status: map['status'] as String? ?? 'pending',
      appliedAt: DateTime.parse(map['appliedAt'] as String),
    );
  }

  ApplicationModel copyWith({
    String? id,
    String? opportunityId,
    String? startupId,
    String? studentId,
    String? studentName,
    String? faculty,
    String? intakeYear,
    String? schoolEmail,
    String? phoneNumber,
    String? coverLetterUrl,
    String? cvUrl,
    String? status,
    DateTime? appliedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      opportunityId: opportunityId ?? this.opportunityId,
      startupId: startupId ?? this.startupId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      faculty: faculty ?? this.faculty,
      intakeYear: intakeYear ?? this.intakeYear,
      schoolEmail: schoolEmail ?? this.schoolEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      coverLetterUrl: coverLetterUrl ?? this.coverLetterUrl,
      cvUrl: cvUrl ?? this.cvUrl,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
