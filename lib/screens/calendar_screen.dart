import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';
import 'calendar_categories_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  List<EventModel> _forDay(List<EventModel> events, DateTime day) {
    return events
        .where((e) =>
            e.startAt.year == day.year &&
            e.startAt.month == day.month &&
            e.startAt.day == day.day)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  Map<String, CalendarCategoryModel> _categoryMap(List<CalendarCategoryModel> categories) {
    return {for (final category in categories) category.id: category};
  }

  Color _colorFromHex(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) return Theme.of(context).colorScheme.primary;
    final cleaned = value.replaceAll('#', '').trim();
    try {
      if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
      if (cleaned.length == 8) return Color(int.parse(cleaned, radix: 16));
    } catch (_) {}
    return Theme.of(context).colorScheme.primary;
  }

  Color _eventColor(EventModel event, Map<String, CalendarCategoryModel> categories, BuildContext context) {
    final category = event.categoryId == null ? null : categories[event.categoryId];
    return _colorFromHex(category?.color ?? event.color, context);
  }

  String _categoryName(EventModel event, Map<String, CalendarCategoryModel> categories) {
    final category = event.categoryId == null ? null : categories[event.categoryId];
    return category?.name ?? 'Sin categoría';
  }

  String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime _monthDelta(DateTime date, int delta) {
    return DateTime(date.year, date.month + delta, 1);
  }

  void _goToMonth(int delta) {
    setState(() {
      focusedDay = _monthDelta(focusedDay, delta);
      selectedDay = DateTime(focusedDay.year, focusedDay.month, 1);
    });
  }

  Future<void> _openDaySheet({
    required BuildContext context,
    required String familyId,
    required DateTime day,
    required List<EventModel> events,
    required List<CalendarCategoryModel> categories,
    required Map<String, CalendarCategoryModel> categoryById,
  }) async {
    final repo = ref.read(repositoriesProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.35,
            maxChildSize: 0.94,
            builder: (context, controller) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dateLabel(day),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text('${events.length} evento(s)', style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () async {
                            await _showEventEditor(
                              context: sheetContext,
                              familyId: familyId,
                              day: day,
                              categories: categories,
                              categoryById: categoryById,
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: events.isEmpty
                          ? const EmptyState(
                              icon: Icons.event_busy_outlined,
                              title: 'Sin eventos este día',
                              message: 'Pulsa Añadir para crear una cita, turno o recordatorio.',
                            )
                          : ListView.separated(
                              controller: controller,
                              itemCount: events.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final event = events[index];
                                final color = _eventColor(event, categoryById, context);
                                return Card(
                                  child: ListTile(
                                    onTap: () => _openEventActions(
                                      context: sheetContext,
                                      familyId: familyId,
                                      day: day,
                                      event: event,
                                      categories: categories,
                                      categoryById: categoryById,
                                    ),
                                    leading: Container(
                                      width: 14,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_categoryName(event, categoryById)),
                                        if (event.notes != null && event.notes!.trim().isNotEmpty) Text(event.notes!),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openEventActions({
    required BuildContext context,
    required String familyId,
    required DateTime day,
    required EventModel event,
    required List<CalendarCategoryModel> categories,
    required Map<String, CalendarCategoryModel> categoryById,
  }) async {
    final repo = ref.read(repositoriesProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final color = _eventColor(event, categoryById, context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 14, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          Text(_categoryName(event, categoryById)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (event.notes != null && event.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(event.notes!),
                ],
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar evento'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _showEventEditor(
                      context: context,
                      familyId: familyId,
                      day: day,
                      event: event,
                      categories: categories,
                      categoryById: categoryById,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  title: Text('Eliminar evento', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Eliminar evento'),
                        content: Text('¿Quieres eliminar "${event.title}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
                          FilledButton.tonal(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await repo.deleteEvent(event.id);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEventEditor({
    required BuildContext context,
    required String familyId,
    required DateTime day,
    required List<CalendarCategoryModel> categories,
    required Map<String, CalendarCategoryModel> categoryById,
    EventModel? event,
  }) async {
    final repo = ref.read(repositoriesProvider);
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final notesCtrl = TextEditingController(text: event?.notes ?? '');
    String? categoryId = event?.categoryId;
    if (categoryId != null && !categoryById.containsKey(categoryId)) categoryId = null;
    categoryId ??= categories.isEmpty ? null : categories.first.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(event == null ? 'Añadir evento' : 'Editar evento'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 10),
                    if (categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: categoryId,
                        decoration: const InputDecoration(labelText: 'Categoría'),
                        items: [
                          for (final category in categories)
                            DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: _colorFromHex(category.color, context),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) => setDialogState(() => categoryId = value),
                      )
                    else
                      const Text('Crea categorías en Ajustes para colorear los eventos.'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notas'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final start = DateTime(day.year, day.month, day.day, event?.startAt.hour ?? 10, event?.startAt.minute ?? 0);
                    final end = start.add(const Duration(hours: 1));
                    final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
                    if (event == null) {
                      await repo.addEvent(
                        familyId: familyId,
                        title: titleCtrl.text.trim(),
                        notes: notes,
                        startAt: start,
                        endAt: end,
                        categoryId: categoryId,
                      );
                    } else {
                      await repo.updateEvent(
                        id: event.id,
                        title: titleCtrl.text.trim(),
                        notes: notes,
                        startAt: start,
                        endAt: end,
                        categoryId: categoryId,
                      );
                    }
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: Text(event == null ? 'Añadir' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    titleCtrl.dispose();
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);

    return currentFamilyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (familyId) {
        if (familyId == null) return const RequireFamily();
        return StreamBuilder<List<CalendarCategoryModel>>(
          stream: repo.calendarCategories(familyId),
          builder: (context, categorySnapshot) {
            final categories = categorySnapshot.data ?? [];
            final categoryById = _categoryMap(categories);

            return StreamBuilder<List<EventModel>>(
              stream: repo.events(familyId),
              builder: (context, snapshot) {
                final events = snapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    ProHeader(
                      icon: Icons.calendar_month_outlined,
                      title: 'Calendario',
                      subtitle: '${events.length} evento(s) familiares',
                      action: IconButton.filledTonal(
                        tooltip: 'Categorías',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CalendarCategoriesScreenEntry()),
                        ),
                        icon: const Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: TableCalendar<EventModel>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2035, 12, 31),
                          focusedDay: focusedDay,
                          selectedDayPredicate: (d) =>
                              d.year == selectedDay.year && d.month == selectedDay.month && d.day == selectedDay.day,
                          eventLoader: (day) => _forDay(events, day),
                          availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
                          availableGestures: AvailableGestures.horizontalSwipe,
                          pageJumpingEnabled: true,
                          calendarStyle: CalendarStyle(
                            markersMaxCount: 0,
                            todayDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders<EventModel>(
                            markerBuilder: (context, day, dayEvents) {
                              if (dayEvents.isEmpty) return null;
                              final visible = dayEvents.take(4).toList();
                              return Positioned(
                                bottom: 5,
                                left: 6,
                                right: 6,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final event in visible)
                                      Container(
                                        width: 7,
                                        height: 7,
                                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                        decoration: BoxDecoration(
                                          color: _eventColor(event, categoryById, context),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (dayEvents.length > visible.length)
                                      Text(
                                        '+',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          onDaySelected: (selected, focused) {
                            final dayEvents = _forDay(events, selected);
                            setState(() {
                              selectedDay = selected;
                              focusedDay = focused;
                            });
                            _openDaySheet(
                              context: context,
                              familyId: familyId,
                              day: selected,
                              events: dayEvents,
                              categories: categories,
                              categoryById: categoryById,
                            );
                          },
                          onPageChanged: (focused) {
                            setState(() {
                              focusedDay = DateTime(focused.year, focused.month, 1);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class CalendarCategoriesScreenEntry extends StatelessWidget {
  const CalendarCategoriesScreenEntry({super.key});

  @override
  Widget build(BuildContext context) => const CalendarCategoriesScreen();
}
