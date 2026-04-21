class FamilySummary {
  final String id;
  final String name;
  final String role;
  final bool isCurrent;

  FamilySummary({
    required this.id,
    required this.name,
    required this.role,
    required this.isCurrent,
  });

  factory FamilySummary.fromMap(Map<String, dynamic> map) {
    return FamilySummary(
      id: map['family_id'] as String,
      name: map['family_name'] as String,
      role: map['role'] as String,
      isCurrent: (map['is_current'] as bool?) ?? false,
    );
  }
}

class ShoppingItemModel {
  final String id;
  final String familyId;
  final String text;
  final String? qty;
  final String? category;
  final bool isDone;
  final String listName;
  final DateTime updatedAt;
  final String? addedBy;

  ShoppingItemModel({
    required this.id,
    required this.familyId,
    required this.text,
    required this.qty,
    required this.category,
    required this.isDone,
    required this.listName,
    required this.updatedAt,
    required this.addedBy,
  });

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] as String,
      familyId: map['family_id'] as String,
      text: map['text'] as String,
      qty: map['qty'] as String?,
      category: map['category'] as String?,
      isDone: map['is_done'] as bool? ?? false,
      listName: map['list_name'] as String? ?? 'principal',
      updatedAt: DateTime.parse(map['updated_at'] as String),
      addedBy: map['added_by'] as String?,
    );
  }
}

class TaskModel {
  final String id;
  final String familyId;
  final String title;
  final String? notes;
  final bool isDone;
  final DateTime? dueAt;
  final String? createdBy;
  final String? assignedTo;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.notes,
    required this.isDone,
    required this.dueAt,
    required this.createdBy,
    required this.assignedTo,
    required this.updatedAt,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id: map['id'] as String,
        familyId: map['family_id'] as String,
        title: map['title'] as String,
        notes: map['notes'] as String?,
        isDone: map['is_done'] as bool? ?? false,
        dueAt: map['due_at'] != null ? DateTime.parse(map['due_at'] as String) : null,
        createdBy: map['created_by'] as String?,
        assignedTo: map['assigned_to'] as String?,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}

class ChatMessageModel {
  final String id;
  final String familyId;
  final String text;
  final String createdBy;
  final String authorName;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.familyId,
    required this.text,
    required this.createdBy,
    required this.authorName,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) => ChatMessageModel(
        id: map['id'] as String,
        familyId: map['family_id'] as String,
        text: map['text'] as String,
        createdBy: map['created_by'] as String,
        authorName: (map['author_name'] as String?) ?? 'Usuario',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class EventModel {
  final String id;
  final String familyId;
  final String title;
  final String? notes;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String? color;
  final String? categoryId;

  EventModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.notes,
    required this.startAt,
    required this.endAt,
    required this.allDay,
    required this.color,
    required this.categoryId,
  });

  factory EventModel.fromMap(Map<String, dynamic> map) => EventModel(
        id: map['id'] as String,
        familyId: map['family_id'] as String,
        title: map['title'] as String,
        notes: map['notes'] as String?,
        startAt: DateTime.parse(map['start_at'] as String),
        endAt: DateTime.parse(map['end_at'] as String),
        allDay: map['all_day'] as bool? ?? false,
        color: map['color'] as String?,
        categoryId: map['category_id'] as String?,
      );
}

class MealEntryModel {
  final String id;
  final String familyId;
  final DateTime day;
  final String mealType;
  final String text;
  final String? createdBy;

  MealEntryModel({
    required this.id,
    required this.familyId,
    required this.day,
    required this.mealType,
    required this.text,
    required this.createdBy,
  });

  factory MealEntryModel.fromMap(Map<String, dynamic> map) => MealEntryModel(
        id: map['id'] as String,
        familyId: map['family_id'] as String,
        day: DateTime.parse(map['day_date'] as String),
        mealType: map['meal_type'] as String,
        text: map['text'] as String,
        createdBy: map['created_by'] as String?,
      );
}

class FamilyAttachment {
  final String id;
  final String familyId;
  final String? shoppingItemId;
  final String? taskId;
  final String? chatMessageId;
  final String? eventId;
  final String path;
  final String originalName;
  final String? mimeType;
  final int? sizeBytes;
  final String createdBy;
  final DateTime createdAt;

  FamilyAttachment({
    required this.id,
    required this.familyId,
    required this.shoppingItemId,
    required this.taskId,
    required this.chatMessageId,
    required this.eventId,
    required this.path,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdBy,
    required this.createdAt,
  });

  factory FamilyAttachment.fromMap(Map<String, dynamic> map) => FamilyAttachment(
        id: map['id'] as String,
        familyId: map['family_id'] as String,
        shoppingItemId: map['shopping_item_id'] as String?,
        taskId: map['task_id'] as String?,
        chatMessageId: map['chat_message_id'] as String?,
        eventId: map['event_id'] as String?,
        path: map['storage_path'] as String,
        originalName: map['original_name'] as String,
        mimeType: map['mime_type'] as String?,
        sizeBytes: map['size_bytes'] as int?,
        createdBy: map['created_by'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
