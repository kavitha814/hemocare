import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'globals.dart';
import 'translations.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<dynamic> _chats = [];
  bool _isLoading = true;
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/chats'),
        headers: {
          ...apiHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _chats = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A98F),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0D2B28),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return "TODAY";
    if (d == yesterday) return "YESTERDAY";
    return "${_getMonth(d.month)} ${d.day}, ${d.year}";
  }

  String _getMonth(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Filter chats if a date is selected
    List<dynamic> filteredChats = _chats;
    if (_selectedDate != null) {
      filteredChats = _chats.where((chat) {
        if (chat['timestamp'] == null) return false;
        final dt = DateTime.parse(chat['timestamp']).toLocal();
        return dt.year == _selectedDate!.year && dt.month == _selectedDate!.month && dt.day == _selectedDate!.day;
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Bar
            ValueListenableBuilder<String>(
              valueListenable: languageNotifier,
              builder: (context, lang, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSelectionMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, 
                          color: const Color(0xFF0D2B28), 
                          size: 20
                        ),
                        onPressed: () {
                          if (_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = false;
                              _selectedIds.clear();
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isSelectionMode 
                          ? "${_selectedIds.length} SELECTED"
                          : AppTranslations.get('chat_history', lang).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D2B28),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      if (_isSelectionMode)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                          onPressed: _showDeleteConfirmation,
                        )
                      else ...[
                        IconButton(
                          icon: Icon(
                            _selectedDate == null ? Icons.calendar_today_rounded : Icons.calendar_month_rounded, 
                            color: _selectedDate == null ? const Color(0xFF64748B) : const Color(0xFF00A98F),
                            size: 20,
                          ),
                          onPressed: () => _selectDate(context),
                        ),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => setState(() => _selectedDate = null),
                          ),
                      ],
                    ],
                  ),
                );
              }
            ),

            // Main Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFFE),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A98F)))
                    : filteredChats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_rounded, size: 64, color: const Color(0xFFD1F0EC)),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedDate == null ? "No chat history available" : "No history on this date", 
                                  style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14)
                                ),
                                if (_selectedDate != null)
                                  TextButton(
                                    onPressed: () => setState(() => _selectedDate = null),
                                    child: Text("Clear Filter", style: GoogleFonts.poppins(color: const Color(0xFF00A98F))),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filteredChats.length,
                            itemBuilder: (context, index) {
                              final chat = filteredChats[index];
                              final bool isUser = chat['isUser'] ?? false;
                              
                              final DateTime chatDate = chat['timestamp'] != null 
                                  ? DateTime.parse(chat['timestamp']).toLocal() 
                                  : DateTime.now();
                                  
                              final String time = chat['timestamp'] != null
                                  ? chatDate.toString().substring(11, 16)
                                  : "";

                              // Show date header if it's the first message of a day
                              bool showDateHeader = false;
                              if (_selectedDate == null) {
                                if (index == 0) {
                                  showDateHeader = true;
                                } else {
                                  final prevChat = filteredChats[index - 1];
                                  if (prevChat['timestamp'] != null) {
                                    final prevDate = DateTime.parse(prevChat['timestamp']).toLocal();
                                    if (prevDate.day != chatDate.day || prevDate.month != chatDate.month || prevDate.year != chatDate.year) {
                                      showDateHeader = true;
                                    }
                                  }
                                }
                              }

                              return Column(
                                children: [
                                  if (showDateHeader)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Row(
                                        children: [
                                          const Expanded(child: Divider(color: Color(0xFFD1F0EC))),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(
                                              _formatDate(chatDate),
                                              style: GoogleFonts.poppins(color: const Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                            ),
                                          ),
                                          const Expanded(child: Divider(color: Color(0xFFD1F0EC))),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        if (!_isSelectionMode) {
                                          final String? id = chat['_id']?.toString();
                                          if (id != null) {
                                            setState(() {
                                              _isSelectionMode = true;
                                              _toggleSelection(id);
                                            });
                                          }
                                        }
                                      },
                                      onTap: () {
                                        if (_isSelectionMode) {
                                          final String? id = chat['_id']?.toString();
                                          if (id != null) {
                                            _toggleSelection(id);
                                          }
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!isUser) _chatAvatar(false),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: _selectedIds.contains(chat['_id']?.toString())
                                                      ? const Color(0xFF00A98F).withOpacity(0.2)
                                                      : (isUser ? const Color(0xFFEEFBFA) : const Color(0xFFF0FFFE)),
                                                    borderRadius: BorderRadius.only(
                                                      topLeft: const Radius.circular(20),
                                                      topRight: const Radius.circular(20),
                                                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                                                      bottomRight: Radius.circular(isUser ? 4 : 20),
                                                    ),
                                                    border: Border.all(
                                                      color: _selectedIds.contains(chat['_id']?.toString()) 
                                                        ? const Color(0xFF00A98F).withOpacity(0.5)
                                                        : const Color(0xFF00A98F).withOpacity(0.1)
                                                    ),
                                                  ),
                                                  child: isUser 
                                                    ? Text(
                                                        chat['text'], 
                                                        style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 14)
                                                      )
                                                    : MarkdownBody(
                                                        data: chat['text'], 
                                                        styleSheet: MarkdownStyleSheet(
                                                          p: GoogleFonts.poppins(color: const Color(0xFF334155), fontSize: 14, height: 1.5),
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  time, 
                                                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B))
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (isUser) _chatAvatar(true),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          "Delete Chats",
          style: GoogleFonts.poppins(color: const Color(0xFF0D2B28), fontSize: 18),
        ),
        content: Text(
          "Are you sure you want to delete ${_selectedIds.length} messages? This action cannot be undone.",
          style: GoogleFonts.poppins(color: const Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedChats();
            },
            child: Text("Delete", style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedChats() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      int deletedCount = 0;
      for (String id in _selectedIds) {
        // If it's a numeric index (fallback), we can't delete from backend easily without ID
        // Assuming backend works with String IDs
        if (id.length < 5) continue; 

        final response = await http.delete(
          Uri.parse('$apiBaseUrl/chats/$id'),
          headers: {
            ...apiHeaders,
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          deletedCount++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $deletedCount messages')),
        );
      }
      
      // Reset state and re-fetch
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _fetchHistory();
    } catch (e) {
      debugPrint("Error deleting chats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _headerLogo() {
    return Container(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00A98F).withOpacity(0.1)),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00A98F).withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A98F).withOpacity(0.4),
                  blurRadius: 10,
                )
              ],
            ),
            child: const Icon(Icons.favorite, size: 16, color: Color(0xFF00A98F)),
          ),
        ],
      ),
    );
  }

  Widget _chatAvatar(bool isUser) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFEEFBFA) : const Color(0xFF00A98F).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 16,
        color: isUser ? const Color(0xFF64748B) : const Color(0xFF00A98F),
      ),
    );
  }
}
