import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  final titleCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  List<EventModel> _forDay(List<EventModel> events, DateTime day) {
    return events.where((e) =>
        e.startAt.year == day.year &&
        e.startAt.month == day.month &&
        e.startAt.day == day.day).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);

    return currentFamilyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (familyId) {
        if (familyId == null) return const Center(child: Text('No hay familia activa.'));
        return StreamBuilder<List<EventModel>>(
          stream: repo.events(familyId),
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];
            final dayEvents = _forDay(events, selectedDay);

            return ListView(
              children: [
                Text('Calendario', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                TableCalendar<EventModel>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (d) =>
                      d.year == selectedDay.year &&
                      d.month == selectedDay.month &&
                      d.day == selectedDay.day,
                  eventLoader: (day) => _forDay(events, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Nuevo evento'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notas'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final start = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                      10,
                      0,
                    );
                    final end = start.add(const Duration(hours: 1));
                    await repo.addEvent(
                      familyId: familyId,
                      title: titleCtrl.text,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text,
                      startAt: start,
                      endAt: end,
                    );
                    titleCtrl.clear();
                    notesCtrl.clear();
                  },
                  child: const Text('Añadir evento'),
                ),
                const SizedBox(height: 12),
                ...dayEvents.map(
                  (event) => Card(
                    child: ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.notes ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => repo.deleteEvent(event.id),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
