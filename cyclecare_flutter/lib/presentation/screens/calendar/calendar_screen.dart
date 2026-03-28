import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/app_providers.dart';
import '../../../domain/engines/cycle_prediction_engine.dart';
import '../../../data/database/app_database.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _periodRed = Color(0xFFE53935);
  static const Color _ovulationBlue = Color(0xFF1E88E5);
  static const Color _fertileGreen = Color(0xFF43A047);

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(periodsProvider);
    final prediction = ref.watch(cyclePredictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CycleCare'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCycleInfoCard(context, prediction),
            _buildCalendar(context, periodsAsync, prediction),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _buildFabColumn(context),
    );
  }

  Widget _buildCycleInfoCard(
    BuildContext context,
    AsyncValue<CyclePrediction> predictions,
  ) {
    return predictions.when(
      data: (prediction) => Card(
        margin: const EdgeInsets.all(16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _primaryPink.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Cycle Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _primaryPink,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoTile(
                    context,
                    label: 'Cycle Day',
                    value: '${prediction.cycleDay}',
                    icon: Icons.today,
                    color: _primaryPink,
                  ),
                  _buildInfoTile(
                    context,
                    label: 'Next Period',
                    value: '${prediction.daysUntilPeriod}d',
                    icon: Icons.schedule,
                    color: _periodRed,
                  ),
                  _buildInfoTile(
                    context,
                    label: 'Phase',
                    value: prediction.currentPhase,
                    icon: Icons.loop,
                    color: _ovulationBlue,
                  ),
                  _buildInfoTile(
                    context,
                    label: 'Confidence',
                    value: '${(prediction.confidenceScore * 100).round()}%',
                    icon: Icons.favorite,
                    color: _fertileGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No cycle data yet. Start logging to see predictions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    AsyncValue<List<PeriodRecord>> periodsAsync,
    AsyncValue<CyclePrediction> predictionAsync,
  ) {
    final prediction = predictionAsync.valueOrNull;
    final periods = periodsAsync.valueOrNull ?? [];

    // Build period day set from actual records
    final periodDays = <DateTime>{};
    for (final p in periods) {
      final end = p.endDate ?? p.startDate.add(const Duration(days: 4));
      for (var d = p.startDate; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        periodDays.add(_normalize(d));
      }
    }

    // Build fertile window set from prediction
    final fertileDays = <DateTime>{};
    DateTime? ovulationDay;
    if (prediction != null) {
      ovulationDay = prediction.ovulationDate;
      for (var d = prediction.fertileWindowStart;
          !d.isAfter(prediction.fertileWindowEnd);
          d = d.add(const Duration(days: 1))) {
        fertileDays.add(_normalize(d));
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<dynamic>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: _primaryPink.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: _primaryPink,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: _primaryPink),
              borderRadius: BorderRadius.circular(20),
            ),
            formatButtonTextStyle: const TextStyle(
              color: _primaryPink,
              fontSize: 13,
            ),
          ),
          calendarBuilders: CalendarBuilders<dynamic>(
            markerBuilder: (context, date, events) {
              final normalized = _normalize(date);
              final markers = <Widget>[];

              if (periodDays.contains(normalized)) {
                markers.add(_buildMarker(_periodRed));
              }
              if (ovulationDay != null && isSameDay(date, ovulationDay)) {
                markers.add(
                  _buildMarker(_ovulationBlue, isOutlined: true),
                );
              } else if (fertileDays.contains(normalized)) {
                markers.add(_buildMarker(_fertileGreen));
              }

              if (markers.isEmpty) return const SizedBox.shrink();

              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: markers,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMarker(Color color, {bool isOutlined = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: isOutlined ? 8 : 6,
      height: isOutlined ? 8 : 6,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: isOutlined ? 2 : 0),
      ),
    );
  }

  Widget _buildFabColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'logSymptom',
          onPressed: () => Navigator.pushNamed(context, '/daily-log'),
          backgroundColor: _primaryPink.withOpacity(0.85),
          child: const Icon(Icons.edit_note, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'logPeriod',
          onPressed: () => _onLogPeriodStart(context),
          backgroundColor: _primaryPink,
          icon: const Icon(Icons.water_drop, color: Colors.white),
          label: const Text(
            'Log Period',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _onLogPeriodStart(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now();
    await db.insertPeriod(
      startDate: DateTime(today.year, today.month, today.day),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period start logged for today')),
      );
    }
  }
}
