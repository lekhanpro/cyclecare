import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/app_providers.dart';
import '../../../domain/engines/cycle_prediction_engine.dart';
import '../../../core/utils/date_utils.dart';

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

  @override
  Widget build(BuildContext context) {
    final cycleData = ref.watch(cycleDataProvider);
    final predictions = ref.watch(cyclePredictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CycleCare'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCycleInfoCard(context, predictions),
            _buildCalendar(context, cycleData, predictions),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _buildFabColumn(context),
    );
  }

  // ---------------------------------------------------------------------------
  // Cycle info card
  // ---------------------------------------------------------------------------
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
                    value: '${prediction.currentCycleDay}',
                    icon: Icons.today,
                    color: _primaryPink,
                  ),
                  _buildInfoTile(
                    context,
                    label: 'Next Period',
                    value: '${prediction.daysUntilNextPeriod}d',
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
                    label: 'Fertility',
                    value: prediction.fertilityStatus,
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

  // ---------------------------------------------------------------------------
  // Calendar with markers
  // ---------------------------------------------------------------------------
  Widget _buildCalendar(
    BuildContext context,
    AsyncValue<Map<DateTime, DayLog>> cycleData,
    AsyncValue<CyclePrediction> predictions,
  ) {
    final periodDays = predictions.valueOrNull?.periodDays ?? <DateTime>{};
    final ovulationDay = predictions.valueOrNull?.ovulationDay;
    final fertileDays = predictions.valueOrNull?.fertileDays ?? <DateTime>{};

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
            _showDayDetailSheet(context, selectedDay, cycleData.valueOrNull);
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
              final normalized = AppDateUtils.normalize(date);
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

  // ---------------------------------------------------------------------------
  // FAB column
  // ---------------------------------------------------------------------------
  Widget _buildFabColumn(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'logSymptom',
          onPressed: () => _onLogSymptom(context),
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

  void _onLogPeriodStart(BuildContext context) {
    final today = DateTime.now();
    ref.read(cycleDataProvider.notifier).logPeriodStart(today);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Period start logged for today')),
    );
  }

  void _onLogSymptom(BuildContext context) {
    ref.read(logSymptomProvider.notifier).openLogSheet(
          context,
          _selectedDay ?? DateTime.now(),
        );
  }

  // ---------------------------------------------------------------------------
  // Day detail bottom sheet
  // ---------------------------------------------------------------------------
  void _showDayDetailSheet(
    BuildContext context,
    DateTime day,
    Map<DateTime, DayLog>? logs,
  ) {
    final normalized = AppDateUtils.normalize(day);
    final dayLog = logs?[normalized];
    final prediction = ref.read(cyclePredictionProvider).valueOrNull;
    final isPeriodDay = prediction?.periodDays.contains(normalized) ?? false;
    final isFertile = prediction?.fertileDays.contains(normalized) ?? false;
    final isOvulation = prediction?.ovulationDay != null &&
        isSameDay(day, prediction!.ovulationDay!);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date title
                Text(
                  AppDateUtils.formatFull(day),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Status chips
                if (isPeriodDay)
                  _buildStatusRow('Period Day', _periodRed, Icons.water_drop),
                if (isOvulation)
                  _buildStatusRow(
                      'Ovulation Day', _ovulationBlue, Icons.circle),
                if (isFertile && !isOvulation)
                  _buildStatusRow('Fertile Window', _fertileGreen, Icons.eco),
                if (!isPeriodDay && !isFertile && !isOvulation)
                  _buildStatusRow('No special status', Colors.grey,
                      Icons.remove_circle_outline),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Log summary header
                Text(
                  'Log Summary',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),

                if (dayLog != null) ...[
                  if (dayLog.symptoms.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: dayLog.symptoms
                          .map((s) => Chip(
                                label:
                                    Text(s, style: const TextStyle(fontSize: 12)),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  if (dayLog.mood != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.mood,
                              size: 18, color: _primaryPink),
                          const SizedBox(width: 8),
                          Text('Mood: ${dayLog.mood}'),
                        ],
                      ),
                    ),
                  if (dayLog.notes != null && dayLog.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes,
                              size: 18, color: _primaryPink),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dayLog.notes!)),
                        ],
                      ),
                    ),
                ] else
                  Text(
                    'No logs for this day.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
