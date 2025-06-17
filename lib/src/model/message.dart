import 'package:isar/isar.dart';
import 'chat.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  final chat = IsarLink<Chat>();

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
} 