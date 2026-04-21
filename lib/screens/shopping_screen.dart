import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final textCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);

    return currentFamilyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (familyId) {
        if (familyId == null) {
          return const Center(child: Text('No hay familia activa.'));
        }

        return StreamBuilder(
          stream: repo.shopping(familyId),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Compra', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        decoration: const InputDecoration(labelText: 'Producto'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (textCtrl.text.trim().isEmpty) return;
                        await repo.addShopping(
                          familyId: familyId,
                          text: textCtrl.text,
                          qty: qtyCtrl.text.trim().isEmpty ? null : qtyCtrl.text,
                        );
                        textCtrl.clear();
                        qtyCtrl.clear();
                      },
                      child: const Text('Añadir'),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return CheckboxListTile(
                        value: item.isDone,
                        onChanged: (_) => repo.toggleShopping(item),
                        title: Text(
                          item.text,
                          style: TextStyle(
                            decoration:
                                item.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(item.qty ?? ''),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => repo.deleteShopping(item.id),
                        ),
                      );
                    },
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
