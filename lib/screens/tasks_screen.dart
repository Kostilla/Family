import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final titleCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

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
          stream: repo.tasks(familyId),
          builder: (context, snapshot) {
            final items = snapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tareas', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Nueva tarea'),
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
                    await repo.addTask(
                      familyId: familyId,
                      title: titleCtrl.text,
                      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text,
                    );
                    titleCtrl.clear();
                    notesCtrl.clear();
                  },
                  child: const Text('Crear tarea'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final task = items[index];
                      return CheckboxListTile(
                        value: task.isDone,
                        onChanged: (_) => repo.toggleTask(task),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(task.notes ?? ''),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => repo.deleteTask(task.id),
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
