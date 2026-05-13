import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class SmartMenusScreen extends ConsumerStatefulWidget {
  const SmartMenusScreen({super.key});

  @override
  ConsumerState<SmartMenusScreen> createState() => _SmartMenusScreenState();
}

class _SmartMenusScreenState extends ConsumerState<SmartMenusScreen> {
  DateTime selectedDay = DateTime.now();
  String mealSlot = 'lunch';
  String? selectedMenuId;

  String _dayLabel(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (d == todayOnly) return 'Hoy';
    if (d == todayOnly.add(const Duration(days: 1))) return 'Mañana';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  DateTime _dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);

    return familyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (familyId) {
        if (familyId == null) return const RequireFamily();

        return StreamBuilder<List<SmartMenuModel>>(
          stream: repo.smartMenus(familyId),
          builder: (context, menusSnapshot) {
            final menus = menusSnapshot.data ?? const <SmartMenuModel>[];
            final validSelected = menus.any((menu) => menu.id == selectedMenuId);
            if (!validSelected && menus.isNotEmpty) selectedMenuId = menus.first.id;

            return StreamBuilder<List<SmartDailyMenuModel>>(
              stream: repo.smartDailyMenus(familyId),
              builder: (context, dailySnapshot) {
                final dailyMenus = dailySnapshot.data ?? const <SmartDailyMenuModel>[];
                final pendingDays = _pendingDays(dailyMenus);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    ProHeader(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Menús con compra',
                      subtitle: 'Recetas predeterminadas, planificación y compra automática.',
                      action: IconButton.filledTonal(
                        tooltip: 'Crear menú predeterminado',
                        onPressed: () => _openMenuEditor(familyId: familyId),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      icon: Icons.bookmark_add_rounded,
                      title: 'Planificar día',
                      subtitle: 'Elige un menú predeterminado para comida o cena.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDay,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 730)),
                                    );
                                    if (picked != null) setState(() => selectedDay = picked);
                                  },
                                  icon: const Icon(Icons.calendar_month_rounded),
                                  label: Text(_dayLabel(selectedDay)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: mealSlot,
                                  decoration: const InputDecoration(labelText: 'Momento'),
                                  items: const [
                                    DropdownMenuItem(value: 'lunch', child: Text('Comida')),
                                    DropdownMenuItem(value: 'dinner', child: Text('Cena')),
                                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                                  ],
                                  onChanged: (value) => setState(() => mealSlot = value ?? 'lunch'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (menus.isEmpty)
                            EmptyState(
                              icon: Icons.restaurant_menu_outlined,
                              title: 'Aún no tienes menús predeterminados',
                              message: 'Crea uno con sus ingredientes para poder añadirlo a tus días.',
                              buttonText: 'Crear menú predeterminado',
                              onPressed: () => _openMenuEditor(familyId: familyId),
                            )
                          else ...[
                            DropdownButtonFormField<String>(
                              value: selectedMenuId,
                              decoration: const InputDecoration(labelText: 'Menú predeterminado'),
                              items: [
                                for (final menu in menus)
                                  DropdownMenuItem(
                                    value: menu.id,
                                    child: Text(menu.name),
                                  ),
                              ],
                              onChanged: (value) => setState(() => selectedMenuId = value),
                            ),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              onPressed: selectedMenuId == null
                                  ? null
                                  : () async {
                                      await repo.assignSmartDailyMenu(
                                        familyId: familyId,
                                        day: selectedDay,
                                        mealSlot: mealSlot,
                                        smartMenuId: selectedMenuId!,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Menú añadido al día. Queda pendiente de confirmar compra.')),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.add_task_rounded),
                              label: const Text('Añadir al día'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      icon: Icons.fact_check_rounded,
                      title: 'Pendientes de confirmar compra',
                      subtitle: 'Cuando confirmes un día, desaparecerá de esta lista.',
                      child: pendingDays.isEmpty
                          ? const EmptyState(
                              icon: Icons.check_circle_outline_rounded,
                              title: 'No hay días pendientes',
                              message: 'Los días confirmados no se muestran aquí.',
                            )
                          : Column(
                              children: [
                                for (final day in pendingDays)
                                  _PendingDayTile(
                                    day: day,
                                    items: dailyMenus.where((item) => _dateOnly(item.menuDate) == day && !item.shoppingConfirmed).toList(),
                                    onConfirm: () => _confirmDay(familyId, day, dailyMenus),
                                  ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    SectionCard(
                      icon: Icons.restaurant_rounded,
                      title: 'Menús predeterminados',
                      subtitle: 'Crea, edita o elimina tus recetas base.',
                      child: menus.isEmpty
                          ? EmptyState(
                              icon: Icons.restaurant_menu_outlined,
                              title: 'Sin menús guardados',
                              message: 'Guarda platos frecuentes y luego úsalos en tus menús diarios.',
                              buttonText: 'Crear menú',
                              onPressed: () => _openMenuEditor(familyId: familyId),
                            )
                          : Column(
                              children: [
                                for (final menu in menus)
                                  GlassPanel(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const Icon(Icons.restaurant_menu_rounded),
                                      title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      subtitle: Text('${_mealTypeLabel(menu.mealType)} · ${menu.ingredients.length} ingrediente(s)'),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') _openMenuEditor(familyId: familyId, menu: menu);
                                          if (value == 'delete') _deleteMenu(menu);
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                                          PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                        ],
                                      ),
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
      },
    );
  }

  List<DateTime> _pendingDays(List<SmartDailyMenuModel> dailyMenus) {
    final days = <DateTime>{};
    for (final item in dailyMenus) {
      if (!item.shoppingConfirmed) days.add(_dateOnly(item.menuDate));
    }
    final sorted = days.toList()..sort();
    return sorted;
  }

  String _mealTypeLabel(String type) {
    switch (type) {
      case 'lunch':
        return 'Comida';
      case 'dinner':
        return 'Cena';
      default:
        return 'Otro';
    }
  }

  Future<void> _openMenuEditor({required String familyId, SmartMenuModel? menu}) async {
    final nameCtrl = TextEditingController(text: menu?.name ?? '');
    final notesCtrl = TextEditingController(text: menu?.notes ?? '');
    var type = menu?.mealType ?? 'lunch';
    final ingredientCtrls = <TextEditingController>[
      if (menu != null && menu.ingredients.isNotEmpty)
        for (final ingredient in menu.ingredients) TextEditingController(text: ingredient.name)
      else
        TextEditingController(),
    ];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(menu == null ? 'Crear menú predeterminado' : 'Editar menú', style: Theme.of(context).textTheme.titleLarge),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalContext).pop(false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre del menú'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: const [
                        DropdownMenuItem(value: 'lunch', child: Text('Comida')),
                        DropdownMenuItem(value: 'dinner', child: Text('Cena')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) => setModalState(() => type = value ?? 'lunch'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Notas'),
                    ),
                    const SizedBox(height: 16),
                    Text('Ingredientes', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var i = 0; i < ingredientCtrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ingredientCtrls[i],
                                decoration: InputDecoration(labelText: 'Ingrediente ${i + 1}'),
                              ),
                            ),
                            IconButton(
                              onPressed: ingredientCtrls.length == 1
                                  ? null
                                  : () => setModalState(() => ingredientCtrls.removeAt(i)),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => setModalState(() => ingredientCtrls.add(TextEditingController())),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir ingrediente'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final repo = ref.read(repositoriesProvider);
                          await repo.upsertSmartMenu(
                            id: menu?.id,
                            familyId: familyId,
                            name: nameCtrl.text,
                            mealType: type,
                            notes: notesCtrl.text,
                            ingredients: ingredientCtrls.map((c) => c.text).toList(),
                          );
                          if (mounted) Navigator.of(modalContext).pop(true);
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: Text(menu == null ? 'Crear menú' : 'Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    for (final controller in ingredientCtrls) {
      controller.dispose();
    }
    nameCtrl.dispose();
    notesCtrl.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menú guardado')));
    }
  }

  Future<void> _deleteMenu(SmartMenuModel menu) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar menú'),
        content: Text('¿Quieres eliminar "${menu.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) await ref.read(repositoriesProvider).deleteSmartMenu(menu.id);
  }

  Future<void> _confirmDay(String familyId, DateTime day, List<SmartDailyMenuModel> dailyMenus) async {
    final dayItems = dailyMenus.where((item) => _dateOnly(item.menuDate) == day && !item.shoppingConfirmed).toList();
    final ingredientsByKey = <String, String>{};
    for (final item in dayItems) {
      for (final ingredient in item.menu?.ingredients ?? const <SmartMenuIngredientModel>[]) {
        final name = ingredient.name.trim();
        if (name.isEmpty) continue;
        ingredientsByKey.putIfAbsent(name.toLowerCase(), () => ingredient.displayName);
      }
    }
    final ingredients = ingredientsByKey.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    if (ingredients.isEmpty) {
      await ref.read(repositoriesProvider).confirmSmartDailyShopping(familyId: familyId, day: day, selectedIngredients: const []);
      return;
    }

    final selected = <String>{...ingredients};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Confirmar compra de ${_dayLabel(day)}', style: Theme.of(context).textTheme.titleLarge)),
                    IconButton(onPressed: () => Navigator.of(modalContext).pop(false), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Desmarca lo que ya tienes en casa. Los repetidos aparecen una sola vez.'),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final ingredient in ingredients)
                        CheckboxListTile(
                          value: selected.contains(ingredient),
                          onChanged: (value) => setModalState(() {
                            if (value == true) {
                              selected.add(ingredient);
                            } else {
                              selected.remove(ingredient);
                            }
                          }),
                          title: Text(ingredient),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(modalContext).pop(true),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: const Text('Añadir seleccionados a compra'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (ok == true) {
      await ref.read(repositoriesProvider).confirmSmartDailyShopping(
        familyId: familyId,
        day: day,
        selectedIngredients: selected.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingredientes añadidos a compra')));
      }
    }
  }
}

class _PendingDayTile extends StatelessWidget {
  const _PendingDayTile({
    required this.day,
    required this.items,
    required this.onConfirm,
  });

  final DateTime day;
  final List<SmartDailyMenuModel> items;
  final VoidCallback onConfirm;

  String _dayLabel(DateTime day) => '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year}';

  String _slotLabel(String slot) {
    switch (slot) {
      case 'lunch':
        return 'Comida';
      case 'dinner':
        return 'Cena';
      default:
        return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_dayLabel(day), style: Theme.of(context).textTheme.titleMedium),
                ),
                FilledButton.tonalIcon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirmar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${_slotLabel(item.mealSlot)}: ${item.menu?.name ?? 'Menú'}'),
              ),
          ],
        ),
      ),
    );
  }
}
