import 'dart:typed_data';

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
        .order('is_done')
        .order('updated_at')
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
    await sb.from('shopping_items').insert({
      'id': _uuid.v4(),
      'family_id': familyId,
      'text': text.trim(),
      'qty': qty,
      'category': category,
      'list_name': listName,
      'added_by': sb.auth.currentUser!.id,
    });
  }

  Future<void> toggleShopping(ShoppingItemModel item) async {
    await sb.from('shopping_items').update({
      'is_done': !item.isDone,
    }).eq('id', item.id);
  }

  Future<void> deleteShopping(String id) async {
    await sb.from('shopping_items').delete().eq('id', id);
  }

  Stream<List<TaskModel>> tasks(String familyId) {
    return sb
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .map((rows) => rows.map((e) => TaskModel.fromMap(e)).toList()
          ..sort((a, b) {
            if (a.isDone == b.isDone) {
              if (a.dueAt == null && b.dueAt == null) return 0;
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
    await sb.from('tasks').insert({
      'id': _uuid.v4(),
      'family_id': familyId,
      'title': title.trim(),
      'notes': notes,
      'due_at': dueAt?.toIso8601String(),
      'created_by': sb.auth.currentUser!.id,
      'assigned_to': sb.auth.currentUser!.id,
    });
  }

  Future<void> toggleTask(TaskModel task) async {
    await sb.from('tasks').update({
      'is_done': !task.isDone,
    }).eq('id', task.id);
  }

  Future<void> deleteTask(String id) async {
    await sb.from('tasks').delete().eq('id', id);
  }

  Stream<List<ChatMessageModel>> chat(String familyId) {
    return sb
        .from('chat_message_feed')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at')
        .map((rows) =>
            rows.map((e) => ChatMessageModel.fromMap(e)).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  Future<void> sendChat({
    required String familyId,
    required String text,
  }) async {
    await sb.from('chat_messages').insert({
      'id': _uuid.v4(),
      'family_id': familyId,
      'text': text.trim(),
      'created_by': sb.auth.currentUser!.id,
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
    String? notes,
  }) async {
    await sb.from('events').insert({
      'id': _uuid.v4(),
      'family_id': familyId,
      'title': title.trim(),
      'notes': notes,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'created_by': sb.auth.currentUser!.id,
    });
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
}
