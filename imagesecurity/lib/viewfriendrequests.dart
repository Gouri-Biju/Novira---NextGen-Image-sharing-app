import 'package:flutter/material.dart';
import 'package:imagesecurity/userhome.dart';
import 'package:imagesecurity/viewusers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ReqApp());
}

class ReqApp extends StatelessWidget {
  const ReqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friend Requests',
      debugShowCheckedModeBanner: false,
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
      home: const ReqPage(title: 'Friend Requests'),
    );
  }
}

class ReqPage extends StatefulWidget {
  const ReqPage({super.key, required this.title});
  final String title;

  @override
  State<ReqPage> createState() => _ReqPageState();
}

class _ReqPageState extends State<ReqPage> {
  String? url;
  String? imageurl;
  List<dynamic> data = [];

  @override
  void initState() {
    super.initState();
    _loadusers();
  }

  Future<void> _loadusers() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    url = sh.getString('url');
    String? uid = sh.getString('uid');
    var response = await http.post(
      Uri.parse('$url/api/viewreq'),
      body: {'uid': uid},
    );
    var result = json.decode(response.body);
    setState(() {
      data = result['data'];
    });
  }

  Widget _buildUserCard(dynamic content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.black.withOpacity(0.3),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.network(
              imageurl = "$url/static/media/${content['image']}",
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content["n"],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  content["e"],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  content["p"],
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),

          // Accept & Reject Buttons
          Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences sh =
                  await SharedPreferences.getInstance();
                  String? url = sh.getString('url');
                  String? uid = sh.getString('uid');
                  await http.post(
                    Uri.parse('$url/api/reqaccept'),
                    body: {
                      'fid': content['id'].toString(),
                      'uid': uid,
                    },
                  );
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const ReqApp()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[400],
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text("Accept"),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () async {
                  SharedPreferences sh =
                  await SharedPreferences.getInstance();
                  String? url = sh.getString('url');
                  String? uid = sh.getString('uid');
                  await http.post(
                    Uri.parse('$url/api/reqreject'),
                    body: {
                      'fid': content['id'].toString(),
                      'uid': uid,
                    },
                  );
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const ReqApp()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text("Reject"),
              ),
            ],
          ),
        ],
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
                context, MaterialPageRoute(builder: (context) => const HomeApp()));
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
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0F1C), Color(0xFF001F29)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          data.isEmpty
              ? const Center(
            child: Text(
              "No requests found",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return _buildUserCard(data[index]);
            },
          ),
        ],
      ),
    );
  }
}
