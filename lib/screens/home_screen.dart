import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final chatCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(myFamiliesProvider);
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);

    return currentFamilyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (familyId) {
        return ListView(
          children: [
            Text('Inicio', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            familiesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (families) {
                final current = families.where((e) => e.isCurrent).toList();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.family_restroom),
                    title: Text(current.isEmpty ? 'Sin familia activa' : current.first.name),
                    subtitle: Text(current.isEmpty
                        ? 'Selecciona o crea una familia'
                        : 'Rol: ${current.first.role}'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (familyId == null)
              const Card(
                child: ListTile(
                  title: Text('No hay familia activa'),
                ),
              )
            else
              StreamBuilder(
                stream: repo.chat(familyId),
                builder: (context, snapshot) {
                  final msgs = snapshot.data ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.chat_bubble_outline),
                              SizedBox(width: 8),
                              Text('Chat familiar'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              itemCount: msgs.length,
                              itemBuilder: (context, index) {
                                final msg = msgs[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(msg.authorName),
                                  subtitle: Text(msg.text),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: chatCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Escribe un mensaje',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () async {
                                  if (chatCtrl.text.trim().isEmpty) return;
                                  await repo.sendChat(
                                    familyId: familyId,
                                    text: chatCtrl.text,
                                  );
                                  chatCtrl.clear();
                                },
                                child: const Text('Enviar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.notifications_active_outlined),
                title: Text('Push móviles'),
                subtitle: Text('Base preparada con FCM + tabla de device tokens + edge function.'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.attach_file_outlined),
                title: Text('Adjuntos'),
                subtitle: Text('Esquema preparado en chat, tareas, compra y eventos.'),
              ),
            ),
          ],
        );
      },
    );
  }
}
