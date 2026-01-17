import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ELiSApp());
}

class ELiSApp extends StatelessWidget {
  const ELiSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELiS Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
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
  final List<String> _currentInput = [];

  void _addSymbol(String symbol) {
    setState(() => _currentInput.add(symbol));
  }

  void _send() {
    if (_currentInput.isEmpty) return;
    setState(() {
      _messages.insert(0, _currentInput.join(""));
      _currentInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ELiS Chat", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, i) => Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCF8C6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_messages[i], style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentInput.isEmpty ? "Digite em ELiS..." : _currentInput.join(""),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF075E54)),
                  onPressed: _send,
                ),
              ],
            ),
          ),
          _buildKeyboard(),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final List<String> keys = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      color: Colors.grey[200],
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: keys.map((k) => ElevatedButton(
          onPressed: () => _addSymbol(k),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: Text(k, style: const TextStyle(color: Colors.white, fontSize: 18)),
        )).toList(),
      ),
    );
  }
}
