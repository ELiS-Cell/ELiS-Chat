import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  
  runApp(const ELiSApp());
}

final supabase = Supabase.instance.client;

class ELiSApp extends StatelessWidget {
  const ELiSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELiS Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFECE5DD),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session != null) {
          return const ContactsScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}

// ============ TELA DE LOGIN ============
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      _showError('Preencha email e senha');
      return;
    }

    setState(() {
      _loading = true;
    });
    
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showError('Erro ao fazer login: Email ou senha incorretos');
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      _showError('Preencha todos os campos');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        await supabase.from('profiles').upsert({
          'id': response.user!.id,
          'phone_number': _emailController.text.trim(),
          'display_name': _nameController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Conta criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showError('Erro ao criar conta: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
              const Icon(
                Icons.sign_language,
                size: 80,
                color: Color(0xFF075E54),
              ),
              const SizedBox(height: 24),
              const Text(
                'ELiS Chat',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF075E54),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comunicação em Escrita de Sinais',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 48),
              
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Seu nome',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'seu@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  hintText: 'Mínimo 6 caracteres',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_isSignUp ? _signUp : _signIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isSignUp ? 'Criar conta' : 'Entrar',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _nameController.clear();
                  });
                },
                child: Text(
                  _isSignUp 
                      ? 'Já tem conta? Entrar' 
                      : 'Não tem conta? Criar',
                  style: const TextStyle(color: Color(0xFF075E54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

// ============ TELA DE CONTATOS ============
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      
      final rooms = await supabase
          .from('room_participants')
          .select('room_id, chat_rooms!inner(id, name, is_group)')
          .eq('user_id', currentUserId);

      setState(() {
        _contacts = List<Map<String, dynamic>>.from(rooms);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar contatos: $e')),
        );
      }
    }
  }

 Future<void> _createNewChat() async {
  final emailController = TextEditingController();
  
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Novo Chat'),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: 'Email do contato',
          hintText: 'amigo@email.com',
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            final email = emailController.text.trim();
            if (email.isEmpty) return;
            
            Navigator.pop(context);
            
            try {
              // Buscar usuário
              final profiles = await supabase
                  .from('profiles')
                  .select()
                  .eq('phone_number', email);

              if (profiles.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuário não encontrado')),
                  );
                }
                return;
              }

              final contactId = profiles.first['id'];
              final currentUserId = supabase.auth.currentUser!.id;

              // Criar sala
              final room = await supabase
                  .from('chat_rooms')
                  .insert({'is_group': false, 'name': email})
                  .select()
                  .single();

              // Adicionar participantes
              await supabase.from('room_participants').insert([
                {'room_id': room['id'], 'user_id': currentUserId},
                {'room_id': room['id'], 'user_id': contactId},
              ]);

              _loadContacts();
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      roomId: room['id'],
                      roomName: email,
                    ),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: ${e.toString()}')),
                );
              }
            }
          },
          child: const Text('Criar'),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ELiS Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma conversa ainda',
                        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no + para começar',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final room = contact['chat_rooms'];
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF075E54),
                        child: Icon(
                          room['is_group'] ? Icons.group : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(room['name'] ?? 'Chat'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              roomId: room['id'],
                              roomName: room['name'] ?? 'Chat',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        backgroundColor: const Color(0xFF075E54),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ============ TELA DE CHAT ============
class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<InlineSpan> _textSpans = [];
  final _scrollController = ScrollController();
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
        'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ç', '\\',
        'Z', 'X', 'C', 'V', 'B', 'N', 'M', '@', '#', '\$', '%', '&', '*', '_'
      ],
    },
    3: {
      'name': 'M',
      'color': Colors.orange,
      'keys': [
        'à', 'á', 'â', 'ã', 'ä', 'è', 'é', 'ê', 'ë', 'ì', 'í', 'î', 'ï', 'ò', 'ó', 'ý', 'ô', 'õ', 'ö', 'ù', 'ú', 'û', 'ü',
        'À', 'Á', 'Â', 'Ã', 'Ä', 'È', 'É', 'Ê', 'Ë', 'Ì', 'Í', 'Î', 'Ï', 'Ñ', 'Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ù', 'Ú', 'Û', 'Ü'
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
              offset: const Offset(0, -8),
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'ElisFont',
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        );
      } else if (_punctuationKeys.contains(key)) {
        if (key == '//') {
          _textSpans.add(
            const TextSpan(
              text: '//',
              style: TextStyle(
                fontSize: 38.4,
                fontFamily: 'ElisFont',
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
                style: const TextStyle(
                  fontSize: 12.8,
                  fontFamily: 'ElisFont',
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
            style: const TextStyle(
              fontSize: 32,
              fontFamily: 'ElisFont',
              color: Colors.black87,
            ),
          ),
        );
      }
    });
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

    final messageText = _getRawText();
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase.from('messages').insert({
        'room_id': widget.roomId,
        'user_id': userId,
        'text': messageText,
      });

      final normalized = messageText.replaceAll(' ', '').trim();
      if (normalized.isNotEmpty) {
        final existing = await supabase
            .from('new_signs')
            .select()
            .eq('sign_text', normalized)
            .limit(1);

        if (existing.isEmpty) {
          await supabase.from('new_signs').insert({
            'sign_text': normalized,
            'discovered_by': userId,
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✨ Novo sinal descoberto!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          await supabase
              .from('new_signs')
              .update({'usage_count': (existing.first['usage_count'] as int) + 1})
              .eq('sign_text', normalized);
        }
      }

      setState(() {
        _textSpans.clear();
        _currentCategory = 0;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: $e')),
        );
      }
    }
  }

  void _backspace() {
    if (_textSpans.isEmpty) return;
    setState(() {
      _textSpans.removeLast();
    });
  }

  void _clearText() {
    setState(() {
      _textSpans.clear();
      _currentCategory = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF075E54),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('room_id', widget.roomId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma mensagem ainda.\nComece a digitar!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['user_id'] == userId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: const TextStyle(
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _textSpans.isEmpty
                        ? Text(
                            'Digite usando o teclado ELiS...',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          )
                        : RichText(text: TextSpan(children: _textSpans)),
                  ),
                ),
                const SizedBox(width: 8),
                if (_textSpans.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    color: Colors.grey.shade600,
                    onPressed: _clearText,
                  ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF075E54),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(6, (index) {
                        final category = _keyboardCategories[index]!;
                        final isActive = _currentCategory == index;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentCategory = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? category['color'] 
                                  : (category['color'] as Color).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: category['color'] as Color, width: 2),
                            ),
                            child: Text(
                              category['name'],
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
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
                      const
                      SizedBox(height: 6),
                      Row(
                        children: (category['subgroups']['Polegar'] as List<String>)
                            .map((key) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: _buildKey(key, color),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 2,
                    height: 50,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 20),
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
                      const SizedBox(height: 6),
                      Row(
                        children: (category['subgroups']['Demais Dedos'] as List<String>)
                            .map((key) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
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
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                child: ElevatedButton(
                  onPressed: _backspace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Icon(Icons.backspace, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onKeyTap(' '),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('ESPAÇO', style: TextStyle(fontSize: 14)),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'ElisFont',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
