import 'package:flutter/material.dart';

void main() {
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
      appBar: AppBar(title: const Text("ELiS Chat"), backgroundColor: Colors.teal),
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
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: Text(_currentInput.join(""), style: const TextStyle(fontSize: 24))),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
          Container(
            height: 100,
            color: Colors.grey[200],
            child: Center(child: Text("Teclado ELiS aqui", style: TextStyle(color: Colors.grey))),
          )
        ],
      ),
    );
  }
}
