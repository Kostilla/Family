import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final textCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  bool showBought = true;
  bool addExpanded = false;

  @override
  void dispose() {
    textCtrl.dispose();
    qtyCtrl.dispose();
    searchCtrl.dispose();
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

        final profilesAsync = ref.watch(familyProfilesProvider(familyId));
        final profiles = profilesAsync.maybeWhen(data: (value) => value, orElse: () => const <String, UserProfileModel>{});

        return StreamBuilder(
          stream: repo.shopping(familyId),
          builder: (context, snapshot) {
            final allItems = snapshot.data ?? [];
            final query = searchCtrl.text.trim().toLowerCase();
            final items = allItems.where((item) {
              final matchesQuery = query.isEmpty ||
                  item.text.toLowerCase().contains(query) ||
                  (item.qty ?? '').toLowerCase().contains(query);
              final matchesBought = showBought || !item.isDone;
              return matchesQuery && matchesBought;
            }).toList();

            final pending = allItems.where((e) => !e.isDone).length;
            final bought = allItems.where((e) => e.isDone).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 24),
              children: [
                ProHeader(
                  icon: Icons.shopping_bag_rounded,
                  title: 'Compra',
                  subtitle: pending == 0 ? 'Lista familiar al día' : '$pending producto(s) pendiente(s)',
                  action: IconButton.filledTonal(
                    tooltip: 'Eliminar comprados',
                    onPressed: bought == 0 ? null : () => _confirmClear(familyId, bought),
                    icon: const Icon(Icons.cleaning_services_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetricPill(icon: Icons.radio_button_unchecked, label: 'Pendientes', value: '$pending'),
                    MetricPill(icon: Icons.check_circle_outline, label: 'Comprados', value: '$bought'),
                    FilterChip(
                      label: const Text('Mostrar comprados'),
                      selected: showBought,
                      onSelected: (value) => setState(() => showBought = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  icon: Icons.add_shopping_cart_rounded,
                  title: addExpanded ? 'Añadir producto' : 'Añadir producto rápido',
                  subtitle: addExpanded
                      ? 'Completa los campos y guárdalo en la lista familiar.'
                      : 'Toca para desplegar el formulario.',
                  trailing: IconButton.filledTonal(
                    tooltip: addExpanded ? 'Contraer' : 'Añadir producto',
                    onPressed: () => setState(() => addExpanded = !addExpanded),
                    icon: Icon(addExpanded ? Icons.keyboard_arrow_up_rounded : Icons.add_rounded),
                  ),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: addExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => addExpanded = true),
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Añadir producto'),
                      ),
                    ),
                    secondChild: Column(
                      children: [
                        TextField(
                          controller: textCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.shopping_basket_outlined),
                            labelText: 'Producto',
                          ),
                          onSubmitted: (_) => _addItem(familyId),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: qtyCtrl,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.numbers_outlined),
                                  labelText: 'Cantidad',
                                ),
                                onSubmitted: (_) => _addItem(familyId),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () => _addItem(familyId),
                              icon: const Icon(Icons.add),
                              label: const Text('Añadir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Buscar en la lista',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (items.isEmpty)
                  EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: allItems.isEmpty ? 'Lista vacía' : 'No hay resultados',
                    message: allItems.isEmpty
                        ? 'Añade el primer producto para verlo todos en tiempo real.'
                        : 'Prueba otro filtro o muestra los productos comprados.',
                  )
                else
                  ...items.map(
                    (item) => GlassPanel(
                      padding: EdgeInsets.zero,
                      child: CheckboxListTile(
                        value: item.isDone,
                        onChanged: (_) => repo.toggleShopping(item),
                        title: Text(
                          item.text.isEmpty ? 'Producto sin nombre' : item.text,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: _ShoppingSubtitle(item: item, profile: profiles[item.addedBy]),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => repo.deleteShopping(item.id),
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

  Future<void> _confirmClear(String familyId, int bought) async {
    final repo = ref.read(repositoriesProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comprados'),
        content: Text('Se eliminarán $bought productos marcados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) await repo.clearBoughtShopping(familyId);
  }

  Future<void> _addItem(String familyId) async {
    final repo = ref.read(repositoriesProvider);
    final text = textCtrl.text.trim();
    if (text.isEmpty) return;
    await repo.addShopping(
      familyId: familyId,
      text: text,
      qty: qtyCtrl.text.trim().isEmpty ? null : qtyCtrl.text.trim(),
    );
    textCtrl.clear();
    qtyCtrl.clear();
  }
}


class _ShoppingSubtitle extends StatelessWidget {
  const _ShoppingSubtitle({required this.item, required this.profile});

  final ShoppingItemModel item;
  final UserProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    if (item.qty != null && item.qty!.trim().isNotEmpty) {
      lines.add(Text(item.qty!.trim()));
    }
    if (profile != null) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(initials: profile!.initials, avatarPath: profile!.avatarPath, radius: 10),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Añadido por ${profile!.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines);
  }
}
