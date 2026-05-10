import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final titleCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  bool showDone = true;
  bool addExpanded = false;

  @override
  void dispose() {
    titleCtrl.dispose();
    notesCtrl.dispose();
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
        return StreamBuilder<List<TaskModel>>(
          stream: repo.tasks(familyId),
          builder: (context, snapshot) {
            final allItems = snapshot.data ?? [];
            final query = searchCtrl.text.trim().toLowerCase();
            final items = allItems.where((task) {
              final matchesQuery = query.isEmpty ||
                  task.title.toLowerCase().contains(query) ||
                  (task.notes ?? '').toLowerCase().contains(query);
              final matchesDone = showDone || !task.isDone;
              return matchesQuery && matchesDone;
            }).toList();
            final pending = allItems.where((e) => !e.isDone).length;
            final done = allItems.where((e) => e.isDone).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 24),
              children: [
                ProHeader(
                  icon: Icons.task_alt_rounded,
                  title: 'Tareas',
                  subtitle: pending == 0 ? 'Todo bajo control' : '$pending pendiente(s) · $done completada(s)',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    MetricPill(icon: Icons.pending_actions_rounded, label: 'Pendientes', value: '$pending'),
                    MetricPill(icon: Icons.verified_rounded, label: 'Hechas', value: '$done'),
                    FilterChip(
                      label: const Text('Mostrar completadas'),
                      selected: showDone,
                      onSelected: (value) => setState(() => showDone = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: addExpanded ? 'Nueva tarea' : 'Añadir tarea',
                  subtitle: addExpanded
                      ? 'Completa los campos y crea una tarea familiar.'
                      : 'Toca para desplegar el formulario.',
                  icon: Icons.add_task_rounded,
                  trailing: IconButton.filledTonal(
                    tooltip: addExpanded ? 'Contraer' : 'Añadir tarea',
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
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('Añadir tarea'),
                      ),
                    ),
                    secondChild: Column(
                      children: [
                        TextField(
                          controller: titleCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.title), labelText: 'Título'),
                          onSubmitted: (_) => _addTask(familyId),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.notes), labelText: 'Notas'),
                          minLines: 1,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _addTask(familyId),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear tarea'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Buscar tarea'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (items.isEmpty)
                  EmptyState(
                    icon: Icons.task_alt,
                    title: allItems.isEmpty ? 'Sin tareas' : 'No hay resultados',
                    message: allItems.isEmpty ? 'Crea la primera tarea familiar.' : 'Prueba con otro filtro o muestra las completadas.',
                  )
                else
                  ...items.map(
                    (task) => GlassPanel(
                      padding: EdgeInsets.zero,
                      child: CheckboxListTile(
                        value: task.isDone,
                        onChanged: (_) => repo.toggleTask(task),
                        title: Text(
                          task.title.isEmpty ? 'Tarea sin título' : task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: task.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: task.notes == null || task.notes!.isEmpty ? null : Text(task.notes!),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => repo.deleteTask(task.id),
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

  Future<void> _addTask(String familyId) async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;
    await ref.read(repositoriesProvider).addTask(
          familyId: familyId,
          title: title,
          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        );
    titleCtrl.clear();
    notesCtrl.clear();
  }
}
