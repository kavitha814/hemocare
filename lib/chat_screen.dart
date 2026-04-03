import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'globals.dart';
import 'translations.dart';
import 'user_profile_icon.dart';
import 'home_screen.dart';


void main() {
  runApp(const GeminiChatApp());
}

class GeminiChatApp extends StatelessWidget {
  const GeminiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareConnect AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A89DC), // Medical Blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Replace with your actual Gemini API Key
  static const _apiKey = 'AIzaSyDiIxBLpborMXx0-9pm_P0jafFsuY0UejU';
  
  late GenerativeModel _model;
  late ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  final List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _isSpeaking = false; 
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _hasText = false; 
  int? _playingIndex; 

  // Session management
  String? _currentSessionId;
  List<dynamic> _sessions = [];
  String _searchQuery = '';
  String _profileName = 'User';
  String? _currentChatTitle;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // System instructions to enforce behavior
  static const String _systemPrompt = '''
You are CareConnect AI, a dedicated health assistant. 
RULES:
1. Answer ONLY medical and health-related queries. Reject all others politely.
2. DO NOT prescribe specific medicines. If asked for a prescription, refuse and advise consulting a doctor.
3. You CAN explain the uses of a medicine if explicitly asked (e.g., "What is Paracetamol used for?").
4. If an image is uploaded (prescription, handwritten note, or photo), analyze it. IDENTIFY each medicine mentioned and explain its DETAILS and USES. Do not suggest treatments or change existing prescriptions.
		5. Keep responses CONCISE: Minimum 2 lines, Maximum 5 lines.
		6. MANDATORY: Use bullet points for all lists and key information.
		7. Tone: Professional, empathetic, educational.
		8. STRICTOR LANGUAGE RULE: Use ONLY the alphabet/script of the requested language. Do not mix scripts.
    9. REMEMBER PREVIOUS CONTEXT. If the user refers to "it" or "that", look at the previous messages.
    10. BE ACCESSIBLE: Ignore minor spelling mistakes or typos (e.g., if the user types 'fewer' instead of 'fever'). Infer the user's health-related intent and answer accordingly.
    11. URGENCY CLASSIFICATION: At the end of every response, if and ONLY if the user is reporting personal symptoms or seeking an immediate health assessment, include a classification tag: [[URGENCY:LEVEL|REASON:Reason text|ACTION:Action steps|WARNING:Danger signs]]. 
        - LEVEL: Use LOW, MEDIUM, or HIGH.
        - TRIGGER: Only trigger this if the user describes a current physical condition they are experiencing.
        - GENERAL INQUIRIES: If the user asks for definitions, general health facts, or "what is" type questions without reporting a personal condition, use [[URGENCY:NONE]].
		''';

  @override
  void initState() {
    super.initState();
    _initGemini();
    _initSpeech();
    _initTts();
    _loadCachedSessions();
    _fetchSessions();
    _loadCachedUserData();
    _fetchUserData();
    
    // Listen for language changes
    languageNotifier.addListener(_updateChatModel);

    // Listen to text changes for send button
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    languageNotifier.removeListener(_updateChatModel);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateChatModel() async {
     final lang = languageNotifier.value;
     debugPrint("Antigravity: Updating chat model for language: $lang");
     
     // Re-initialize model with new language prompt
     final String localizedPrompt = "$_systemPrompt\n\nCRITICAL: You MUST respond ONLY in $lang. Even if I type in English or any other language, you MUST first translate the context into $lang and respond ONLY in the $lang script. Do not use English words unless they are medical terms with no $lang equivalent.";
    
     final newModel = GenerativeModel(
       model: 'gemini-2.5-flash', 
       apiKey: _apiKey,
       systemInstruction: Content.system(localizedPrompt),
     );
     
     // Convert current _messages to history for the new model instance
     final List<Content> history = [];
     for (var msg in _messages) {
       // Skip the internal welcome messages if they are system-like or repetitive
       if (msg.text.contains("I'm CareConnect AI") || msg.text.contains("Hello! I'm CareConnect AI")) continue;
       
       if (msg.isUser) {
         history.add(Content.text(msg.text));
       } else {
         history.add(Content.model([TextPart(msg.text)]));
       }
     }

     setState(() {
       _model = newModel;
       _chat = _model.startChat(history: history);
     });

     await _updateTtsLanguage();
  }

  void _initGemini() {
    final lang = languageNotifier.value;
    final String localizedPrompt = "$_systemPrompt\n\nCRITICAL: You MUST respond ONLY in $lang. Even if I type in English or any other language, you MUST first translate the context into $lang and respond ONLY in the $lang script. Do not use English words unless they are medical terms with no $lang equivalent.";

    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
      systemInstruction: Content.system(localizedPrompt),
    );
    _chat = _model.startChat(
      history: [
        Content.text("Hello"),
        Content.model([TextPart(AppTranslations.get('welcome_chat', lang))])
      ],
    );
    
    // Initial greeting
    _messages.add(ChatMessage(
      text: "Hello! I'm CareConnect AI, your health assistant. How can I help you today?",
      isUser: false,
      timestamp: "Just now",
    ));
  }

  Future<void> _loadCachedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_chat_sessions');
    if (cached != null) {
      if (mounted) {
        setState(() {
          _sessions = jsonDecode(cached);
        });
      }
    }
  }

  Future<void> _fetchSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/chats/sessions'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Fetch Sessions Status: ${response.statusCode}");
      debugPrint("Fetch Sessions Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _sessions = data;
        });
        await prefs.setString('cached_chat_sessions', response.body);
        debugPrint("Sessions count: ${_sessions.length}");
      }
    } catch (e) {
      debugPrint("Error fetching sessions: $e");
    }
  }

  Future<void> _loadSession(String sessionId) async {
    setState(() {
      _loading = true;
      _currentSessionId = sessionId;
      _messages.clear();
      // Set chat title from sessions list
      final session = _sessions.firstWhere((s) => s['_id'] == sessionId, orElse: () => null);
      _currentChatTitle = session != null ? session['title'] : "Old Chat";

      if (Navigator.canPop(context)) Navigator.pop(context); // Close drawer
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/chats/session/$sessionId'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);
        final List<Content> aiHistory = [];
        
        setState(() {
          for (var item in history) {
            final text = item['text'] ?? "";
            final isUser = item['isUser'] ?? false;
            final String? msgId = item['_id']?.toString();
            final DateTime? rawTs = item['timestamp'] != null ? DateTime.parse(item['timestamp']) : null;
            
            _messages.add(ChatMessage(
              id: msgId,
              text: text,
              isUser: isUser,
              timestamp: _formatTimestamp(item['timestamp']),
              rawTimestamp: rawTs,
              urgency: item['urgency'] ?? 'none',
              urgencyReason: item['urgencyReason'] ?? '',
              urgencyAction: item['urgencyAction'] ?? '',
              urgencyWarning: item['urgencyWarning'] ?? '',
            ));

            // Populate AI history
            if (isUser) {
              aiHistory.add(Content.text(text));
            } else {
              aiHistory.add(Content.model([TextPart(text)]));
            }
          }

          // Restart Gemini session with history
          _chat = _model.startChat(history: aiHistory);
          _loading = false;
        });
        _scrollDown();
      }
    } catch (e) {
      debugPrint("Error loading session: $e");
      setState(() => _loading = false);
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return "Just now";
    final dt = DateTime.parse(ts).toLocal();
    return "${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
  }

  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _currentChatTitle = null;
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Hello! I'm CareConnect AI, a new session has started. How can I help?",
        isUser: false,
        timestamp: "Just now",
      ));
      
      // CRITICAL: Reset the AI session as well
      _chat = _model.startChat(history: []);
      
      if (Navigator.canPop(context)) Navigator.pop(context); // Close drawer
    });
  }

  Future<void> _loadCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileName = prefs.getString('profile_name') ?? 'Siva Selvarasu';
      });
    }
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileName = prefs.getString('profile_name') ?? 'Siva Selvarasu';
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (val) => debugPrint('Speech error: $val'),
      onStatus: (val) => debugPrint('Speech status: $val'),
    );
    if(mounted) setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);

    _flutterTts.setCompletionHandler(() {
      if(mounted) {
        setState(() {
          _playingIndex = null;
        });
      }
    });

    _flutterTts.setCancelHandler(() {
      if(mounted) {
        setState(() {
          _playingIndex = null;
        });
      }
    });
  }

  Future<void> _updateTtsLanguage() async {
    String langCode = "en-US";
    final currentLang = languageNotifier.value;
    if (currentLang == "Tamil") langCode = "ta-IN";
    else if (currentLang == "Hindi") langCode = "hi-IN";
    else if (currentLang == "Malayalam") langCode = "ml-IN";
    else if (currentLang == "Telugu") langCode = "te-IN";
    else if (currentLang == "Kannada") langCode = "kn-IN";
    
    await _flutterTts.setLanguage(langCode);
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      if (!kIsWeb) {
        var status = await Permission.microphone.request();
        if (!status.isGranted) return;
      }
      _initSpeech();
    }
    
    String localeId = "en-US";
    final currentLang = languageNotifier.value;
    if (currentLang == "Tamil") localeId = "ta-IN";
    else if (currentLang == "Hindi") localeId = "hi-IN";
    else if (currentLang == "Malayalam") localeId = "ml-IN";
    else if (currentLang == "Telugu") localeId = "te-IN";
    else if (currentLang == "Kannada") localeId = "kn-IN";

    await _speech.listen(
      onResult: (val) {
        setState(() {
          _textController.text = val.recognizedWords;
          _isListening = true;
        });
      },
      localeId: localeId,
    );
    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _handleSpeech(int index, String text) async {
    if (_playingIndex == index) {
      // currently speaking this message -> STOP
      await _flutterTts.stop();
      setState(() {
        _playingIndex = null;
      });
    } else {
      // speaking something else or nothing -> START this
      await _flutterTts.stop(); // Stop potential previous
      await _updateTtsLanguage(); // Update language
      setState(() {
        _playingIndex = index;
      });
      await _flutterTts.speak(text);
    }
  }

  Future<void> _saveMessageToBackend(String text, bool isUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      int currentMsgIndex = _messages.lastIndexWhere((m) => m.text == text && m.isUser == isUser);
      final msg = currentMsgIndex != -1 ? _messages[currentMsgIndex] : null;

      final response = await http.post(
        Uri.parse('$apiBaseUrl/chats'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'text': text,
          'isUser': isUser,
          'sessionId': _currentSessionId,
          'title': _messages.firstWhere((m) => m.isUser, orElse: () => _messages.first).text,
          'urgency': msg?.urgency ?? 'none',
          'urgencyReason': msg?.urgencyReason ?? '',
          'urgencyAction': msg?.urgencyAction ?? '',
          'urgencyWarning': msg?.urgencyWarning ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final savedChat = jsonDecode(response.body);
        
        // Find the message in the current list to update its ID
        // We match by text and isUser since multiple messages might be pending
        int msgIndex = _messages.lastIndexWhere((m) => m.text == text && m.isUser == isUser && m.id == null);
        
        if (msgIndex != -1) {
          final oldMsg = _messages[msgIndex];
          setState(() {
            _messages[msgIndex] = ChatMessage(
              id: savedChat['_id']?.toString(),
              text: oldMsg.text,
              isUser: oldMsg.isUser,
              timestamp: oldMsg.timestamp,
              rawTimestamp: savedChat['timestamp'] != null ? DateTime.parse(savedChat['timestamp']) : null,
              imagePath: oldMsg.imagePath,
              imageFile: oldMsg.imageFile,
              urgency: oldMsg.urgency,
              urgencyReason: oldMsg.urgencyReason,
              urgencyAction: oldMsg.urgencyAction,
              urgencyWarning: oldMsg.urgencyWarning,
            );
          });
        }

        if (_currentSessionId == null) {
          setState(() {
            _currentSessionId = savedChat['sessionId'];
          });
          _fetchSessions();
        }
      } else {
        debugPrint("Failed to save message to backend: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error saving message: $e");
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _sendChatMessage(String message, {XFile? image}) async {
    if (message.trim().isEmpty && image == null) return;

    if (_currentSessionId == null) {
       _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    setState(() {
      _loading = true;
      _messages.add(ChatMessage(
        text: message,
        imagePath: image?.path,
        imageFile: image, 
        isUser: true,
        timestamp: _getCurrentTime(),
      ));
    });

    // Set chat title if it's the first message
    if (_messages.length == 2 && _currentChatTitle == null) {
      _currentChatTitle = message.length > 30 ? "${message.substring(0, 27)}..." : message;
    }

    // Save user message to backend
    _saveMessageToBackend(message.isEmpty && image != null ? "[Image Uploaded]" : message, true);

    try {
      _textController.clear();
      _scrollDown();

      GenerateContentResponse? response;
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        
        final content = Content.multi([
          TextPart(message.isEmpty ? "Analyze this image." : message),
          DataPart('image/jpeg', imageBytes),
        ]);
        
        response = await _chat.sendMessage(content);

      } else {
        response = await _chat.sendMessage(Content.text(message));
      }

      String? text = response.text;
      String urgency = 'none';
      String urgencyReason = '';
      String urgencyAction = '';
      String urgencyWarning = '';

      if (text != null) {
        // Updated regex to catch structured block: [[URGENCY:LEVEL|REASON:text|ACTION:text|WARNING:text]]
        final urgencyMatch = RegExp(r'\[\[URGENCY:(LOW|MEDIUM|HIGH|NONE)(?:\|REASON:(.*?))?(?:\|ACTION:(.*?))?(?:\|WARNING:(.*?))?\]\]', dotAll: true).firstMatch(text);
        if (urgencyMatch != null) {
          urgency = urgencyMatch.group(1)!.toLowerCase();
          urgencyReason = urgencyMatch.group(2)?.trim() ?? '';
          urgencyAction = urgencyMatch.group(3)?.trim() ?? '';
          urgencyWarning = urgencyMatch.group(4)?.trim() ?? '';
          text = text.replaceFirst(urgencyMatch.group(0)!, '').trim();
        }
      }

      setState(() {
        _loading = false;
        if (text != null) {
          _messages.add(ChatMessage(
            text: text,
            isUser: false,
            timestamp: _getCurrentTime(),
            urgency: urgency,
            urgencyReason: urgencyReason,
            urgencyAction: urgencyAction,
            urgencyWarning: urgencyWarning,
          ));
          // Save bot response to backend
          _saveMessageToBackend(text, false);
        }
      });
      _scrollDown();

    } catch (e) {
      setState(() {
        _loading = false;
        _messages.add(ChatMessage(
          text: "I encountered an error. Please try again or check your internet connection.",
          isUser: false,
          timestamp: _getCurrentTime(),
        ));
      });
      debugPrint("Error: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      _sendChatMessage("Analyzed uploaded image:", image: image);
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: _buildSidebar(lang),
          drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.2, // Increased sensitivity
          body: SafeArea(
            child: Column(
              children: [
                // Custom Top Bar (Centered Layout)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // Sidebar Toggle (Left)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.short_text_rounded, color: Color(0xFF0D2B28), size: 32),
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                        ),
                        
                        // Dynamic Title Area (Perfectly Centered)
                        Center(
                          child: _messages.length <= 1 
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00A98F).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'CareConnect',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF0D2B28).withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: _showSessionContextMenu,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.45),
                                      child: Text(
                                        _currentChatTitle ?? "Chat",
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF0D2B28),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 20),
                                  ],
                                ),
                              ),
                        ),
                        
                        // Action icons (Right)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_messages.length <= 1)
                                const EmergencyHelpIcon(),
                              
                              if (_messages.length > 1)
                                IconButton(
                                  onPressed: _startNewChat,
                                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF0D2B28), size: 28),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Main Chat Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FFFE),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        
                        // Chat Area
                        Expanded(
                          child: _messages.length <= 1 
                            ? _buildLandingScreen(lang)
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                    return MessageWidget(
                                      message: msg,
                                      isPlaying: _playingIndex == index,
                                      onSpeakTap: () => _handleSpeech(index, msg.text),
                                      onCopyTap: () {
                                        Clipboard.setData(ClipboardData(text: msg.text));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Message copied to clipboard'), duration: Duration(seconds: 1)),
                                        );
                                      },
                                      onShareTap: () {
                                        Share.share(msg.text);
                                      },
                                       onLongPress: _showMessageContextMenu,
                                     );
                                },
                              ),
                        ),
                        
                        if (_loading)
                          Padding(
                            padding: const EdgeInsets.only(left: 32, bottom: 24),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16, 
                                  height: 16, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D1C1))
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppTranslations.get('typing', lang), 
                                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13)
                                ),
                              ],
                            ),
                          ),

                        // Input Area
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Row(
                            children: [
                              // Plus Icon
                              GestureDetector(
                                onTap: () => _showImageSourceSheet(),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE8F8F6),
                                    border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.2)),
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Color(0xFF00A98F), size: 28),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Input Bar
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEFBFA),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: const Color(0xFFD1F0EC)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _textController,
                                          style: const TextStyle(color: Color(0xFF0D2B28), fontSize: 14),
                                          decoration: InputDecoration(
                                            hintText: AppTranslations.get('ask_careconnect', lang),
                                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          ),
                                          onSubmitted: (val) => _sendChatMessage(val),
                                        ),
                                      ),
                                      // Mic Icon inside
                                      IconButton(
                                        icon: Icon(
                                          _isListening ? Icons.mic_off : Icons.mic_rounded, 
                                          color: _isListening ? Colors.red : const Color(0xFF00A98F),
                                          size: 20,
                                        ),
                                        onPressed: _isListening ? _stopListening : _startListening,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Send Button
                              GestureDetector(
                                onTap: _hasText ? () => _sendChatMessage(_textController.text) : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _hasText ? const Color(0xFF00A98F) : const Color(0xFFE8F8F6),
                                    boxShadow: _hasText ? [
                                      BoxShadow(
                                        color: const Color(0xFF00A98F).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ] : [],
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward_rounded, 
                                    color: _hasText ? Colors.white : const Color(0xFFB0BEC5),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandingScreen(String lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi ${_profileName.split(' ')[0]}",
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Where should we start?",
            style: GoogleFonts.poppins(
              color: const Color(0xFF0D2B28),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildSuggestionItem(
            icon: Icons.biotech_outlined,
            title: "Common Diseases",
            onTap: () => _sendChatMessage("Tell me about some common diseases and their symptoms."),
          ),
          _buildSuggestionItem(
            icon: Icons.health_and_safety_outlined,
            title: "Healthy Habits",
            onTap: () => _sendChatMessage("What are some daily healthy habits I should follow?"),
          ),
          _buildSuggestionItem(
            icon: Icons.vaccines_outlined,
            title: "Vaccination Info",
            onTap: () => _sendChatMessage("Give me a brief overview of important vaccinations."),
          ),
          _buildSuggestionItem(
            icon: Icons.medical_services_outlined,
            title: "Medical Disclaimer",
            onTap: () => _sendChatMessage("What is your medical disclaimer?"),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 205, // Adjusted to fit "Medical Disclaimer" perfectly
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEFBFA),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00A98F), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0D2B28),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(String lang) {
    // Filter sessions based on search query
    final filteredSessions = _sessions.where((s) {
      final title = (s['title'] ?? "").toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          
          // Header Row: Search + New Chat Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEFBFA),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Color(0xFF0D2B28), fontSize: 14),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: AppTranslations.get('search_chats_hint', lang),
                        hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00A98F), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _startNewChat,
                  icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF00A98F), size: 28),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your chats", 
                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w400)
                ),
                GestureDetector(
                  onTap: _fetchSessions,
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFF00A98F), size: 16),
                ),
              ],
            ),
          ),
          
          const Divider(color: Color(0xFFE2F7F5)),
          
          Expanded(
            child: filteredSessions.isEmpty 
              ? Center(
                  child: Text(
                    "No sessions found", 
                    style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 12)
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filteredSessions.length,
                  itemBuilder: (context, index) {
                    final session = filteredSessions[index];
                    final String sId = session['_id']?.toString() ?? "";
                    final bool isSelected = sId == _currentSessionId;
                    
                    return ListTile(
                      onTap: () => _loadSession(sId),
                      onLongPress: () => _showSessionOptions(sId, session['title'] ?? "Untitled Chat", session['isPinned'] ?? false),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: isSelected ? const Color(0xFF00A98F).withOpacity(0.1) : Colors.transparent,
                      leading: Icon(
                        session['isPinned'] == true ? Icons.push_pin_rounded : Icons.chat_bubble_outline_rounded, 
                        color: isSelected ? const Color(0xFF00A98F) : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      title: Text(
                        session['title'] ?? "Untitled Chat",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: isSelected ? const Color(0xFF00A98F) : const Color(0xFF334155),
                          fontSize: 13,
                        ),
                      ),
                      trailing: session['isPinned'] == true 
                        ? const Icon(Icons.push_pin_rounded, color: Color(0xFF00A98F), size: 12)
                        : null,
                    );
                  },
                ),
          ),
          
          // Bottom Profile Section
          const Divider(color: Color(0xFFE2F7F5)),
          InkWell(
            onTap: () {
              Navigator.pop(context); // Close drawer
              homeTabNotifier.value = 3; // Switch to profile tab
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Row(
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: profileImageNotifier,
                    builder: (context, imagePath, _) {
                      if (imagePath != null && imagePath.isNotEmpty) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundImage: FileImage(File(imagePath)),
                        );
                      }
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF00A98F).withOpacity(0.2),
                        child: Text(
                          _profileName.isNotEmpty ? _profileName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _profileName,
                      style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14, fontWeight: FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionOptions(String sId, String currentTitle, bool isPinned) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuOption(
                  icon: Icons.edit_outlined,
                  label: "Rename",
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameDialog(sId, currentTitle);
                  },
                ),
                _buildMenuOption(
                  icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin_outlined, // Both use outlined per screenshot
                  label: isPinned ? "Unpin chat" : "Pin chat",
                  onTap: () {
                    Navigator.pop(context);
                    _togglePin(sId, !isPinned);
                  },
                ),
                _buildMenuOption(
                  icon: Icons.delete_outline_rounded,
                  label: "Delete",
                  color: Colors.redAccent.withOpacity(0.8),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteSessionConfirmation(sId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF64748B), size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color ?? const Color(0xFF0D2B28),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameDialog(String sId, String currentTitle) async {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Rename Chat", style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF0D2B28)),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD1F0EC))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A98F))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _renameSession(sId, controller.text);
            },
            child: const Text("Rename", style: TextStyle(color: Color(0xFF00A98F))),
          ),
        ],
      ),
    );
  }

  Future<void> _renameSession(String sId, String newTitle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.put(
        Uri.parse('$apiBaseUrl/chats/session/$sId/rename'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'title': newTitle}),
      );
      if (response.statusCode == 200) _fetchSessions();
    } catch (e) {
      debugPrint("Error renaming session: $e");
    }
  }

  Future<void> _togglePin(String sId, bool pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.put(
        Uri.parse('$apiBaseUrl/chats/session/$sId/pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isPinned': pin}),
      );
      if (response.statusCode == 200) _fetchSessions();
    } catch (e) {
      debugPrint("Error pinning session: $e");
    }
  }

  void _showDeleteSessionConfirmation(String sId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Delete Chat?", style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 16)),
        content: const Text("All messages in this conversation will be permanently removed.", style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSession(sId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(String sId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/chats/session/$sId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        if (_currentSessionId == sId) _startNewChat();
        _fetchSessions();
      }
    } catch (e) {
      debugPrint("Error deleting session: $e");
    }
  }

  void _showMessageContextMenu(ChatMessage message) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuOption(
                  icon: Icons.copy_rounded,
                  label: "Copy",
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
                  },
                ),
                if (message.isUser)
                  _buildMenuOption(
                    icon: Icons.edit_outlined,
                    label: "Edit Message",
                    onTap: () {
                      Navigator.pop(context);
                      _showEditMessageDialog(message);
                    },
                  ),
                _buildMenuOption(
                  icon: Icons.share_outlined,
                  label: "Share",
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(message.text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMessageDialog(ChatMessage message) {
    final controller = TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Edit Message", style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 16)),
        content: TextField(
          controller: controller,
          maxLines: null,
          style: const TextStyle(color: Color(0xFF0D2B28)),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD1F0EC))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00A98F))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleEditedMessage(message, controller.text);
            },
            child: const Text("Regenerate", style: TextStyle(color: Color(0xFF00A98F))),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditedMessage(ChatMessage oldMsg, String newText) async {
    if (newText.trim() == oldMsg.text.trim()) return;

    final index = _messages.indexOf(oldMsg);
    if (index == -1) return;

    setState(() {
      // 1. Remove all messages from this point onwards
      _messages.removeRange(index, _messages.length);
      _loading = true;
    });

    // 2. Rebuild AI context history from remaining messages
    final List<Content> aiHistory = [];
    for (var msg in _messages) {
      if (msg.isUser) {
        aiHistory.add(Content.text(msg.text));
      } else {
        aiHistory.add(Content.model([TextPart(msg.text)]));
      }
    }
    _chat = _model.startChat(history: aiHistory);

    // 3. Trigger new message with edited text
    _sendChatMessage(newText);
    
    // 4. (Backend) Ideally tell backend to delete subsequent messages for this session
    _cleanupBackendSessionAfter(oldMsg);
  }

  Future<void> _cleanupBackendSessionAfter(ChatMessage msg) async {
    // Note: Implementation depends on backend support. For now, we just let it grow.
    // A robust impl would delete messages with timestamp > msg.rawTimestamp
  }

  void _showSessionContextMenu() {
    if (_messages.isEmpty) return;

    final String sessionTitle = _messages.firstWhere((m) => m.isUser, orElse: () => _messages.first).text;
    final bool isPinned = _sessions.any((s) => s['_id']?.toString() == _currentSessionId && s['isPinned'] == true);

    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuOption(
                  icon: Icons.share_rounded,
                  label: "Share whole chat",
                  onTap: () {
                    Navigator.pop(context);
                    _shareWholeChat();
                  },
                ),
                if (_currentSessionId != null) ...[
                   _buildMenuOption(
                    icon: Icons.edit_outlined,
                    label: "Rename",
                    onTap: () {
                      Navigator.pop(context);
                      _showRenameDialog(_currentSessionId!, sessionTitle);
                    },
                  ),
                  _buildMenuOption(
                    icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    label: isPinned ? "Unpin chat" : "Pin chat",
                    onTap: () {
                      Navigator.pop(context);
                      _togglePin(_currentSessionId!, !isPinned);
                    },
                  ),
                  _buildMenuOption(
                    icon: Icons.delete_outline_rounded,
                    label: "Delete chat",
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteSessionConfirmation(_currentSessionId!);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareWholeChat() {
    if (_messages.isEmpty) return;
    
    String formattedChat = "--- CareConnect AI Chat Export ---\n\n";
    for (var msg in _messages) {
      final role = msg.isUser ? "You" : "CareConnect AI";
      formattedChat += "[$role - ${msg.timestamp}]\n${msg.text}\n\n";
    }
    
    Share.share(formattedChat);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00A98F)),
            title: Text(AppTranslations.get('camera', languageNotifier.value), style: const TextStyle(color: Color(0xFF0D2B28))),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_rounded, color: Color(0xFF00A98F)),
            title: Text(AppTranslations.get('upload_photo', languageNotifier.value), style: const TextStyle(color: Color(0xFF0D2B28))),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? id; // Backend ID
  final DateTime? rawTimestamp; // For precise ordering/filtering
  final String? imagePath;
  final XFile? imageFile;
  final String urgency;
  final String urgencyReason;
  final String urgencyAction;
  final String urgencyWarning;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.id,
    this.rawTimestamp,
    this.imagePath,
    this.imageFile,
    this.urgency = 'none',
    this.urgencyReason = '',
    this.urgencyAction = '',
    this.urgencyWarning = '',
  });
}

class MessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isPlaying;
  final VoidCallback onSpeakTap;
  final VoidCallback onCopyTap;
  final VoidCallback onShareTap;
  final Function(ChatMessage) onLongPress;

  const MessageWidget({
    super.key, 
    required this.message, 
    this.isPlaying = false,
    required this.onSpeakTap,
    required this.onCopyTap,
    required this.onShareTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Bot Message
    if (!message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bot Identity (Optional, matching screenshot "ChatGPT" look)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.favorite, color: Color(0xFF00A98F), size: 10),
                ),
                const SizedBox(width: 8),
                Text(
                  "CareConnect",
                  style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (message.urgency != 'none')
              _buildUrgencyIndicator(message),
            
            // Message Bubble Area
            GestureDetector(
              onLongPress: () => onLongPress(message),
              child: Container(
                width: double.infinity, // Take full width
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 13, height: 1.6),
                    code: GoogleFonts.firaCode(backgroundColor: const Color(0xFFE8F5F4), color: const Color(0xFF00A98F)),
                    listBullet: GoogleFonts.poppins(color: const Color(0xFF00A98F)),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Disclaimer (Small and subtle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppTranslations.get('consult_professional', languageNotifier.value),
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            
            // Actions Row (Bottom)
            Row(
              children: [
                _buildActionIcon(Icons.content_copy_rounded, onCopyTap),
                const SizedBox(width: 16),
                _buildActionIcon(Icons.thumb_up_outlined, () {}),
                const SizedBox(width: 16),
                _buildActionIcon(Icons.thumb_down_outlined, () {}),
                const SizedBox(width: 16),
                _buildActionIcon(isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded, onSpeakTap, 
                  color: isPlaying ? Colors.redAccent : null),
                const SizedBox(width: 16),
                _buildActionIcon(Icons.share_rounded, onShareTap),
                const Spacer(),
                Text(
                  message.timestamp,
                  style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    } 
    
    // User Message
    else {
       return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: kIsWeb 
                           ? Image.network(message.imageFile!.path, height: 180, width: 180, fit: BoxFit.cover)
                           : Image.file(File(message.imageFile!.path), height: 180, width: 180, fit: BoxFit.cover),
                      ),
                    ),
                GestureDetector(
                  onLongPress: () => onLongPress(message),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A98F),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, height: 1.5),
                    ),
                  ),
                ),
                  const SizedBox(height: 8),
                  Text(
                    message.timestamp,
                    style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 18, color: color ?? const Color(0xFF94A3B8)),
    );
  }

  Widget _buildUrgencyIndicator(ChatMessage message) {
    if (message.urgency == 'none') return const SizedBox.shrink();
    
    Color color;
    String label;
    IconData icon;

    switch (message.urgency) {
      case 'low':
        color = const Color(0xFF4CAF50); // Green
        label = "Low Urgency – Self-Care";
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'medium':
        color = const Color(0xFFFFC107); // Amber/Yellow
        label = "Medium Urgency – Doctor Visit";
        icon = Icons.info_outline_rounded;
        break;
      case 'high':
        color = const Color(0xFFF44336); // Red
        label = "High Urgency – Emergency";
        icon = Icons.warning_amber_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.urgencyReason.isNotEmpty) ...[
                  Text(
                    "Reason:",
                    style: GoogleFonts.poppins(
                      color: color.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.urgencyReason,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF334155),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (message.urgencyAction.isNotEmpty) ...[
                  Text(
                    "What you should do now:",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF00A98F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.urgencyAction,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF334155),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (message.urgencyWarning.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Important Flag:",
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.urgencyWarning,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF475569),
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
