import 'package:hive/hive.dart';

part 'highlight.g.dart';

// ハイライト分類: good=良表現, fix=違和感, check=要確認
@HiveType(typeId: 3)
class Highlight extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String documentId;

  @HiveField(2)
  late int startOffset;

  @HiveField(3)
  late int endOffset;

  @HiveField(4)
  late String text;

  @HiveField(5)
  late String category; // 'good', 'fix', 'check'

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late DateTime updatedAt;

  Highlight({
    required this.id,
    required this.documentId,
    required this.startOffset,
    required this.endOffset,
    required this.text,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });
}
