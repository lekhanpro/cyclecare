import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/cyclecare_theme.dart';
import 'domain/partner_share_code.dart';

class SharedPartnerEvent {
  const SharedPartnerEvent(
    this.title,
    this.start,
    this.end, {
    this.estimated = true,
  });
  final String title;
  final DateTime start, end;
  final bool estimated;
  bool on(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
        !d.isAfter(DateTime(end.year, end.month, end.day));
  }
}

List<SharedPartnerEvent> partnerEvents(PartnerSnapshot snapshot) => [
  if (snapshot.nextPeriod != null)
    SharedPartnerEvent(
      'Period estimate',
      snapshot.nextPeriod!,
      snapshot.nextPeriod!,
    ),
  if (snapshot.fertileStart != null && snapshot.fertileEnd != null)
    SharedPartnerEvent(
      'Fertile-window estimate',
      snapshot.fertileStart!,
      snapshot.fertileEnd!,
    ),
  if (snapshot.ovulation != null)
    SharedPartnerEvent(
      'Ovulation estimate',
      snapshot.ovulation!,
      snapshot.ovulation!,
    ),
  if (snapshot.pmsStart != null && snapshot.pmsEnd != null)
    SharedPartnerEvent(
      'PMS-window estimate',
      snapshot.pmsStart!,
      snapshot.pmsEnd!,
    ),
];

class PartnerCalendar extends StatefulWidget {
  const PartnerCalendar({super.key, required this.snapshot});
  final PartnerSnapshot snapshot;
  @override
  State<PartnerCalendar> createState() => _PartnerCalendarState();
}

class _PartnerCalendarState extends State<PartnerCalendar> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final events = partnerEvents(widget.snapshot);
    final first = DateTime(_month.year, _month.month, 1);
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final offset = first.weekday % 7;
    final dayEvents = events.where((e) => e.on(_selected)).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Shared calendar',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(_month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final label in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(
                child: ExcludeSemantics(
                  child: Text(label, textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final cellHeight = MediaQuery.textScalerOf(context).scale(14) > 22
                ? 64.0
                : 52.0;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: cellHeight,
              ),
              itemCount: offset + count,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox();
                final day = DateTime(
                  _month.year,
                  _month.month,
                  index - offset + 1,
                );
                final marked = events.any((e) => e.on(day));
                final selected = DateUtils.isSameDay(day, _selected);
                return Semantics(
                  selected: selected,
                  label: DateFormat('EEEE d MMMM').format(day),
                  button: true,
                  child: InkWell(
                    onTap: () => setState(() => _selected = day),
                    borderRadius: BorderRadius.circular(14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${day.day}'),
                          if (marked) const Icon(Icons.circle, size: 5),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          DateFormat('EEE d MMM').format(_selected),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (dayEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No shared event for this date.'),
          ),
        for (final event in dayEvents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(AppIcons.calendarRange),
            title: Text(event.title),
            subtitle: const Text('Shared estimate'),
          ),
        if (events.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Upcoming shared dates'),
            children: [
              for (final event in events)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(event.title),
                  subtitle: Text(
                    '${DateFormat('d MMM').format(event.start)}${DateUtils.isSameDay(event.start, event.end) ? '' : ' – ${DateFormat('d MMM').format(event.end)}'}',
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        const Text(
          'These are the dates shared in the latest update. An estimate is not a recorded period or confirmation of ovulation.',
        ),
      ],
    );
  }
}
