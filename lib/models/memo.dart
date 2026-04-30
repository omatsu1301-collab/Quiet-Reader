import 'package:hive/hive.dart';

part 'memo.g.dart';

@HiveType(typeId: 4)
class Memo extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String highlightId;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  Memo({
    required this.id,
    required this.highlightId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
}
