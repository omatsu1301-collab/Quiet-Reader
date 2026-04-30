import 'package:hive/hive.dart';

part 'work.g.dart';

@HiveType(typeId: 0)
class Work extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late DateTime updatedAt;

  Work({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}
