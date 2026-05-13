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

  DateTime _dateOnly(DateTime day) => DateTime(day.year, day.month, day.day);

  String _dayLabel(DateTime day) {
    final d = _dateOnly(day);
    final today = _dateOnly(DateTime.now());
    if (d == today) return 'Hoy';
    if (d == today.add(const Duration(days: 1))) return 'Mañana';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _fullDayLabel(DateTime day) {
    const names = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return '${names[day.weekday - 1]} ${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}';
  }

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

  int _slotRank(String slot) {
    switch (slot) {
      case 'lunch':
        return 0;
      case 'dinner':
        return 1;
      default:
        return 2;
    }
  }

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
            final selectedStillExists = menus.any((menu) => menu.id == selectedMenuId);
            if (!selectedStillExists && menus.isNotEmpty) selectedMenuId = menus.first.id;

            return StreamBuilder<List<SmartDailyMenuModel>>(
              stream: repo.smartDailyMenus(familyId),
              builder: (context, dailySnapshot) {
                final dailyMenus = dailySnapshot.data ?? const <SmartDailyMenuModel>[];
                final pendingDays = _pendingDays(dailyMenus);
                final selectedDayItems = _itemsForDay(dailyMenus, selectedDay);
                final weekDays = List.generate(7, (i) => _startOfWeek(selectedDay).add(Duration(days: i)));

                return DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: ProHeader(
                          icon: Icons.restaurant_menu_rounded,
                          title: 'Menús con compra',
                          subtitle: 'Planifica por día, revisa la semana y gestiona tus plantillas sin saturar la pantalla.',
                          action: IconButton.filledTonal(
                            tooltip: 'Crear plantilla',
                            onPressed: () => _openMenuEditor(familyId: familyId),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GlassPanel(
                          padding: const EdgeInsets.all(6),
                          radius: 22,
                          child: const TabBar(
                            tabs: [
                              Tab(icon: Icon(Icons.today_rounded), text: 'Día'),
                              Tab(icon: Icon(Icons.view_week_rounded), text: 'Semana'),
                              Tab(icon: Icon(Icons.bookmark_rounded), text: 'Plantillas'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _DayTab(
                              familyId: familyId,
                              selectedDay: selectedDay,
                              menus: menus,
                              dailyItems: selectedDayItems,
                              mealSlot: mealSlot,
                              selectedMenuId: selectedMenuId,
                              dayLabel: _dayLabel,
                              slotLabel: _slotLabel,
                              slotRank: _slotRank,
                              onPickDay: _pickSelectedDay,
                              onMealSlotChanged: (value) => setState(() => mealSlot = value),
                              onMenuChanged: (value) => setState(() => selectedMenuId = value),
                              onCreateTemplate: () => _openMenuEditor(familyId: familyId),
                              onAssign: selectedMenuId == null
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
                                          const SnackBar(content: Text('Menú asignado. Queda pendiente si no has confirmado la compra.')),
                                        );
                                      }
                                    },
                              onConfirm: selectedDayItems.any((item) => !item.shoppingConfirmed)
                                  ? () => _confirmDay(familyId, selectedDay, dailyMenus)
                                  : null,
                            ),
                            _WeekTab(
                              days: weekDays,
                              dailyMenus: dailyMenus,
                              pendingDays: pendingDays,
                              fullDayLabel: _fullDayLabel,
                              slotLabel: _slotLabel,
                              slotRank: _slotRank,
                              itemsForDay: _itemsForDay,
                              onSelectDay: (day) {
                                setState(() => selectedDay = day);
                                DefaultTabController.of(context).animateTo(0);
                              },
                              onConfirmDay: (day) => _confirmDay(familyId, day, dailyMenus),
                            ),
                            _TemplatesTab(
                              menus: menus,
                              mealTypeLabel: _slotLabel,
                              onCreate: () => _openMenuEditor(familyId: familyId),
                              onEdit: (menu) => _openMenuEditor(familyId: familyId, menu: menu),
                              onDelete: _deleteMenu,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickSelectedDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => selectedDay = picked);
  }

  DateTime _startOfWeek(DateTime day) {
    final d = _dateOnly(day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<SmartDailyMenuModel> _itemsForDay(List<SmartDailyMenuModel> dailyMenus, DateTime day) {
    final items = dailyMenus.where((item) => _dateOnly(item.menuDate) == _dateOnly(day)).toList();
    items.sort((a, b) => _slotRank(a.mealSlot).compareTo(_slotRank(b.mealSlot)));
    return items;
  }

  List<DateTime> _pendingDays(List<SmartDailyMenuModel> dailyMenus) {
    final days = <DateTime>{};
    for (final item in dailyMenus) {
      if (!item.shoppingConfirmed) days.add(_dateOnly(item.menuDate));
    }
    final sorted = days.toList()..sort();
    return sorted;
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
                          child: Text(menu == null ? 'Crear plantilla de menú' : 'Editar plantilla', style: Theme.of(context).textTheme.titleLarge),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(modalContext).pop(false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del menú')),
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
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notas')),
                    const SizedBox(height: 18),
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
                              onPressed: ingredientCtrls.length == 1 ? null : () => setModalState(() => ingredientCtrls.removeAt(i)),
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
                          await ref.read(repositoriesProvider).upsertSmartMenu(
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
                        label: Text(menu == null ? 'Crear plantilla' : 'Guardar cambios'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plantilla guardada')));
    }
  }

  Future<void> _deleteMenu(SmartMenuModel menu) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text('¿Quieres eliminar "${menu.name}"? También se quitará de los días donde esté asignada.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) await ref.read(repositoriesProvider).deleteSmartMenu(menu.id);
  }

  Future<void> _confirmDay(String familyId, DateTime day, List<SmartDailyMenuModel> dailyMenus) async {
    final dayItems = dailyMenus.where((item) => _dateOnly(item.menuDate) == _dateOnly(day) && !item.shoppingConfirmed).toList();
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

class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.familyId,
    required this.selectedDay,
    required this.menus,
    required this.dailyItems,
    required this.mealSlot,
    required this.selectedMenuId,
    required this.dayLabel,
    required this.slotLabel,
    required this.slotRank,
    required this.onPickDay,
    required this.onMealSlotChanged,
    required this.onMenuChanged,
    required this.onCreateTemplate,
    required this.onAssign,
    required this.onConfirm,
  });

  final String familyId;
  final DateTime selectedDay;
  final List<SmartMenuModel> menus;
  final List<SmartDailyMenuModel> dailyItems;
  final String mealSlot;
  final String? selectedMenuId;
  final String Function(DateTime) dayLabel;
  final String Function(String) slotLabel;
  final int Function(String) slotRank;
  final VoidCallback onPickDay;
  final ValueChanged<String> onMealSlotChanged;
  final ValueChanged<String?> onMenuChanged;
  final VoidCallback onCreateTemplate;
  final VoidCallback? onAssign;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final sortedItems = [...dailyItems]..sort((a, b) => slotRank(a.mealSlot).compareTo(slotRank(b.mealSlot)));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionCard(
          icon: Icons.today_rounded,
          title: 'Día',
          subtitle: 'Consulta y asigna menús para cualquier día.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: onPickDay,
                icon: const Icon(Icons.event_rounded),
                label: Text(dayLabel(selectedDay)),
              ),
              const SizedBox(height: 12),
              if (sortedItems.isEmpty)
                const EmptyState(
                  icon: Icons.no_meals_rounded,
                  title: 'No hay menús asignados',
                  message: 'Asigna comida o cena abajo para este día.',
                )
              else
                GlassPanel(
                  padding: const EdgeInsets.all(14),
                  radius: 22,
                  child: Column(
                    children: [
                      for (final item in sortedItems)
                        _CompactAssignedMenuRow(slot: slotLabel(item.mealSlot), item: item),
                      if (onConfirm != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: onConfirm,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Confirmar ingredientes para compra'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.add_task_rounded,
          title: 'Asignar menú',
          subtitle: 'Elige momento y plantilla. La compra queda pendiente hasta confirmar.',
          child: menus.isEmpty
              ? EmptyState(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Aún no tienes plantillas',
                  message: 'Crea menús predeterminados con ingredientes para usarlos aquí.',
                  buttonText: 'Crear plantilla',
                  onPressed: onCreateTemplate,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      value: mealSlot,
                      decoration: const InputDecoration(labelText: 'Momento'),
                      items: const [
                        DropdownMenuItem(value: 'lunch', child: Text('Comida')),
                        DropdownMenuItem(value: 'dinner', child: Text('Cena')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) => onMealSlotChanged(value ?? 'lunch'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedMenuId,
                      decoration: const InputDecoration(labelText: 'Plantilla'),
                      items: [
                        for (final menu in menus) DropdownMenuItem(value: menu.id, child: Text(menu.name)),
                      ],
                      onChanged: onMenuChanged,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onAssign,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Asignar al día'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _WeekTab extends StatelessWidget {
  const _WeekTab({
    required this.days,
    required this.dailyMenus,
    required this.pendingDays,
    required this.fullDayLabel,
    required this.slotLabel,
    required this.slotRank,
    required this.itemsForDay,
    required this.onSelectDay,
    required this.onConfirmDay,
  });

  final List<DateTime> days;
  final List<SmartDailyMenuModel> dailyMenus;
  final List<DateTime> pendingDays;
  final String Function(DateTime) fullDayLabel;
  final String Function(String) slotLabel;
  final int Function(String) slotRank;
  final List<SmartDailyMenuModel> Function(List<SmartDailyMenuModel>, DateTime) itemsForDay;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<DateTime> onConfirmDay;

  @override
  Widget build(BuildContext context) {
    final pendingSet = pendingDays.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionCard(
          icon: Icons.view_week_rounded,
          title: 'Plan semanal',
          subtitle: 'Tarjetas compactas. Toca un día para editarlo en la pestaña Día.',
          child: Column(
            children: [
              for (final day in days)
                _WeekDayTile(
                  day: day,
                  title: fullDayLabel(day),
                  items: itemsForDay(dailyMenus, day),
                  hasPending: pendingSet.contains(DateTime(day.year, day.month, day.day)),
                  slotLabel: slotLabel,
                  slotRank: slotRank,
                  onTap: () => onSelectDay(day),
                  onConfirm: pendingSet.contains(DateTime(day.year, day.month, day.day)) ? () => onConfirmDay(day) : null,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  const _TemplatesTab({
    required this.menus,
    required this.mealTypeLabel,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final List<SmartMenuModel> menus;
  final String Function(String) mealTypeLabel;
  final VoidCallback onCreate;
  final ValueChanged<SmartMenuModel> onEdit;
  final ValueChanged<SmartMenuModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionCard(
          icon: Icons.bookmark_rounded,
          title: 'Plantillas',
          subtitle: 'Guarda platos frecuentes con sus ingredientes.',
          trailing: FilledButton.tonalIcon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crear'),
          ),
          child: menus.isEmpty
              ? EmptyState(
                  icon: Icons.restaurant_menu_outlined,
                  title: 'Sin plantillas',
                  message: 'Crea menús frecuentes y luego asígnalos a cualquier día.',
                  buttonText: 'Crear plantilla',
                  onPressed: onCreate,
                )
              : Column(
                  children: [
                    for (final menu in menus)
                      _PresetMenuTile(
                        menu: menu,
                        mealTypeLabel: mealTypeLabel,
                        onEdit: () => onEdit(menu),
                        onDelete: () => onDelete(menu),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _WeekDayTile extends StatelessWidget {
  const _WeekDayTile({
    required this.day,
    required this.title,
    required this.items,
    required this.hasPending,
    required this.slotLabel,
    required this.slotRank,
    required this.onTap,
    required this.onConfirm,
  });

  final DateTime day;
  final String title;
  final List<SmartDailyMenuModel> items;
  final bool hasPending;
  final String Function(String) slotLabel;
  final int Function(String) slotRank;
  final VoidCallback onTap;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => slotRank(a.mealSlot).compareTo(slotRank(b.mealSlot)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        radius: 22,
        child: ListTile(
          onTap: onTap,
          leading: Icon(hasPending ? Icons.pending_actions_rounded : Icons.event_available_rounded),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: sorted.isEmpty
              ? const Text('Sin menú asignado')
              : Text(sorted.map((item) => '${slotLabel(item.mealSlot)}: ${item.menu?.name ?? 'Menú'}').join(' · ')),
          trailing: onConfirm == null
              ? const Icon(Icons.chevron_right_rounded)
              : FilledButton.tonal(
                  onPressed: onConfirm,
                  child: const Text('Confirmar'),
                ),
        ),
      ),
    );
  }
}

class _CompactAssignedMenuRow extends StatelessWidget {
  const _CompactAssignedMenuRow({required this.slot, required this.item});

  final String slot;
  final SmartDailyMenuModel item;

  @override
  Widget build(BuildContext context) {
    final ingredients = item.menu?.ingredients ?? const <SmartMenuIngredientModel>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              slot,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menu?.name ?? 'Menú', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  item.shoppingConfirmed ? 'Compra confirmada' : 'Pendiente de compra',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.shoppingConfirmed ? Colors.green.shade700 : Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (ingredients.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    ingredients.map((e) => e.displayName).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetMenuTile extends StatelessWidget {
  const _PresetMenuTile({required this.menu, required this.mealTypeLabel, required this.onEdit, required this.onDelete});

  final SmartMenuModel menu;
  final String Function(String) mealTypeLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        radius: 22,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: const Icon(Icons.restaurant_menu_rounded),
          title: Text(menu.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text('${mealTypeLabel(menu.mealType)} · ${menu.ingredients.length} ingrediente(s)'),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
          children: [
            const Divider(height: 14),
            if (menu.ingredients.isEmpty)
              Text('Sin ingredientes', style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ingredient in menu.ingredients)
                    Chip(label: Text(ingredient.displayName), visualDensity: VisualDensity.compact),
                ],
              ),
            if ((menu.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text((menu.notes ?? '').trim(), style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
