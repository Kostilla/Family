class UserProfileModel {
  final String id;
  final String email;
  final String displayName;
  final String? avatarPath;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarPath,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    final email = (map['email'] ?? '').toString();
    final fallback = email.contains('@') ? email.split('@').first : 'Usuario';
    final name = (map['display_name'] ?? map['name'] ?? '').toString().trim();
    return UserProfileModel(
      id: (map['id'] ?? '').toString(),
      email: email,
      displayName: name.isEmpty ? fallback : name,
      avatarPath: (map['avatar_path'] ?? map['avatar_url'])?.toString(),
    );
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length < 2 ? value.length : 2).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

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

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  factory FamilySummary.fromMap(Map<String, dynamic> map) {
    return FamilySummary(
      id: _string(map['family_id'] ?? map['id']),
      name: _string(map['family_name'] ?? map['name'], fallback: 'Familia'),
      role: _string(map['role'], fallback: 'adult'),
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
      id: (map['id'] ?? '').toString(),
      familyId: (map['family_id'] ?? '').toString(),
      text: (map['text'] ?? map['name'] ?? '').toString(),
      qty: map['qty']?.toString(),
      category: map['category']?.toString(),
      isDone: (map['is_done'] ?? map['done'] ?? false) as bool,
      listName: (map['list_name'] ?? 'principal').toString(),
      updatedAt: DateTime.tryParse((map['updated_at'] ?? map['created_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      addedBy: map['added_by']?.toString() ?? map['created_by']?.toString(),
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
        id: (map['id'] ?? '').toString(),
        familyId: (map['family_id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        notes: map['notes']?.toString(),
        isDone: (map['is_done'] ?? map['completed'] ?? false) as bool,
        dueAt: map['due_at'] != null ? DateTime.tryParse(map['due_at'].toString()) : null,
        createdBy: map['created_by']?.toString(),
        assignedTo: map['assigned_to']?.toString(),
        updatedAt: DateTime.tryParse((map['updated_at'] ?? map['created_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      );
}

class ChatMessageModel {
  final String id;
  final String familyId;
  final String text;
  final String createdBy;
  final String authorName;
  final String? authorAvatarPath;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.familyId,
    required this.text,
    required this.createdBy,
    required this.authorName,
    required this.authorAvatarPath,
    required this.createdAt,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) => ChatMessageModel(
        id: (map['id'] ?? '').toString(),
        familyId: (map['family_id'] ?? '').toString(),
        text: (map['text'] ?? map['content'] ?? '').toString(),
        createdBy: (map['created_by'] ?? map['author_id'] ?? '').toString(),
        authorName: (map['author_name'] ?? map['display_name'] ?? 'Usuario').toString(),
        authorAvatarPath: (map['author_avatar_path'] ?? map['avatar_path'] ?? map['avatar_url'])?.toString(),
        createdAt: DateTime.tryParse((map['created_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      );
}


class CalendarCategoryModel {
  final String id;
  final String familyId;
  final String name;
  final String color;
  final int sortOrder;

  CalendarCategoryModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.color,
    required this.sortOrder,
  });

  factory CalendarCategoryModel.fromMap(Map<String, dynamic> map) {
    return CalendarCategoryModel(
      id: (map['id'] ?? '').toString(),
      familyId: (map['family_id'] ?? '').toString(),
      name: (map['name'] ?? 'Categoría').toString(),
      color: (map['color'] ?? map['color_hex'] ?? '#3B82F6').toString(),
      sortOrder: map['sort_order'] is int ? map['sort_order'] as int : int.tryParse((map['sort_order'] ?? '0').toString()) ?? 0,
    );
  }
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
        id: (map['id'] ?? '').toString(),
        familyId: (map['family_id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        notes: map['notes']?.toString(),
        startAt: DateTime.tryParse((map['start_at'] ?? map['event_date'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
        endAt: DateTime.tryParse((map['end_at'] ?? map['event_date'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
        allDay: map['all_day'] as bool? ?? false,
        color: map['color']?.toString(),
        categoryId: map['category_id']?.toString(),
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
        id: (map['id'] ?? '').toString(),
        familyId: (map['family_id'] ?? '').toString(),
        day: DateTime.tryParse((map['day_date'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
        mealType: (map['meal_type'] ?? '').toString(),
        text: (map['text'] ?? '').toString(),
        createdBy: map['created_by']?.toString(),
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
        id: (map['id'] ?? '').toString(),
        familyId: (map['family_id'] ?? '').toString(),
        shoppingItemId: map['shopping_item_id']?.toString(),
        taskId: map['task_id']?.toString(),
        chatMessageId: map['chat_message_id']?.toString(),
        eventId: map['event_id']?.toString(),
        path: (map['storage_path'] ?? '').toString(),
        originalName: (map['original_name'] ?? '').toString(),
        mimeType: map['mime_type']?.toString(),
        sizeBytes: map['size_bytes'] as int?,
        createdBy: (map['created_by'] ?? '').toString(),
        createdAt: DateTime.tryParse((map['created_at'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      );
}

class SmartMenuIngredientModel {
  final String id;
  final String smartMenuId;
  final String name;
  final String? quantity;
  final String? unit;
  final int sortOrder;

  SmartMenuIngredientModel({
    required this.id,
    required this.smartMenuId,
    required this.name,
    this.quantity,
    this.unit,
    required this.sortOrder,
  });

  factory SmartMenuIngredientModel.fromMap(Map<String, dynamic> map) {
    return SmartMenuIngredientModel(
      id: (map['id'] ?? '').toString(),
      smartMenuId: (map['smart_menu_id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      quantity: map['quantity']?.toString(),
      unit: map['unit']?.toString(),
      sortOrder: map['sort_order'] is int ? map['sort_order'] as int : int.tryParse((map['sort_order'] ?? '0').toString()) ?? 0,
    );
  }

  String get displayName {
    final parts = <String>[];
    if (quantity != null && quantity!.trim().isNotEmpty) parts.add(quantity!.trim());
    if (unit != null && unit!.trim().isNotEmpty) parts.add(unit!.trim());
    if (parts.isEmpty) return name;
    return '$name (${parts.join(' ')})';
  }
}

class SmartMenuModel {
  final String id;
  final String familyId;
  final String name;
  final String mealType;
  final String? notes;
  final List<SmartMenuIngredientModel> ingredients;

  SmartMenuModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.mealType,
    this.notes,
    this.ingredients = const [],
  });

  factory SmartMenuModel.fromMap(Map<String, dynamic> map) {
    final rawIngredients = map['smart_menu_ingredients'] ?? map['ingredients'];
    final ingredients = rawIngredients is List
        ? rawIngredients
            .whereType<Map>()
            .map((e) => SmartMenuIngredientModel.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <SmartMenuIngredientModel>[];

    ingredients.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SmartMenuModel(
      id: (map['id'] ?? '').toString(),
      familyId: (map['family_id'] ?? '').toString(),
      name: (map['name'] ?? 'Menú').toString(),
      mealType: (map['meal_type'] ?? 'meal').toString(),
      notes: map['notes']?.toString(),
      ingredients: ingredients,
    );
  }
}

class SmartDailyMenuModel {
  final String id;
  final String familyId;
  final DateTime menuDate;
  final String mealSlot;
  final String smartMenuId;
  final bool shoppingConfirmed;
  final DateTime? shoppingConfirmedAt;
  final SmartMenuModel? menu;

  SmartDailyMenuModel({
    required this.id,
    required this.familyId,
    required this.menuDate,
    required this.mealSlot,
    required this.smartMenuId,
    required this.shoppingConfirmed,
    this.shoppingConfirmedAt,
    this.menu,
  });

  factory SmartDailyMenuModel.fromMap(Map<String, dynamic> map) {
    final menuMap = map['smart_menus'];
    return SmartDailyMenuModel(
      id: (map['id'] ?? '').toString(),
      familyId: (map['family_id'] ?? '').toString(),
      menuDate: DateTime.tryParse((map['menu_date'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      mealSlot: (map['meal_slot'] ?? 'lunch').toString(),
      smartMenuId: (map['smart_menu_id'] ?? '').toString(),
      shoppingConfirmed: (map['shopping_confirmed'] as bool?) ?? false,
      shoppingConfirmedAt: map['shopping_confirmed_at'] == null ? null : DateTime.tryParse(map['shopping_confirmed_at'].toString()),
      menu: menuMap is Map ? SmartMenuModel.fromMap(Map<String, dynamic>.from(menuMap)) : null,
    );
  }
}
