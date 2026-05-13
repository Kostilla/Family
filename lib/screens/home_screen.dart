import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase.dart';
import '../models/app_models.dart';
import '../models/module_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final chatCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  @override
  void dispose() {
    chatCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollCtrl.hasClients) return;
      scrollCtrl.animateTo(
        scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  FamilySummary? _currentFamily(List<FamilySummary> families, String? id) {
    if (id == null) return null;
    for (final family in families) {
      if (family.id == id) return family;
    }
    return families.isEmpty ? null : families.first;
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(myFamiliesProvider);
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);
    final currentUserId = sb.auth.currentUser?.id;

    return currentFamilyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (familyId) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            familiesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error cargando familias: $e'),
              data: (families) {
                final current = _currentFamily(families, familyId);
                return ProHeader(
                  icon: Icons.home_rounded,
                  title: 'Inicio',
                  subtitle: current == null
                      ? 'Crea o elige una familia desde Ajustes.'
                      : current.name,
                );
              },
            ),
            const SizedBox(height: 12),
            if (familyId == null)
              const RequireFamily()
            else ...[
              _QuickActions(familyId: familyId),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, _) {
                  final modulesAsync = ref.watch(familyModulesProvider);
                  return modulesAsync.maybeWhen(
                    data: (modules) => modules.isEnabled('chat')
                        ? _ChatCard(
                            familyId: familyId,
                            currentUserId: currentUserId,
                            chatCtrl: chatCtrl,
                            scrollCtrl: scrollCtrl,
                            formatTime: _formatTime,
                            scrollToBottom: _scrollToBottom,
                          )
                        : const EmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: 'Chat desactivado',
                            message: 'Puedes activarlo en Ajustes → Módulos.',
                          ),
                    orElse: () => _ChatCard(
                      familyId: familyId,
                      currentUserId: currentUserId,
                      chatCtrl: chatCtrl,
                      scrollCtrl: scrollCtrl,
                      formatTime: _formatTime,
                      scrollToBottom: _scrollToBottom,
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.familyId});

  final String familyId;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _time(DateTime date) {
    final local = date.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _extendedEndTime(EventModel event) {
    final startDay = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
    final diff = event.endAt.difference(startDay).inMinutes;
    final safe = diff.clamp(0, 72 * 60);
    final hh = (safe ~/ 60).toString().padLeft(2, '0');
    final mm = (safe % 60).toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _eventLine(EventModel event, Map<String, CalendarCategoryModel> categories) {
    final category = categories[event.categoryId];
    final categoryName = category?.name ?? 'Sin categoría';
    final time = event.allDay ? 'Todo el día' : '${_time(event.startAt)}-${_extendedEndTime(event)}';
    return '$time · $categoryName · ${event.title}';
  }

  List<String> _todayMealLines(List<MealEntryModel> meals) {
    final today = DateTime.now();
    final todayMeals = meals.where((m) => _sameDay(m.day, today)).toList();
    String? lunch;
    String? dinner;
    for (final meal in todayMeals) {
      if (meal.mealType == 'lunch' && meal.text.trim().isNotEmpty) lunch = meal.text.trim();
      if (meal.mealType == 'dinner' && meal.text.trim().isNotEmpty) dinner = meal.text.trim();
    }
    return [
      if (lunch != null) '🍽 Comida: $lunch',
      if (dinner != null) '🌙 Cena: $dinner',
    ];
  }

  List<Widget> _agendaWidgets(
    BuildContext context,
    List<EventModel> events,
    Map<String, CalendarCategoryModel> categories,
  ) {
    final today = DateTime.now();
    final todayEvents = events.where((e) => _sameDay(e.startAt, today)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (todayEvents.isEmpty) {
      return [Text('Sin eventos hoy', style: Theme.of(context).textTheme.bodySmall)];
    }

    return todayEvents.take(3).map((event) {
      final category = categories[event.categoryId];
      final color = _parseColor(category?.color ?? event.color ?? '#3B82F6');
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5, right: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(
                _eventLine(event, categories),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }


  String _buildAiSummary(int shopping, int tasks, List<String> meals, List<EventModel> events) {
    final todayEvents = events.where((e) => _sameDay(e.startAt, DateTime.now())).length;
    return 'Hoy: $shopping compra · $tasks tareas · $todayEvents eventos';
  }

  List<String> _buildAiSuggestions(int shopping, int tasks, List<String> meals, List<EventModel> events) {
    final suggestions = <String>[];
    if (shopping > 5) suggestions.add('🛒 Compra bastante cargada');
    if (tasks > 3) suggestions.add('✅ Muchas tareas pendientes');
    if (meals.isEmpty) suggestions.add('🍽 Sin menú configurado hoy');
    if (events.isEmpty) suggestions.add('📅 Día tranquilo sin eventos');
    if (suggestions.isEmpty) suggestions.add('✨ Todo parece bajo control');
    return suggestions.take(2).toList();
  }

  Color _parseColor(String value) {
    final clean = value.replaceAll('#', '').trim();
    final hex = clean.length == 6 ? 'FF$clean' : clean;
    final parsed = int.tryParse(hex, radix: 16);
    return Color(parsed ?? 0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoriesProvider);
    final modulesAsync = ref.watch(familyModulesProvider);

    return StreamBuilder<List<ShoppingItemModel>>(
      stream: repo.shopping(familyId),
      builder: (context, shoppingSnapshot) {
        final shoppingItems = shoppingSnapshot.data ?? [];
        final pendingShopping = shoppingItems.where((e) => !e.isDone).length;

        return StreamBuilder<List<TaskModel>>(
          stream: repo.tasks(familyId),
          builder: (context, tasksSnapshot) {
            final tasks = tasksSnapshot.data ?? [];
            final pendingTasks = tasks.where((e) => !e.isDone).length;

            return StreamBuilder<List<MealEntryModel>>(
              stream: repo.meals(familyId),
              builder: (context, mealsSnapshot) {
                final mealLines = mealsSnapshot.hasError
                    ? <String>[]
                    : _todayMealLines(mealsSnapshot.data ?? []);

                return StreamBuilder<List<CalendarCategoryModel>>(
                  stream: repo.calendarCategories(familyId),
                  builder: (context, categoriesSnapshot) {
                    final categories = {
                      for (final c in categoriesSnapshot.data ?? <CalendarCategoryModel>[]) c.id: c,
                    };

                    return StreamBuilder<List<EventModel>>(
                      stream: repo.events(familyId),
                      builder: (context, eventsSnapshot) {
                        final events = eventsSnapshot.data ?? [];
                        final modules = modulesAsync.maybeWhen(
                          data: (value) => value,
                          orElse: () => EnabledModules({
                            for (final definition in familyModuleDefinitions)
                              definition.key: definition.defaultEnabled,
                          }),
                        );

                        final tiles = <Widget>[

                          _ActionTile(
                              icon: Icons.auto_awesome_outlined,
                              title: 'IA familiar',
                              subtitle: _buildAiSummary(pendingShopping, pendingTasks, mealLines, events),
                              detailLines: _buildAiSuggestions(pendingShopping, pendingTasks, mealLines, events),
                              onTap: () {},
                            ),
                          if (modules.isEnabled('shopping'))
                            _ActionTile(
                              icon: Icons.shopping_cart_outlined,
                              title: 'Compra',
                              subtitle: pendingShopping == 1
                                  ? '1 producto pendiente'
                                  : '$pendingShopping productos pendientes',
                              onTap: () => context.go('/shopping'),
                            ),
                          if (modules.isEnabled('tasks'))
                            _ActionTile(
                              icon: Icons.checklist_outlined,
                              title: 'Tareas',
                              subtitle: pendingTasks == 1
                                  ? '1 tarea pendiente'
                                  : '$pendingTasks tareas pendientes',
                              onTap: () => context.go('/tasks'),
                            ),
                          if (modules.isEnabled('menus'))
                            _ActionTile(
                              icon: Icons.restaurant_menu_outlined,
                              title: 'Menú de hoy',
                              subtitle: mealLines.isEmpty ? 'Sin menú para hoy' : 'Plan de comidas de hoy',
                              detailLines: mealLines,
                              onTap: () => context.go('/menus'),
                            ),
                          if (modules.isEnabled('calendar'))
                            _ActionTile(
                              icon: Icons.calendar_month_outlined,
                              title: 'Agenda de hoy',
                              subtitle: events.where((e) => _sameDay(e.startAt, DateTime.now())).isEmpty
                                  ? 'Sin eventos hoy'
                                  : '${events.where((e) => _sameDay(e.startAt, DateTime.now())).length} evento(s)',
                              details: _agendaWidgets(context, events, categories),
                              onTap: () => context.go('/calendar'),
                            ),
                        ];

                        if (tiles.isEmpty) {
                          return const EmptyState(
                            icon: Icons.dashboard_customize_outlined,
                            title: 'Sin módulos activos',
                            message: 'Activa módulos desde Ajustes para personalizar el Inicio.',
                          );
                        }

                        return GridView.count(
                          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: MediaQuery.sizeOf(context).width > 700 ? 1.65 : 1.42,
                          children: tiles,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.detailLines,
    this.details,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final List<String>? detailLines;
  final List<Widget>? details;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detailWidgets = details ??
        (detailLines ?? const <String>[])
            .take(2)
            .map((line) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ))
            .toList();

    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: 24,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withOpacity(.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: scheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Icon(Icons.chevron_right, color: scheme.primary),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                maxLines: detailWidgets.isEmpty ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              ...detailWidgets,
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatCard extends ConsumerWidget {
  const _ChatCard({
    required this.familyId,
    required this.currentUserId,
    required this.chatCtrl,
    required this.scrollCtrl,
    required this.formatTime,
    required this.scrollToBottom,
  });

  final String familyId;
  final String? currentUserId;
  final TextEditingController chatCtrl;
  final ScrollController scrollCtrl;
  final String Function(DateTime) formatTime;
  final VoidCallback scrollToBottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoriesProvider);
    return StreamBuilder<List<ChatMessageModel>>(
      stream: repo.chat(familyId),
      builder: (context, snapshot) {
        if (snapshot.hasData) scrollToBottom();
        final msgs = snapshot.data ?? [];
        return SectionCard(
          icon: Icons.chat_bubble_outline,
          title: 'Chat familiar',
          subtitle: '${msgs.length} mensaje(s)',
          trailing: IconButton(
            tooltip: 'Ajustes de familia',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.group_add_outlined),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 340,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : msgs.isEmpty
                        ? const EmptyState(
                            icon: Icons.forum_outlined,
                            title: 'Empieza la conversación',
                            message: 'Los mensajes se actualizan en tiempo real para toda la familia.',
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: msgs.length,
                            itemBuilder: (context, index) {
                              final msg = msgs[index];
                              final isMe = msg.createdBy == currentUserId;
                              final initials = msg.authorName.trim().isEmpty
                                  ? 'U'
                                  : msg.authorName
                                      .trim()
                                      .split(RegExp(r'\s+'))
                                      .map((e) => e.isEmpty ? '' : e[0])
                                      .take(2)
                                      .join()
                                      .toUpperCase();
                              final bubble = ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 460),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 18),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isMe ? 'Tú · ${msg.authorName}' : msg.authorName,
                                            style: Theme.of(context).textTheme.labelMedium,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            formatTime(msg.createdAt),
                                            style: Theme.of(context).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(msg.text),
                                    ],
                                  ),
                                ),
                              );

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: isMe
                                      ? [
                                          bubble,
                                          const SizedBox(width: 8),
                                          UserAvatar(
                                            initials: initials,
                                            avatarPath: msg.authorAvatarPath,
                                            radius: 16,
                                          ),
                                        ]
                                      : [
                                          UserAvatar(
                                            initials: initials,
                                            avatarPath: msg.authorAvatarPath,
                                            radius: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          bubble,
                                        ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chatCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.message_outlined),
                        labelText: 'Escribe un mensaje',
                      ),
                      onSubmitted: (_) => _send(ref),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _send(ref),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _send(WidgetRef ref) async {
    final text = chatCtrl.text.trim();
    if (text.isEmpty) return;
    await ref.read(repositoriesProvider).sendChat(familyId: familyId, text: text);
    chatCtrl.clear();
    scrollToBottom();
  }
}
