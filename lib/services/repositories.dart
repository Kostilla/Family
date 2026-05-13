import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import '../core/supabase.dart';
import '../models/app_models.dart';
import 'storage_service.dart';

class Repositories {
  final _uuid = const Uuid();
  final _storage = StorageService();

  Stream<List<ShoppingItemModel>> shopping(String familyId) {
    return sb
        .from('shopping_items')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) => rows
            .map((e) => ShoppingItemModel.fromMap(e))
            .toList()
          ..sort((a, b) {
            if (a.isDone == b.isDone) {
              return b.updatedAt.compareTo(a.updatedAt);
            }
            return a.isDone ? 1 : -1;
          }));
  }

  Future<void> addShopping({
    required String familyId,
    required String text,
    String? qty,
    String? category,
    String listName = 'principal',
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    final id = _uuid.v4();
    final userId = sb.auth.currentUser!.id;

    // Primero intenta el esquema PRO; si tu Supabase aún está simplificado, cae al mínimo compatible.
    try {
      await sb.from('shopping_items').insert({
        'id': id,
        'family_id': familyId,
        'name': cleanText,
        'text': cleanText,
        'qty': qty,
        'category': category,
        'list_name': listName,
        'done': false,
        'is_done': false,
        'created_by': userId,
        'added_by': userId,
      });
    } catch (_) {
      await sb.from('shopping_items').insert({
        'id': id,
        'family_id': familyId,
        'name': cleanText,
        'done': false,
        'created_by': userId,
      });
    }
  }

  Future<void> toggleShopping(ShoppingItemModel item) async {
    final next = !item.isDone;
    try {
      await sb.from('shopping_items').update({
        'done': next,
        'is_done': next,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', item.id);
    } catch (_) {
      await sb.from('shopping_items').update({'done': next}).eq('id', item.id);
    }
  }

  Future<void> deleteShopping(String id) async {
    await sb.from('shopping_items').delete().eq('id', id);
  }

  Future<void> clearBoughtShopping(String familyId) async {
    try {
      await sb
          .from('shopping_items')
          .delete()
          .eq('family_id', familyId)
          .or('done.eq.true,is_done.eq.true');
    } catch (_) {
      await sb
          .from('shopping_items')
          .delete()
          .eq('family_id', familyId)
          .eq('done', true);
    }
  }

  Stream<List<TaskModel>> tasks(String familyId) {
    return sb
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) => rows.map((e) => TaskModel.fromMap(e)).toList()
          ..sort((a, b) {
            if (a.isDone == b.isDone) {
              if (a.dueAt == null && b.dueAt == null) {
                return b.updatedAt.compareTo(a.updatedAt);
              }
              if (a.dueAt == null) return 1;
              if (b.dueAt == null) return -1;
              return a.dueAt!.compareTo(b.dueAt!);
            }
            return a.isDone ? 1 : -1;
          }));
  }

  Future<void> addTask({
    required String familyId,
    required String title,
    String? notes,
    DateTime? dueAt,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final id = _uuid.v4();
    final userId = sb.auth.currentUser!.id;
    try {
      await sb.from('tasks').insert({
        'id': id,
        'family_id': familyId,
        'title': cleanTitle,
        'notes': notes,
        'due_at': dueAt?.toIso8601String(),
        'completed': false,
        'is_done': false,
        'created_by': userId,
        'assigned_to': userId,
      });
    } catch (_) {
      await sb.from('tasks').insert({
        'id': id,
        'family_id': familyId,
        'title': cleanTitle,
        'completed': false,
        'created_by': userId,
        'assigned_to': userId,
      });
    }
  }

  Future<void> toggleTask(TaskModel task) async {
    final next = !task.isDone;
    try {
      await sb.from('tasks').update({
        'completed': next,
        'is_done': next,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', task.id);
    } catch (_) {
      await sb.from('tasks').update({'completed': next}).eq('id', task.id);
    }
  }

  Future<void> deleteTask(String id) async {
    await sb.from('tasks').delete().eq('id', id);
  }

  Stream<List<ChatMessageModel>> chat(String familyId) {
    // Compatible con tu tabla actual: chat_messages(content, author_id, created_at).
    // No dependemos de vistas SQL adicionales como chat_message_feed.
    return sb
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) => rows
            .map((e) => ChatMessageModel.fromMap(e))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  Future<void> sendChat({
    required String familyId,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;
    await sb.from('chat_messages').insert({
      'id': _uuid.v4(),
      'family_id': familyId,
      'content': cleanText,
      'author_id': sb.auth.currentUser!.id,
    });
  }

  Future<void> attachToChat({
    required String familyId,
    required String chatMessageId,
  }) async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.single.bytes == null) return;

    final file = picked.files.single;
    final path = await _storage.uploadBytes(
      familyId: familyId,
      bytes: file.bytes!,
      originalName: file.name,
    );

    await sb.from('attachments').insert({
      'id': _uuid.v4(),
      'family_id': familyId,
      'chat_message_id': chatMessageId,
      'storage_path': path,
      'original_name': file.name,
      'mime_type': lookupMimeType(file.name, headerBytes: file.bytes!),
      'size_bytes': file.size,
      'created_by': sb.auth.currentUser!.id,
    });
  }

  Stream<List<CalendarCategoryModel>> calendarCategories(String familyId) {
    return sb
        .from('event_categories')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) => rows
            .map((e) => CalendarCategoryModel.fromMap(e))
            .toList()
          ..sort((a, b) {
            final order = a.sortOrder.compareTo(b.sortOrder);
            if (order != 0) return order;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }));
  }

  Future<List<CalendarCategoryModel>> calendarCategoriesOnce(String familyId) async {
    final rows = await sb
        .from('event_categories')
        .select('*')
        .eq('family_id', familyId)
        .order('sort_order');
    return (rows as List)
        .map((e) => CalendarCategoryModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> upsertCalendarCategory({
    String? id,
    required String familyId,
    required String name,
    required String color,
    int sortOrder = 0,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final payload = {
      'id': id ?? _uuid.v4(),
      'family_id': familyId,
      'name': cleanName,
      'color': color,
      'sort_order': sortOrder,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await sb.from('event_categories').upsert(payload, onConflict: 'id');
  }

  Future<void> deleteCalendarCategory(String id) async {
    await sb.from('events').update({'category_id': null}).eq('category_id', id);
    await sb.from('event_categories').delete().eq('id', id);
  }

  Stream<List<EventModel>> events(String familyId) {
    return sb
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) => rows.map((e) => EventModel.fromMap(e)).toList());
  }

  Future<void> addEvent({
    required String familyId,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    bool allDay = false,
    String? notes,
    String? categoryId,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final id = _uuid.v4();
    try {
      await sb.from('events').insert({
        'id': id,
        'family_id': familyId,
        'title': cleanTitle,
        'notes': notes,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'all_day': allDay,
        'event_date': startAt.toIso8601String().split('T').first,
        'created_by': sb.auth.currentUser!.id,
        'category_id': categoryId,
      });
    } catch (_) {
      await sb.from('events').insert({
        'id': id,
        'family_id': familyId,
        'title': cleanTitle,
        'event_date': startAt.toIso8601String().split('T').first,
      });
    }
  }

  Future<void> updateEvent({
    required String id,
    required String title,
    required DateTime startAt,
    required DateTime endAt,
    bool allDay = false,
    String? notes,
    String? categoryId,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    final payload = {
      'title': cleanTitle,
      'notes': notes,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'all_day': allDay,
      'event_date': startAt.toIso8601String().split('T').first,
      'category_id': categoryId,
      'updated_at': DateTime.now().toIso8601String(),
    };
    try {
      await sb.from('events').update(payload).eq('id', id);
    } catch (_) {
      await sb.from('events').update({
        'title': cleanTitle,
        'event_date': startAt.toIso8601String().split('T').first,
      }).eq('id', id);
    }
  }

  Future<void> deleteEvent(String id) async {
    await sb.from('events').delete().eq('id', id);
  }

  Stream<List<MealEntryModel>> meals(String familyId) {
    return sb
        .from('meal_entries')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) => rows.map((e) => MealEntryModel.fromMap(e)).toList());
  }

  Future<void> upsertMeal({
    required String familyId,
    required DateTime day,
    required String mealType,
    required String text,
  }) async {
    final dayKey = DateTime.utc(day.year, day.month, day.day).toIso8601String().split('T').first;
    final existing = await sb
        .from('meal_entries')
        .select('id')
        .eq('family_id', familyId)
        .eq('day_date', dayKey)
        .eq('meal_type', mealType)
        .maybeSingle();

    if (existing == null) {
      await sb.from('meal_entries').insert({
        'id': _uuid.v4(),
        'family_id': familyId,
        'day_date': dayKey,
        'meal_type': mealType,
        'text': text.trim(),
        'created_by': sb.auth.currentUser!.id,
      });
    } else {
      await sb.from('meal_entries').update({
        'text': text.trim(),
      }).eq('id', existing['id']);
    }
  }

  Future<List<FamilyAttachment>> attachmentsFor({
    String? chatMessageId,
    String? taskId,
    String? shoppingItemId,
    String? eventId,
  }) async {
    var query = sb.from('attachments').select('*');
    if (chatMessageId != null) query = query.eq('chat_message_id', chatMessageId);
    if (taskId != null) query = query.eq('task_id', taskId);
    if (shoppingItemId != null) query = query.eq('shopping_item_id', shoppingItemId);
    if (eventId != null) query = query.eq('event_id', eventId);
    final rows = await query.order('created_at');
    return (rows as List)
        .map((e) => FamilyAttachment.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Stream<List<SmartMenuModel>> smartMenus(String familyId) {
    return sb
        .from('smart_menus')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) async {
          final menus = <SmartMenuModel>[];
          for (final row in rows) {
            final id = (row['id'] ?? '').toString();
            final ingredientsRows = await sb
                .from('smart_menu_ingredients')
                .select('*')
                .eq('smart_menu_id', id)
                .order('sort_order');
            final map = Map<String, dynamic>.from(row);
            map['smart_menu_ingredients'] = ingredientsRows;
            menus.add(SmartMenuModel.fromMap(map));
          }
          menus.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return menus;
        })
        .asyncMap((future) => future);
  }

  Future<List<SmartMenuModel>> smartMenusOnce(String familyId) async {
    final rows = await sb
        .from('smart_menus')
        .select('*')
        .eq('family_id', familyId)
        .order('name');
    final menus = <SmartMenuModel>[];
    for (final raw in rows as List) {
      final row = Map<String, dynamic>.from(raw as Map);
      final ingredientsRows = await sb
          .from('smart_menu_ingredients')
          .select('*')
          .eq('smart_menu_id', row['id'])
          .order('sort_order');
      row['smart_menu_ingredients'] = ingredientsRows;
      menus.add(SmartMenuModel.fromMap(row));
    }
    return menus;
  }

  Future<void> upsertSmartMenu({
    String? id,
    required String familyId,
    required String name,
    required String mealType,
    String? notes,
    required List<String> ingredients,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    final menuId = id ?? _uuid.v4();
    await sb.from('smart_menus').upsert({
      'id': menuId,
      'family_id': familyId,
      'name': cleanName,
      'meal_type': mealType,
      'notes': notes?.trim(),
      'created_by': sb.auth.currentUser!.id,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id');

    await sb.from('smart_menu_ingredients').delete().eq('smart_menu_id', menuId);
    final cleanIngredients = ingredients
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (cleanIngredients.isEmpty) return;
    await sb.from('smart_menu_ingredients').insert([
      for (var i = 0; i < cleanIngredients.length; i++)
        {
          'id': _uuid.v4(),
          'smart_menu_id': menuId,
          'name': cleanIngredients[i],
          'sort_order': i,
        }
    ]);
  }

  Future<void> deleteSmartMenu(String id) async {
    await sb.from('smart_daily_menus').delete().eq('smart_menu_id', id);
    await sb.from('smart_menus').delete().eq('id', id);
  }

  Stream<List<SmartDailyMenuModel>> smartDailyMenus(String familyId) {
    return sb
        .from('smart_daily_menus')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) async {
          final menus = await smartMenusOnce(familyId);
          final byId = {for (final menu in menus) menu.id: menu};
          final items = rows.map((row) {
            final map = Map<String, dynamic>.from(row);
            final menuId = (map['smart_menu_id'] ?? '').toString();
            if (byId[menuId] != null) {
              map['smart_menus'] = {
                'id': byId[menuId]!.id,
                'family_id': byId[menuId]!.familyId,
                'name': byId[menuId]!.name,
                'meal_type': byId[menuId]!.mealType,
                'notes': byId[menuId]!.notes,
                'smart_menu_ingredients': byId[menuId]!.ingredients.map((e) => {
                  'id': e.id,
                  'smart_menu_id': e.smartMenuId,
                  'name': e.name,
                  'quantity': e.quantity,
                  'unit': e.unit,
                  'sort_order': e.sortOrder,
                }).toList(),
              };
            }
            return SmartDailyMenuModel.fromMap(map);
          }).toList();
          items.sort((a, b) => a.menuDate.compareTo(b.menuDate));
          return items;
        })
        .asyncMap((future) => future);
  }

  Future<void> assignSmartDailyMenu({
    required String familyId,
    required DateTime day,
    required String mealSlot,
    required String smartMenuId,
  }) async {
    final dayKey = DateTime.utc(day.year, day.month, day.day).toIso8601String().split('T').first;
    await sb.from('smart_daily_menus').upsert({
      'id': _uuid.v4(),
      'family_id': familyId,
      'menu_date': dayKey,
      'meal_slot': mealSlot,
      'smart_menu_id': smartMenuId,
      'shopping_confirmed': false,
      'created_by': sb.auth.currentUser!.id,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'family_id,menu_date,meal_slot');
  }

  Future<void> confirmSmartDailyShopping({
    required String familyId,
    required DateTime day,
    required List<String> selectedIngredients,
  }) async {
    final selected = selectedIngredients
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (selected.isNotEmpty) {
      List<dynamic> existingRows;
      try {
        existingRows = await sb
            .from('shopping_items')
            .select('name,text,done,is_done')
            .eq('family_id', familyId);
      } catch (_) {
        existingRows = await sb
            .from('shopping_items')
            .select('name,done')
            .eq('family_id', familyId);
      }
      final existingPending = <String>{};
      for (final raw in existingRows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final done = (row['done'] ?? row['is_done'] ?? false) as bool;
        if (!done) {
          final name = (row['name'] ?? row['text'] ?? '').toString().trim().toLowerCase();
          if (name.isNotEmpty) existingPending.add(name);
        }
      }

      for (final ingredient in selected) {
        if (!existingPending.contains(ingredient.toLowerCase())) {
          await addShopping(
            familyId: familyId,
            text: ingredient,
            category: 'Menús con compra',
            listName: 'principal',
          );
          existingPending.add(ingredient.toLowerCase());
        }
      }
    }

    final dayKey = DateTime.utc(day.year, day.month, day.day).toIso8601String().split('T').first;
    await sb
        .from('smart_daily_menus')
        .update({
          'shopping_confirmed': true,
          'shopping_confirmed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('family_id', familyId)
        .eq('menu_date', dayKey);
  }

}
