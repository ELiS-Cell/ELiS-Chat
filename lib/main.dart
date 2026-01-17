import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // O Supabase será inicializado aqui. 
  // Por enquanto, deixamos comentado para o seu Actions ficar VERDE e o app abrir.
  /*
  await Supabase.initialize(
    url: 'SUA_URL_DO_SUPABASE',
    anonKey: 'SUA_CHAVE_ANON_DO_SUPABASE',
  );
  */

  runApp(const ELiSApp());
}

class ELiSApp extends StatelessWidget {
  const ELiSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELiS Chat',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFECE5DD),
      ),
      // Começaremos direto na tela de Chat para testar a interface
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<String> _messages = []; // Lista temporária até conectarmos o banco
  final List<TextSpan> _currentTextSpans = [];
  int _currentCategory = 0;

  final Map<int, Map<String, dynamic>> _keyboardCategories = {
    0: {'name': 'CD', 'color': Colors.blue, 'keys': ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']},
    1: {'name': 'OP', 'color': Colors.amber, 'keys': ['l', 'ç', 'z', 'x', 'c', 'v']},
    2: {'name': 'PA', 'color': Colors.green, 'keys': ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I']},
    3: {'name': 'M', 'color': Colors.orange, 'keys': ['à', 'á', 'â', 'ã', 'è', 'é']},
    4: {'name': 'd.a', 'color': Colors.purple, 'keys': ['n', 'm', '<', '>', '§']},
    5: {'name': 'Pontuação', 'color': Colors.pink, 'keys': ['//', ':', '.', '-']},
  };

  void _onKeyTap(String key) {
    setState(() {
      _currentTextSpans.add(TextSpan(
        text: key,
        style: const TextStyle(fontSize: 32, color: Colors.black87),
      ));
    });
  }

  void _sendMessage() {
    if (_currentTextSpans.isEmpty) return;
    setState(() {
      String fullText = _currentTextSpans.map((e) => e.text).join();
      _messages.insert(0, fullText);
      _currentTextSpans.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELiS Chat (Preview)'),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(_messages[i], style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
          // Área de digitação
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: RichText(text: TextSpan(children: _currentTextSpans)),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
          // Teclado
          _buildKeyboard(),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final cat = _keyboardCategories[_currentCategory]!;
    return Container(
      color: Colors.grey[300],
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.all(4.0),
                child: ChoiceChip(
                  label: Text(_keyboardCategories[i]!['name']),
                  selected: _currentCategory == i,
                  onSelected: (val) => setState(() => _currentCategory = i),
                ),
              )),
            ),
          ),
          Wrap(
            padding: const EdgeInsets.all(8),
            spacing: 8,
            children: (cat['keys'] as List<String>).map((k) => ElevatedButton(
              onPressed: () => _onKeyTap(k),
              style: ElevatedButton.styleFrom(backgroundColor: cat['color']),
              child: Text(k, style: const TextStyle(color: Colors.white)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
