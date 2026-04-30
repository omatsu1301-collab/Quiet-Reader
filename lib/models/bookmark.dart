import 'package:hive/hive.dart';

part 'bookmark.g.dart';

@HiveType(typeId: 2)
class Bookmark extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String documentId;

  @HiveField(2)
  late double position; // 0.0〜1.0

  @HiveField(3)
  String? label;

  @HiveField(4)
  late DateTime createdAt;

  Bookmark({
    required this.id,
    required this.documentId,
    required this.position,
    this.label,
    required this.createdAt,
  });
}
