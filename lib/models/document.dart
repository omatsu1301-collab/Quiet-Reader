import 'package:hive/hive.dart';

part 'document.g.dart';

@HiveType(typeId: 1)
class Document extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String workId;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late String type; // 本文, 初稿, 推敲稿, プロット, キャラシート, その他

  @HiveField(4)
  late String body;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  @HiveField(7)
  double lastReadPosition; // 0.0〜1.0

  @HiveField(8)
  DateTime? lastOpenedAt;

  Document({
    required this.id,
    required this.workId,
    required this.title,
    required this.type,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.lastReadPosition = 0.0,
    this.lastOpenedAt,
  });
}
