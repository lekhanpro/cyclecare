import 'package:freezed_annotation/freezed_annotation.dart';

part 'period.freezed.dart';
part 'period.g.dart';

@freezed
class Period with _$Period {
  const factory Period({
    required int id,
    required DateTime startDate,
    DateTime? endDate,
    @Default([]) List<String> symptoms,
    String? notes,
  }) = _Period;

  factory Period.fromJson(Map<String, dynamic> json) => _$PeriodFromJson(json);
}
