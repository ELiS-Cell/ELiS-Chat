import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ELiSApp());
}

class ELiSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELiS Chat',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Color(0xFFECE5DD),
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
          return Scaffold(
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
      timeout: Duration(seconds: 60),
    );
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
        SnackBar(content: Text('Código inválido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECE5DD),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sign_language,
                size: 80,
                color: Color(0xFF075E54),
              ),
              SizedBox(height: 24),
              Text(
                'ELiS Chat',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075E54),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Comunicação em Escrita de Sinais',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              SizedBox(height: 48),
              
              if (!_codeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Número de telefone',
                    hintText: '(62) 99999-9999',
                    prefixText: '+55 ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyPhoneNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF075E54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Enviar código',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ] else ...[
                Text(
                  'Código enviado para ${_phoneController.text}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Código de verificação',
                    hintText: '123456',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signInWithCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF075E54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Verificar',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _codeSent = false;
                      _codeController.clear();
                    });
                  },
                  child: Text('Voltar'),
                ),
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
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  
  int _currentCategory = 0;

  final Set<String> _diacriticKeys = {'n', 'm', '<', '>', '§', 'ñ'};
  final Set<String> _punctuationKeys = {'//', 'b', '-', ':', '.', '"'};
  
  final Map<int, Map<String, dynamic>> _keyboardCategories = {
    0: {
      'name': 'CD',
      'color': Colors.blue,
      'hasSubgroups': true,
      'subgroups': {
        'Polegar': ['q', 'w', 'e', 'r', 't', 'y'],
        'Demais Dedos': ['u', 'i', 'o', 'p', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k'],
      },
    },
    1: {
      'name': 'OP',
      'color': Colors.amber.shade700,
      'keys': ['l', 'ç', 'z', 'x', 'c', 'v'],
    },
    2: {
      'name': 'PA',
      'color': Colors.green,
      'keys': [
        'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'A', 'S', 'D', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'Ç', '\\',
        'Z', 'X', 'C', 'V', 'B', 'N', 'M', '@', '#', '\$', '%', '&', '*', '_'
      ],
    },
    3: {
      'name': 'M',
      'color': Colors.orange,
      'keys': [
        'à', 'á', 'â', 'ã', 'ä', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï', 'ò', 'ó', 'ý', 'ô', 'õ', 'ö', 'ù', 'ú', 'û', 'ü',
        'À', 'Á', 'Â', 'Ã', 'Ä', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü'
      ],
    },
    4: {
      'name': 'd.a',
      'color': Colors.purple,
      'keys': ['n', 'm', '<', '>', '§', 'ñ'],
    },
    5: {
      'name': 'Pontuação',
      'color': Colors.pink,
      'keys': ['//', 'b', '-', ':', '.', '"'],
    },
  };

  void _onKeyTap(String key) {
    setState(() {
      if (_diacriticKeys.contains(key)) {
        _textSpans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, -8),
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'ElisFont',
                  fontFamilyFallback: const ['ElisFont'],
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        );
      } else if (_punctuationKeys.contains(key)) {
        if (key == '//') {
          _textSpans.add(
            TextSpan(
              text: key,
              style: TextStyle(
                fontSize: 38.4,
                fontFamily: 'ElisFont',
                fontFamilyFallback: const ['ElisFont'],
                color: Colors.black87,
              ),
            ),
          );
        } else {
          _textSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 12.8,
                  fontFamily: 'ElisFont',
                  fontFamilyFallback: const ['ElisFont'],
                  color: Colors.black87,
                ),
              ),
            ),
          );
        }
      } else {
        _textSpans.add(
          TextSpan(
            text: key,
            style: TextStyle(
              fontSize: 32,
              fontFamily: 'ElisFont',
              fontFamilyFallback: const ['ElisFont'],
              color: Colors.black87,
            ),
          ),
        );
      }
      _updateTextField();
    });
  }

  void _updateTextField() {
    _textController.text = _getRawText();
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );
  }

  String _getRawText() {
    String result = '';
    for (var span in _textSpans) {
      if (span is TextSpan && span.text != null) {
        result += span.text!;
      } else if (span is WidgetSpan) {
        final widget = span.child;
        if (widget is Transform) {
          final textWidget = widget.child as Text;
          result += textWidget.data ?? '';
        } else if (widget is Text) {
          result += widget.data ?? '';
        }
      }
    }
    return result;
  }

  Future<void> _sendMessage() async {
    if (_textSpans.isEmpty) return;
    
    String messageText = _getRawText();
    
    await _firestore.collection('mensagens').add({
      'texto': messageText,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    await _checkAndSaveNewSign(messageText);
    
    setState(() {
      _textSpans.clear();
      _textController.clear();
      _currentCategory = 0;
    });
    
    Future.delayed(Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _checkAndSaveNewSign(String signText) async {
    String normalizedSign = signText.replaceAll(' ', '').trim();
    if (normalizedSign.isEmpty) return;
    
    final querySnapshot = await _firestore
        .collection('novos_sinais')
        .where('sinal', isEqualTo: normalizedSign)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      await _firestore.collection('novos_sinais').add({
        'sinal': normalizedSign,
        'texto_original': signText,
        'descoberto_por': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'contagem_uso': 1,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Novo sinal descoberto e salvo!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      await _firestore
          .collection('novos_sinais')
          .doc(querySnapshot.docs.first.id)
          .update({
        'contagem_uso': FieldValue.increment(1),
      });
    }
  }

  void _backspace() {
    if (_textSpans.isEmpty) return;
    
    setState(() {
      _textSpans.removeLast();
      _updateTextField();
    });
  }

  void _clearText() {
    setState(() {
      _textSpans.clear();
      _textController.clear();
      _currentCategory = 0;
    });
  }

  void _selectCategory(int category) {
    setState(() {
      _currentCategory = category;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ELiS Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF075E54),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('mensagens')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar mensagens'));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma mensagem ainda.\nComece a digitar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                
                final messages = snapshot.data!.docs;
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['userId'] == userId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xFFDCF8C6) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Text(
                          messageData['texto'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'ElisFont',
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _textSpans.isEmpty
                        ? Text(
                            'Digite usando o teclado ELiS...',
                            style: TextStyle(
                              fontFamily: 'sans-serif',
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          )
                        : RichText(
                            text: TextSpan(children: _textSpans),
                          ),
                  ),
                ),
                SizedBox(width: 8),
                
                if (_textSpans.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear),
                    color: Colors.grey.shade600,
                    onPressed: _clearText,
                  ),
                
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF075E54),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Text(
                  'Categoria Atual: ${_keyboardCategories[_currentCategory]!['name']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(4, (index) {
                        final category = _keyboardCategories[index]!;
                        final isActive = _currentCategory == index;
                        
                        return GestureDetector(
                          onTap: () => _selectCategory(index),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? category['color'] 
                                  : category['color'].withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: category['color'], width: 2),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  category['name'],
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (index < 3) ...[
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: isActive ? Colors.white : Colors.black54,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                      
                      SizedBox(width: 16),
                      
                      GestureDetector(
                        onTap: () => _selectCategory(4),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _currentCategory == 4 
                                ? Colors.purple 
                                : Colors.purple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: Text(
                            'd.a',
                            style: TextStyle(
                              color: _currentCategory == 4 ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 8),
                      
                      GestureDetector(
                        onTap: () => _selectCategory(5),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _currentCategory == 5 
                                ? Colors.pink 
                                : Colors.pink.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.pink, width: 2),
                          ),
                          child: Text(
                            'Pontuação',
                            style: TextStyle(
                              color: _currentCategory == 5 ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          _buildCustomKeyboard(),
        ],
      ),
    );
  }

  Widget _buildCustomKeyboard() {
    final category = _keyboardCategories[_currentCategory]!;
    final color = category['color'] as Color;
    final hasSubgroups = category['hasSubgroups'] ?? false;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasSubgroups) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        'POLEGAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: (category['subgroups']['Polegar'] as List<String>)
                            .map((key) => Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  child: _buildKey(key, color),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  SizedBox(width: 20),
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(width: 20),
                  Column(
                    children: [
                      Text(
                        'DEMAIS DEDOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: (category['subgroups']['Demais Dedos'] as List<String>)
                            .map((key) => Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3),
                                  child: _buildKey(key, color),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: (category['keys'] as List<String>).map((key) {
                  return _buildKey(key, color);
                }).toList(),
              ),
            ),
          ],
          
          SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                child: ElevatedButton(
                  onPressed: _backspace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Icon(Icons.backspace, size: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onKeyTap(' '),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('ESPAÇO', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key, Color color) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ElevatedButton(
        onPressed: () => _onKeyTap(key),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: Text(
          key,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'ElisFont',
            fontFamilyFallback: const ['ElisFont'],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
