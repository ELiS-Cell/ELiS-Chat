import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // As chaves do Supabase serão inseridas aqui após a criação da sua conta.
  // Por enquanto, o app inicia sem travar para o GitHub Actions ficar verde.
  /*
  await Supabase.initialize(
    url: 'https://seu-projeto.supabase.co',
    anonKey: 'sua-chave-anonima',
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
        useMaterial3: true,
      ),
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
  final List<String> _messages = []; 
  final List<TextSpan> _currentTextSpans = [];
  int _currentCategory = 0;

  // Definição das categorias do teclado ELiS
  final Map<int, Map<String, dynamic>> _keyboardCategories = {
    0: {'name': 'CD', 'color': Colors.blue, 'keys': ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']},
    1: {'name': 'OP', 'color': Colors.amber, 'keys': ['l', 'ç', 'z', 'x', 'c', 'v']},
    2: {'name': 'PA', 'color': Colors.green, 'keys': ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I']},
    3: {'name': 'M', 'color': Colors.orange, 'keys': ['à', 'á', 'â', 'ã', 'è', 'é']},
    4: {'name': 'd.a', 'color': Colors.purple, 'keys': ['n', 'm', '<', '>', '§']},
    5: {'name': 'Pontos', 'color': Colors.pink, 'keys': ['//', ':', '.', '-']},
  };

  void _onKeyTap(String key) {
    setState(() {
      _currentTextSpans.add(TextSpan(
        text: key,
        style: const TextStyle(fontSize: 32, color: Colors.black, fontFamily: 'ElisFont'),
      ));
    });
  }

  void _sendMessage() {
    if (_currentTextSpans.isEmpty) return;
    setState(() {
      // Converte os símbolos digitados em uma string única
      String fullText = _currentTextSpans.map((e) => e.text).join();
      _messages.insert(0, fullText); 
      _currentTextSpans.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELiS Chat (Preview)', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Histórico de Mensagens
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, i) => Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF8C6),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                  ),
                  child: Text(_messages[i], style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
          
          // Campo de Digitação Visual
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    minHeight: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: RichText(
                      text: TextSpan(children: _currentTextSpans),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
                ),
              ],
            ),
          ),

          // Teclado ELiS
          _buildKeyboard(),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final cat = _keyboardCategories[_currentCategory]!;
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 25),
      child: Column(
        children: [
          // Seleção de Categorias
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(6, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_keyboardCategories[i]!['name']),
                  selected: _currentCategory == i,
                  onSelected: (val) => setState(() => _currentCategory = i),
                ),
              )),
            ),
          ),
          const SizedBox(height: 12),
          // Botões das Letras/Sinais
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: (cat['keys'] as List<String>).map((k) => InkWell(
              onTap: () => _onKeyTap(k),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat['color'],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2))],
                ),
                child: Center(
                  child: Text(k, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
