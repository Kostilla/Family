import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class CalendarCategoriesScreen extends ConsumerStatefulWidget {
  const CalendarCategoriesScreen({super.key});

  @override
  ConsumerState<CalendarCategoriesScreen> createState() => _CalendarCategoriesScreenState();
}

class _CalendarCategoriesScreenState extends ConsumerState<CalendarCategoriesScreen> {
  final nameCtrl = TextEditingController();
  final hexCtrl = TextEditingController();
  String selectedColor = _presetColors.first;
  CalendarCategoryModel? editing;
  bool saving = false;

  static const _presetColors = <String>[
    '#EF4444', // rojo
    '#F97316', // naranja
    '#F59E0B', // amarillo
    '#84CC16', // lima
    '#22C55E', // verde
    '#10B981', // esmeralda
    '#14B8A6', // turquesa
    '#06B6D4', // cyan
    '#0EA5E9', // celeste
    '#3B82F6', // azul
    '#6366F1', // índigo
    '#8B5CF6', // violeta
    '#A855F7', // morado
    '#D946EF', // fucsia
    '#EC4899', // rosa
    '#F43F5E', // coral
    '#64748B', // gris azulado
    '#111827', // oscuro
  ];

  @override
  void initState() {
    super.initState();
    hexCtrl.text = selectedColor;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    hexCtrl.dispose();
    super.dispose();
  }

