import 'package:flutter/material.dart';
import 'package:imagesecurity/userhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const FeedbackApp());
}

class FeedbackApp extends StatelessWidget {
  const FeedbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feedback',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A0F1C),
          secondary: Color(0xFF26A69A),
          surface: Color(0xFF10131F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F1C),
        useMaterial3: true,
      ),
      home: const FeedbackPage(title: 'Feedbacks'),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, required this.title});
  final String title;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  TextEditingController _complaint = TextEditingController();
  List<dynamic> data = [];
  String? url;

  @override
  void initState() {
    super.initState();
    _loadcomplaints();
  }

  Future<void> _loadcomplaints() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    url = sh.getString('url');
    String? uid = sh.getString('uid');
    var response = await http.post(
      Uri.parse('$url/api/viewfeedback'),
      body: {'uid': uid},
    );
    var result = json.decode(response.body);
    setState(() {
      data = result['data'];
    });
  }

  Widget _buildFeedbackCard(dynamic content) {
    return Card(
      color: const Color(0xFF10131F),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.tealAccent.withOpacity(0.2),
          backgroundImage: NetworkImage(
            '$url/static/media/${content['image']}',
          ),
        ),
        title: Text(
          content["n"],
          style: const TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              'Feedback: ${content["c"]}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Date: ${content["d"]}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeApp()),
            );
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.tealAccent),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0F1C), Color(0xFF001F29)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Feedback Input
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _complaint,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Write your feedback...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                    ),
                    onPressed: () async {
                      SharedPreferences sh =
                      await SharedPreferences.getInstance();
                      String? url = sh.getString('url');
                      String? uid = sh.getString('uid');
                      String? complaint = _complaint.text.trim();
                      if (complaint.isNotEmpty) {
                        await http.post(
                          Uri.parse('$url/api/sendfeedback'),
                          body: {'uid': uid, 'feedback': complaint},
                        );
                        _complaint.clear();
                        _loadcomplaints();
                      }
                    },
                    child: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),

            // Feedback List
            Expanded(
              child: data.isEmpty
                  ? const Center(
                child: Text(
                  "No feedbacks found",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return _buildFeedbackCard(data[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
