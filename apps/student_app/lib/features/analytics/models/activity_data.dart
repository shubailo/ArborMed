class ActivityData {
  final DateTime date;
  final String? calendarDate;
  final String? dayLabel;
  final int count;
  final int correctCount;

  ActivityData(
      {required this.date,
      this.dayLabel,
      this.calendarDate,
      required this.count,
      required this.correctCount});

  DateTime get calendarDay {
    final day = DateTime.tryParse(calendarDate ?? '') ?? date.toLocal();
    return DateTime(day.year, day.month, day.day);
  }

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    return ActivityData(
      date: DateTime.parse(json['date']),
      dayLabel: json['day_label'],
      calendarDate: json['calendar_date'],
      count: int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      correctCount: int.tryParse(json['correct_count']?.toString() ?? '0') ?? 0,
    );
  }
}
