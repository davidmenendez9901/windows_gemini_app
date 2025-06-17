import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../model/chat.dart';
import '../model/message.dart';

class DatabaseService {
  late Future<Isar> db;

  DatabaseService() {
    db = _initDB();
  }

  Future<Isar> _initDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [ChatSchema, MessageSchema],
        directory: dir.path,
        name: 'gemini_chat_db',
      );
    }
    return Future.value(Isar.getInstance());
  }

  Future<List<Chat>> getAllChats() async {
    final isar = await db;
    return await isar.chats.where().sortByCreatedAtDesc().findAll();
  }

  Future<Chat> createChat(Chat chat) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.chats.put(chat);
    });
    return chat;
  }

  Future<void> addMessageToChat(Chat chat, Message message) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.messages.put(message);
      await message.chat.save();
    });
  }

  Future<void> deleteChat(int chatId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      // Isar no elimina en cascada, así que borramos los mensajes primero
      await isar.messages.filter().chat((q) => q.idEqualTo(chatId)).deleteAll();
      // Luego borramos el chat
      await isar.chats.delete(chatId);
    });
  }

  Stream<List<Chat>> watchChats() async* {
    final isar = await db;
    yield* isar.chats.where().watch(fireImmediately: true);
  }
} 