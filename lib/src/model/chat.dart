import 'package:isar/isar.dart';
import 'message.dart';

part 'chat.g.dart';

@collection
class Chat {
  Id id = Isar.autoIncrement;
  String? title;
  final DateTime createdAt;

  @Backlink(to: 'chat')
  final messages = IsarLinks<Message>();

  Chat({
    this.title,
    required this.createdAt,
  });
} 