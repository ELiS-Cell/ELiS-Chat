import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização segura para Web
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSy... (seu-codigo)", 
        appId: "1:12345... (seu-id)",
        messagingSenderId: "12345",
        projectId: "elis-chat",
      ),
    );
  } catch (e) {
    print("Firebase não configurado, mas iniciando app: $e");
  }

  runApp(ELiSApp());
}

class ELiSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELiS Chat',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFECE5DD),
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return ChatScreen();
        }
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String _verificationId = '';
  bool _codeSent = false;
  bool _loading = false;

  Future<void> _verifyPhoneNumber() async {
    setState(() => _loading = true);
    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+')) {
      phoneNumber = '+55' + phoneNumber;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _loading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _signInWithCode() async {
    setState(() => _loading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sign_language, size: 80, color: Color(0xFF075E54)),
              const SizedBox(height: 24),
              const Text('ELiS Chat', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF075E54))),
              Text('Comunicação em Escrita de Sinais', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              const SizedBox(height: 48),
              if (!_codeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Número de telefone',
                    hintText: '(62) 99999-9999',
                    prefixText: '+55 ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyPhoneNumber,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar código', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ] else ...[
                Text('Código enviado para ${_phoneController.text}', style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Código de verificação',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signInWithCode,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Verificar', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                TextButton(onPressed: () => setState(() => _codeSent = false), child: const Text('Voltar')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<InlineSpan> _textSpans = [];
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';
  int _currentCategory = 0;

  final Set<String> _diacriticKeys = {'n', 'm', '<', '>', '§', 'ñ'};
  final Set<String> _punctuationKeys = {'//', 'b', '-', ':', '.', '"'};

  final Map<int, Map<String, dynamic>> _keyboardCategories = {
    0: {'name': 'CD', 'color': Colors.blue, 'hasSubgroups': true, 'subgroups': {'Polegar': ['q', 'w', 'e', 'r', 't', 'y'], 'Demais Dedos': ['u', 'i', 'o', 'p', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k']}},
    1: {'name': 'OP', 'color': const Color(0xFFFFA000), 'keys': ['l', 'ç', 'z', 'x', 'c', 'v']},
    2: {'name': 'PA', 'color': Colors.green, 'keys': ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ç', '\\', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '@', '#', '\$', '%', '&', '*', '_']},
    3: {'name': 'M', 'color': Colors.orange, 'keys': ['à', 'á', 'â', 'ã', 'ä', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï', 'ò', 'ó', 'ý', 'ô', 'õ', 'ö', 'ù', 'ú', 'û', 'ü']},
    4: {'name': 'd.a', 'color': Colors.purple, 'keys': ['n', 'm', '<', '>', '§', 'ñ']},
    5: {'name': 'Pontuação', 'color': Colors.pink, 'keys': ['//', 'b', '-', ':', '.', '"']},
  };

  void _onKeyTap(String key) {
    setState(() {
      if (_diacriticKeys.contains(key)) {
        _textSpans.add(WidgetSpan(child: Transform.translate(offset: const Offset(0, -8), child: Text(key, style: const TextStyle(fontSize: 16, fontFamily: 'ElisFont')))));
      } else {
        _textSpans.add(TextSpan(text: key, style: const TextStyle(fontSize: 32, fontFamily: 'ElisFont')));
      }
      _updateTextField();
    });
  }

  void _updateTextField() {
    _textController.text = _getRawText();
  }

  String _getRawText() {
    String result = '';
    for (var span in _textSpans) {
      if (span is TextSpan) result += span.text ?? '';
      if (span is WidgetSpan && span.child is Transform) {
        result += ((span.child as Transform).child as Text).data ?? '';
      }
    }
    return result;
  }

  Future<void> _sendMessage() async {
    if (_textSpans.isEmpty) return;
    String messageText = _getRawText();
    await _firestore.collection('mensagens').add({'texto': messageText, 'userId': userId, 'timestamp': FieldValue.serverTimestamp()});
    setState(() { _textSpans.clear(); _textController.clear(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ELiS Chat'), backgroundColor: const Color(0xFF075E54), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())]),
      body: Column(
        children: [
          Expanded(child: Container(color: Colors.white)), // Espaço para mensagens
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)), child: _textSpans.isEmpty ? const Text('Digite em ELiS...') : RichText(text: TextSpan(children: _textSpans, style: const TextStyle(color: Colors.black))))),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
          _buildKeyboard(),
        ],
      ),
    );
  }

  Widget _buildKeyboard() {
    final cat = _keyboardCategories[_currentCategory]!;
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(6, (i) => ActionChip(label: Text(_keyboardCategories[i]!['name']), onPressed: () => setState(() => _currentCategory = i)))),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: (cat['keys'] != null ? (cat['keys'] as List<String>) : [...cat['subgroups']['Polegar'], ...cat['subgroups']['Demais Dedos']]).map((k) => ElevatedButton(onPressed: () => _onKeyTap(k), child: Text(k))).toList()),
        ],
      ),
    );
  }
}
