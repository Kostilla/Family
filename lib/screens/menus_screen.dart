import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class MenusScreen extends ConsumerStatefulWidget {
  const MenusScreen({super.key});

  @override
  ConsumerState<MenusScreen> createState() => _MenusScreenState();
}

class _MenusScreenState extends ConsumerState<MenusScreen> {
  final lunchCtrl = TextEditingController();
  final dinnerCtrl = TextEditingController();
  DateTime selectedDay = DateTime.now();
  DateTime? loadedForDay;

  @override
  void dispose() {
    lunchCtrl.dispose();
    dinnerCtrl.dispose();
    super.dispose();
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
        return StreamBuilder(
          stream: repo.meals(familyId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: const [
                  ProHeader(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Menús',
                    subtitle: 'Falta preparar la tabla meal_entries en Supabase.',
                  ),
                  SizedBox(height: 12),
                  EmptyState(
                    icon: Icons.storage_outlined,
                    title: 'Tabla de menús pendiente',
                    message: 'Ejecuta el SQL incluido en el ZIP para activar menús semanales.',
                  ),
                ],
              );
            }

            final meals = snapshot.data ?? [];
            final sameDay = meals.where((m) =>
                m.day.year == selectedDay.year &&
                m.day.month == selectedDay.month &&
                m.day.day == selectedDay.day);
            final lunch = sameDay.where((e) => e.mealType == 'lunch').toList();
            final dinner = sameDay.where((e) => e.mealType == 'dinner').toList();

            final key = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
            if (loadedForDay != key) {
              lunchCtrl.text = lunch.isEmpty ? '' : lunch.first.text;
              dinnerCtrl.text = dinner.isEmpty ? '' : dinner.first.text;
              loadedForDay = key;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                ProHeader(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Menús',
                  subtitle: DateFormat('EEEE d MMMM', 'es').format(selectedDay),
                  action: IconButton.filledTonal(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2035),
                        initialDate: selectedDay,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDay = picked;
                          loadedForDay = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  icon: Icons.lunch_dining_outlined,
                  title: 'Comida',
                  child: Column(
                    children: [
                      TextField(
                        controller: lunchCtrl,
                        decoration: const InputDecoration(labelText: 'Ej. Arroz al horno'),
                        minLines: 1,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => repo.upsertMeal(
                            familyId: familyId,
                            day: selectedDay,
                            mealType: 'lunch',
                            text: lunchCtrl.text,
                          ),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar comida'),
                        ),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  icon: Icons.dinner_dining_outlined,
                  title: 'Cena',
                  child: Column(
                    children: [
                      TextField(
                        controller: dinnerCtrl,
                        decoration: const InputDecoration(labelText: 'Ej. Tortilla y ensalada'),
                        minLines: 1,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => repo.upsertMeal(
                            familyId: familyId,
                            day: selectedDay,
                            mealType: 'dinner',
                            text: dinnerCtrl.text,
                          ),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar cena'),
                        ),
                      ),
                    ],
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
