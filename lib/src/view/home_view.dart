import 'package:fluent_ui/fluent_ui.dart' hide FluentIcons;
import 'package:flutter/widgets.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as f_icons;
import '../core/database_service.dart';
import '../core/gemini_service.dart';
import '../model/chat.dart';
import '../model/message.dart';
import 'settings_view.dart';

class HomeView extends StatefulWidget {
  final DatabaseService databaseService;
  const HomeView({super.key, required this.databaseService});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final List<String> _models = [
    'gemini-2.5-flash-preview-05-20',
    'gemini-2.5-pro-preview-06-05',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
  ];
  late String _selectedModel;
  bool _isLoading = false;

  Chat? _currentChat;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _selectedModel = _models.first;
    _loadInitialChat();
  }

  void _loadInitialChat() async {
    final chats = await widget.databaseService.getAllChats();
    if (chats.isNotEmpty) {
      _selectChat(chats.first);
    } else {
      _createNewChat();
    }
  }

  void _selectChat(Chat chat) {
    setState(() {
      _currentChat = chat;
      // IsarLinks son lazy, necesitamos cargarlos explícitamente si queremos usarlos síncronamente
      _messages = chat.messages.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  void _createNewChat() async {
    final newChat = Chat(createdAt: DateTime.now(), title: 'New Chat');
    await widget.databaseService.createChat(newChat);
    _selectChat(newChat);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendPrompt() async {
    if (_textController.text.isEmpty || _currentChat == null) return;
    final prompt = _textController.text;
    _textController.clear();

    final userMessage = Message(
      text: prompt,
      isUser: true,
      timestamp: DateTime.now(),
    );
    userMessage.chat.value = _currentChat;

    setState(() {
      _isLoading = true;
      _messages.add(userMessage);
    });
    _scrollToBottom();

    await widget.databaseService.addMessageToChat(_currentChat!, userMessage);

    // Creamos una copia de los mensajes para enviar a la API
    final messagesForApi = List<Message>.from(_messages);

    try {
      final response = await _geminiService.sendPrompt(
        messagesForApi,
        _selectedModel,
      );
      final modelMessage = Message(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
      modelMessage.chat.value = _currentChat;

      await widget.databaseService.addMessageToChat(
        _currentChat!,
        modelMessage,
      );

      setState(() {
        _messages.add(modelMessage);
      });
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Error'),
              content: Text(e.toString()),
              action: IconButton(
                icon: Icon(f_icons.FluentIcons.dismiss_24_regular),
                onPressed: close,
              ),
              severity: InfoBarSeverity.error,
            );
          },
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  void _deleteChat(Chat chat) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Chat?'),
        content: Text(
            'Are you sure you want to delete "${chat.title ?? 'Chat ${chat.id}'}"? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
          FilledButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      ),
    );
    if (result == true) {
      await widget.databaseService.deleteChat(chat.id);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Chat>>(
      stream: widget.databaseService.watchChats(),
      builder: (context, snapshot) {
        final chats = snapshot.data ?? [];

        // Sincronizar el chat actual si la lista cambia
        if (_currentChat != null &&
            !chats.any((c) => c.id == _currentChat!.id)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadInitialChat();
          });
        }

        final currentIndex = _currentChat == null
            ? 0
            : chats.indexWhere((c) => c.id == _currentChat!.id);

        return NavigationView(
          appBar: NavigationAppBar(
            title: Text(_currentChat?.title ?? 'Gemini App'),
            actions: SizedBox(
              width: 200,
              child: ComboBox<String>(
                isExpanded: true,
                value: _selectedModel,
                items: _models.map((model) {
                  return ComboBoxItem(
                    value: model,
                    child: Text(model, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedModel = value;
                    });
                  }
                },
              ),
            ),
          ),
          pane: NavigationPane(
            selected: currentIndex == -1 ? 0 : currentIndex,
            onChanged: (index) {
              if (index < chats.length) {
                _selectChat(chats[index]);
              }
            },
            header: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton(
                onPressed: _createNewChat,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(f_icons.FluentIcons.add_24_regular),
                    const SizedBox(width: 8),
                    const Text('New Chat'),
                  ],
                ),
              ),
            ),
            displayMode: PaneDisplayMode.auto,
            items: chats.map<NavigationPaneItem>((chat) {
              return PaneItem(
                key: ValueKey(chat.id),
                icon: Icon(f_icons.FluentIcons.chat_24_regular),
                title: Expanded(
                  child: Text(
                    chat.title ?? 'Chat ${chat.id}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(f_icons.FluentIcons.delete_24_regular),
                  onPressed: () => _deleteChat(chat),
                ),
                body: _buildChatView(),
              );
            }).toList(),
            footerItems: [
              PaneItemAction(
                icon: Icon(f_icons.FluentIcons.settings_24_regular),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.push(
                    context,
                    FluentPageRoute(builder: (context) => const SettingsView()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      "¿En qué puedo ayudarte hoy?",
                      style: FluentTheme.of(context).typography.title,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message.isUser
                                ? FluentTheme.of(context).accentColor
                                : FluentTheme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(message.text),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: ProgressRing(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _textController,
                    focusNode: _focusNode,
                    placeholder: 'Ask anything',
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _sendPrompt,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
