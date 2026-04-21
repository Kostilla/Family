import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/app_providers.dart';

class MenusScreen extends ConsumerStatefulWidget {
  const MenusScreen({super.key});

  @override
  ConsumerState<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends ConsumerState<MenusScreen> {
  final lunchCtrl = TextEditingController();
  final dinnerCtrl = TextEditingController();
  DateTime selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);

    return currentFamilyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (familyId) {
        if (familyId == null) return const Center(child: Text('No hay familia activa.'));
        return StreamBuilder(
          stream: repo.meals(familyId),
          builder: (context, snapshot) {
            final meals = snapshot.data ?? [];
            final sameDay = meals.where((m) =>
                m.day.year == selectedDay.year &&
                m.day.month == selectedDay.month &&
                m.day.day == selectedDay.day);
            final lunch = sameDay.where((e) => e.mealType == 'lunch').cast().toList();
            final dinner = sameDay.where((e) => e.mealType == 'dinner').cast().toList();
            lunchCtrl.text = lunch.isEmpty ? '' : lunch.first.text;
            dinnerCtrl.text = dinner.isEmpty ? '' : dinner.first.text;

            return ListView(
              children: [
                Text('Menús', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: const Text('Día seleccionado'),
                    subtitle: Text(DateFormat('EEEE d MMMM', 'es').format(selectedDay)),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                          initialDate: selectedDay,
                        );
                        if (picked != null) {
                          setState(() => selectedDay = picked);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: lunchCtrl,
                  decoration: const InputDecoration(labelText: 'Comida'),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => repo.upsertMeal(
                    familyId: familyId,
                    day: selectedDay,
                    mealType: 'lunch',
                    text: lunchCtrl.text,
                  ),
                  child: const Text('Guardar comida'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dinnerCtrl,
                  decoration: const InputDecoration(labelText: 'Cena'),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => repo.upsertMeal(
                    familyId: familyId,
                    day: selectedDay,
                    mealType: 'dinner',
                    text: dinnerCtrl.text,
                  ),
                  child: const Text('Guardar cena'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
