import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'check.dart';

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Secure Chat',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A0F1C),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF10131F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F1C),
        useMaterial3: true,
      ),
      home: const ChatPage(title: 'Secure Image Chat'),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title});
  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  String? _baseUrl;
  String? _uid;

  Future<void> _loadBaseUrl() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    setState(() {
      _baseUrl = sh.getString('url');
      _uid = sh.getString('uid');
    });
  }

  Future<void> _pickAndSend() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null || _baseUrl == null) return;

    setState(() => _isSending = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? uid = sh.getString('uid');
    String? rid = sh.getString('rid');

    var request =
    http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/sendimage'));
    request.fields['sid'] = uid!;
    request.fields['rid'] = rid!;
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      picked.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    var response = await request.send();
    var respStr = await response.stream.bytesToString();
    var jsonResp = jsonDecode(respStr);

    if (response.statusCode == 200 && jsonResp['status'] == 'success') {
      _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send image")));
    }

    setState(() => _isSending = false);
  }

  Future<void> _loadMessages() async {
    if (_baseUrl == null) return;

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? uid = sh.getString('uid');
    String? rid = sh.getString('rid');

    final response =
    await http.get(Uri.parse('$_baseUrl/api/getmessages/$uid/$rid'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data['messages']);
        });
      }
    }
  }

  Future<void> _decryptMessage(String sid, String rid, String mid) async {
    if (_baseUrl == null) return;

    final response =
    await http.get(Uri.parse('$_baseUrl/api/decrypt/$sid/$rid/$mid'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        _showFullscreenImage('$_baseUrl/static${data['stitched_image']}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? "Decryption failed")));
      }
    }
  }

  void _showFullscreenImage(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: InteractiveViewer(
            child: Center(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBaseUrl().then((_) => _loadMessages());
  }

  @override
  Widget build(BuildContext context) {
    // Group by message_id
    Map<String, List<Map<String, dynamic>>> groupedMessages = {};
    for (var msg in _messages) {
      String mid = msg['message_id'].toString();
      if (!groupedMessages.containsKey(mid)) groupedMessages[mid] = [];
      groupedMessages[mid]!.add(msg);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeApp()),
            );
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: groupedMessages.entries.map((entry) {
                  var parts = entry.value;
                  bool isMine = parts.first['sender_id'].toString() == _uid;
                  bool isEncrypted =
                  parts.any((p) => p['part_index'] != -1); // encrypted group?
                  int rows = (parts.length / 2).ceil();
                  double gridHeight = rows * 140.0;

                  return Align(
                    alignment:
                    isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.tealAccent.withOpacity(0.3)
                            : Colors.grey[850],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isMine
                              ? const Radius.circular(12)
                              : const Radius.circular(0),
                          bottomRight: isMine
                              ? const Radius.circular(0)
                              : const Radius.circular(12),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (isEncrypted) {
                            _decryptMessage(
                                parts.first['sender_id'].toString(),
                                parts.first['receiver_id'].toString(),
                                parts.first['message_id'].toString());
                          } else {
                            _showFullscreenImage(
                                parts.first['image_url'].toString().startsWith('http')
                                    ? parts.first['image_url']
                                    : '$_baseUrl/static${parts.first['image_url']}');
                          }
                        },
                        child: isEncrypted
                            ? SizedBox(
                          height: gridHeight,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 1,
                            ),
                            itemCount: parts.length,
                            itemBuilder: (context, index) {
                              final img = parts[index];
                              final imageUrl = img['image_url'];
                              if (imageUrl == null) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[850],
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.lock,
                                      color: Colors.orangeAccent,
                                      size: 40),
                                );
                              }
                              return ClipRRect(
                                borderRadius:
                                BorderRadius.circular(6),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (ctx, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey,
                                        child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.red),
                                      ),
                                ),
                              );
                            },
                          ),
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            parts.first['image_url']
                                .toString()
                                .startsWith('http')
                                ? parts.first['image_url']
                                : '$_baseUrl/static${parts.first['image_url']}',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (ctx, error, stackTrace) => Container(
                              color: Colors.grey,
                              width: 200,
                              height: 200,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (_isSending)
            const LinearProgressIndicator(color: Colors.tealAccent),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.cyanAccent),
                  onPressed: _pickAndSend,
                ),
                const Expanded(
                  child: Text(
                    "Send an image",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
