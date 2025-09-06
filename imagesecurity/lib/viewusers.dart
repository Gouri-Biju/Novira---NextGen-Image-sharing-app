import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:imagesecurity/userhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const UserApp());
}

class UserApp extends StatelessWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Users',
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
      home: const UserPage(title: 'Discover Users'),
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key, required this.title});
  final String title;

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String url = "";
  List<dynamic> data = [];
  String? imageurl;

  @override
  void initState() {
    super.initState();
    _loadusers();
  }

  Future<void> _loadusers() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    url = sh.getString('url')!;
    String? uid = sh.getString('uid');

    var response = await http.post(
      Uri.parse('$url/api/viewuser'),
      body: {'uid': uid},
    );
    final result = json.decode(response.body);
    setState(() {
      data = result['data'];
    });
  }

  Widget _buildUserCard(dynamic content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withOpacity(0.15),
            Colors.tealAccent.withOpacity(0.10),
            Colors.transparent
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person, color: Colors.white70, size: 40),
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
                    color: Colors.cyanAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content["e"],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content["p"],
                  style: TextStyle(
                    color: Colors.tealAccent.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Action Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
              foregroundColor: Colors.cyanAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              SharedPreferences sh = await SharedPreferences.getInstance();
              String? url = sh.getString('url');
              String? uid = sh.getString('uid').toString();
              if (content['button'] == 'Send request') {
                await http.post(
                  Uri.parse('$url/api/sendreq'),
                  body: {
                    'fid': content['id'].toString(),
                    'uid': uid.toString(),
                  },
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserApp()),
                );
              }
            },
            child: Text(content['button']),
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeApp()),
            );
          },
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient Background
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
              'No users found',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 20, top: 10),
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