  Color _colorFromHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    try {
      if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
      if (cleaned.length == 8) return Color(int.parse(cleaned, radix: 16));
    } catch (_) {}
    return Theme.of(context).colorScheme.primary;
  }

  String _hexFromColor(Color color) {
    final value = color.value & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String _normalizeHex(String raw, {String fallback = '#3B82F6'}) {
    var value = raw.trim().toUpperCase();
    if (value.isEmpty) return fallback;
    if (!value.startsWith('#')) value = '#$value';
    final hex = value.substring(1);
    final valid = RegExp(r'^[0-9A-F]{6}$').hasMatch(hex);
    return valid ? value : fallback;
  }

  void _setColor(String color) {
    final normalized = _normalizeHex(color, fallback: selectedColor);
    setState(() {
      selectedColor = normalized;
      hexCtrl.text = normalized;
    });
  }

  void _startEdit(CalendarCategoryModel category) {
    setState(() {
      editing = category;
      nameCtrl.text = category.name;
      selectedColor = _normalizeHex(category.color);
      hexCtrl.text = selectedColor;
    });
  }

  void _clearForm() {
    setState(() {
      editing = null;
      nameCtrl.clear();
      selectedColor = _presetColors.first;
      hexCtrl.text = selectedColor;
    });
  }

  Future<void> _openColorPicker() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryColorPickerDialog(
        initialColor: selectedColor,
        presetColors: _presetColors,
      ),
    );
    if (picked != null) _setColor(picked);
  }

  Future<void> _save(String familyId, int currentCount) async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para la categoría')),
      );
      return;
    }

    final normalizedColor = _normalizeHex(hexCtrl.text, fallback: selectedColor);
    setState(() {
      saving = true;
      selectedColor = normalizedColor;
      hexCtrl.text = normalizedColor;
    });

    try {
      await ref.read(repositoriesProvider).upsertCalendarCategory(
            id: editing?.id,
            familyId: familyId,
            name: name,
            color: normalizedColor,
            sortOrder: editing?.sortOrder ?? currentCount,
          );
      final wasEditing = editing != null;
      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasEditing ? 'Categoría guardada' : 'Categoría creada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar categoría: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _confirmDelete(CalendarCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Quieres eliminar "${category.name}"? Los eventos que usen esta categoría se quedarán sin categoría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(repositoriesProvider).deleteCalendarCategory(category.id);
      if (editing?.id == category.id) _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar categoría: $e')),
        );
      }
    }
  }

  Widget _colorPreview() {
    final color = _colorFromHex(selectedColor);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _openColorPicker,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.palette_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Color de la categoría', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(selectedColor, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(currentFamilyIdProvider);
    final repo = ref.watch(repositoriesProvider);

    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: familyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (familyId) {
              if (familyId == null) return const RequireFamily();
              return StreamBuilder<List<CalendarCategoryModel>>(
                stream: repo.calendarCategories(familyId),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      ProHeader(
                        icon: Icons.category_outlined,
                        title: 'Categorías',
                        subtitle: 'Crea, edita, elimina y personaliza colores del calendario',
                        action: IconButton.filledTonal(
                          onPressed: () => context.go('/settings'),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SectionCard(
                        icon: editing == null ? Icons.add_circle_outline : Icons.edit_outlined,
                        title: editing == null ? 'Nueva categoría' : 'Editar categoría',
                        subtitle: 'El color se verá en la vista mensual del calendario',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: nameCtrl,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Nombre',
                                hintText: 'Trabajo, Médico, Colegio...',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _colorPreview(),
                            const SizedBox(height: 14),
                            Text('Colores rápidos', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final color in _presetColors)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(99),
                                    onTap: () => _setColor(color),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: _colorFromHex(color),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selectedColor == color
                                              ? Theme.of(context).colorScheme.onSurface
                                              : Colors.white.withOpacity(0.6),
                                          width: selectedColor == color ? 3 : 1,
                                        ),
                                      ),
                                      child: selectedColor == color
                                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                                          : null,
                                    ),
                                  ),
                                InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: _openColorPicker,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                      gradient: const SweepGradient(
                                        colors: [
                                          Colors.red,
                                          Colors.orange,
                                          Colors.yellow,
                                          Colors.green,
                                          Colors.cyan,
                                          Colors.blue,
                                          Colors.purple,
                                          Colors.red,
                                        ],
                                      ),
                                    ),
                                    child: const Icon(Icons.add, size: 20, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: hexCtrl,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                                LengthLimitingTextInputFormatter(7),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Color HEX personalizado',
                                hintText: '#3B82F6',
                                prefixIcon: Icon(Icons.tag, color: _colorFromHex(selectedColor)),
                                suffixIcon: IconButton(
                                  tooltip: 'Aplicar color',
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () => _setColor(hexCtrl.text),
                                ),
                              ),
                              onSubmitted: _setColor,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: saving ? null : () => _save(familyId, categories.length),
                                    icon: const Icon(Icons.save_outlined),
                                    label: Text(saving ? 'Guardando...' : editing == null ? 'Crear categoría' : 'Guardar cambios'),
                                  ),
                                ),
                                if (editing != null) ...[
                                  const SizedBox(width: 8),
                                  IconButton.outlined(
                                    tooltip: 'Cancelar edición',
                                    onPressed: saving ? null : _clearForm,
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Tus categorías', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          const Spacer(),
                          Text('${categories.length}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ))
                      else if (categories.isEmpty)
                        const EmptyState(
                          icon: Icons.category_outlined,
                          title: 'Aún no hay categorías',
                          message: 'Crea categorías para colorear los eventos del calendario.',
                        )
                      else
                        ...categories.map(
                          (category) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _colorFromHex(category.color),
                                child: const Icon(Icons.event, color: Colors.white, size: 18),
                              ),
                              title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text(category.color),
                              onTap: () => _startEdit(category),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Editar',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _startEdit(category),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(category),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryColorPickerDialog extends StatefulWidget {
  const _CategoryColorPickerDialog({
    required this.initialColor,
    required this.presetColors,
  });

  final String initialColor;
  final List<String> presetColors;

  @override
  State<_CategoryColorPickerDialog> createState() => _CategoryColorPickerDialogState();
}

class _CategoryColorPickerDialogState extends State<_CategoryColorPickerDialog> {
  late Color color;
  late final TextEditingController hexCtrl;

  @override
  void initState() {
    super.initState();
    color = _colorFromHex(widget.initialColor);
    hexCtrl = TextEditingController(text: _hexFromColor(color));
  }

  @override
  void dispose() {
    hexCtrl.dispose();
    super.dispose();
  }

  Color _colorFromHex(String value) {
    final cleaned = value.replaceAll('#', '').trim();
    try {
      if (cleaned.length == 6) return Color(int.parse('FF$cleaned', radix: 16));
      if (cleaned.length == 8) return Color(int.parse(cleaned, radix: 16));
    } catch (_) {}
    return const Color(0xFF3B82F6);
  }

  String _hexFromColor(Color color) {
    final value = color.value & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String _normalizeHex(String raw) {
    var value = raw.trim().toUpperCase();
    if (value.isEmpty) return _hexFromColor(color);
    if (!value.startsWith('#')) value = '#$value';
    final hex = value.substring(1);
    final valid = RegExp(r'^[0-9A-F]{6}$').hasMatch(hex);
    return valid ? value : _hexFromColor(color);
  }

  void _setColor(Color next) {
    setState(() {
      color = next;
      hexCtrl.text = _hexFromColor(next);
    });
  }

  Widget _slider({
    required String label,
    required int value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            label: value.toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 34, child: Text(value.toString(), textAlign: TextAlign.end)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Elegir color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 18),
            Text('Predeterminados', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in widget.presetColors)
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => _setColor(_colorFromHex(hex)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _colorFromHex(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _hexFromColor(color) == hex ? Theme.of(context).colorScheme.onSurface : Colors.white.withOpacity(0.7),
                          width: _hexFromColor(color) == hex ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Paleta personalizada', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            _slider(
              label: 'R',
              value: color.red,
              onChanged: (v) => _setColor(Color.fromARGB(255, v.round(), color.green, color.blue)),
            ),
            _slider(
              label: 'G',
              value: color.green,
              onChanged: (v) => _setColor(Color.fromARGB(255, color.red, v.round(), color.blue)),
            ),
            _slider(
              label: 'B',
              value: color.blue,
              onChanged: (v) => _setColor(Color.fromARGB(255, color.red, color.green, v.round())),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: hexCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: InputDecoration(
                labelText: 'HEX',
                prefixIcon: const Icon(Icons.tag),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _setColor(_colorFromHex(_normalizeHex(hexCtrl.text))),
                ),
              ),
              onSubmitted: (value) => _setColor(_colorFromHex(_normalizeHex(value))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_hexFromColor(color)),
          child: const Text('Usar color'),
        ),
      ],
    );
  }
}
