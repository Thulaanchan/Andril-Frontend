import 'package:flutter/foundation.dart';

/// Status lifecycle for a classroom admission request.
enum ClassroomJoinRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

/// Domain entity representing a learner's request to join a restricted classroom.
///
/// Follows CF-06 / CF-07 M5 contract specification Op 5 & Op 6.
@immutable
class ClassroomJoinRequest {
  /// Unique request identifier.
  final String requestId;

  /// Classroom identifier to join.
  final String classroomId;

  /// Profile identifier of the applicant.
  final String applicantProfileId;

  /// Optional introductory note or statement of interest.
  final String? note;

  /// Current status of the request.
  final ClassroomJoinRequestStatus status;

  /// Timestamp when the request was submitted.
  final DateTime requestedAt;

  const ClassroomJoinRequest._({
    required this.requestId,
    required this.classroomId,
    required this.applicantProfileId,
    this.note,
    required this.status,
    required this.requestedAt,
  });

  /// Factory constructor validating request invariants.
  factory ClassroomJoinRequest.create({
    required String requestId,
    required String classroomId,
    required String applicantProfileId,
    String? note,
    ClassroomJoinRequestStatus status = ClassroomJoinRequestStatus.pending,
    DateTime? requestedAt,
  }) {
    final cleanReqId = requestId.trim();
    if (cleanReqId.isEmpty) {
      throw ArgumentError.value(
          requestId, 'requestId', 'A request ID is required.');
    }
    final cleanClassroomId = classroomId.trim();
    if (cleanClassroomId.isEmpty) {
      throw ArgumentError.value(
          classroomId, 'classroomId', 'A classroom ID is required.');
    }
    final cleanApplicantId = applicantProfileId.trim();
    if (cleanApplicantId.isEmpty) {
      throw ArgumentError.value(
        applicantProfileId,
        'applicantProfileId',
        'An applicant profile ID is required.',
      );
    }

    return ClassroomJoinRequest._(
      requestId: cleanReqId,
      classroomId: cleanClassroomId,
      applicantProfileId: cleanApplicantId,
      note: note?.trim(),
      status: status,
      requestedAt: requestedAt ?? DateTime.now(),
    );
  }

  /// Cancels a pending join request.
  ClassroomJoinRequest cancel() {
    if (status != ClassroomJoinRequestStatus.pending) {
      throw StateError('Only pending requests can be cancelled.');
    }
    return ClassroomJoinRequest._(
      requestId: requestId,
      classroomId: classroomId,
      applicantProfileId: applicantProfileId,
      note: note,
      status: ClassroomJoinRequestStatus.cancelled,
      requestedAt: requestedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassroomJoinRequest &&
        other.requestId == requestId &&
        other.classroomId == classroomId &&
        other.applicantProfileId == applicantProfileId &&
        other.status == status;
  }

  @override
  int get hashCode =>
      Object.hash(requestId, classroomId, applicantProfileId, status);

  @override
  String toString() {
    return 'ClassroomJoinRequest(requestId: $requestId, status: $status)';
  }
}
