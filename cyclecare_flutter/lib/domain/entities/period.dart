import 'package:flutter/foundation.dart';

@immutable
class Period {
  final int id;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> symptoms;
  final String? notes;

  const Period({
    required this.id,
    required this.startDate,
    this.endDate,
    this.symptoms = const [],
    this.notes,
  });

  Period copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? symptoms,
    String? notes,
  }) {
    return Period(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'symptoms': symptoms,
      'notes': notes,
    };
  }

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      id: json['id'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      symptoms: (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }
}
