import 'package:flutter/material.dart';
import 'package:imagesecurity/userhome.dart';
import 'package:imagesecurity/profileedit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile',
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
      home: const ProfilePage(title: 'My Profile'),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.title});
  final String title;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? url;
  List<dynamic> data = [];

  @override
  void initState() {
    super.initState();
    _loadprofile();
  }

  Future<void> _loadprofile() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    url = sh.getString('url');
    String? uid = sh.getString('uid');

    var response = await http.post(
      Uri.parse('$url/api/userprofile'),
      body: {'uid': uid},
    );
    final result = json.decode(response.body);
    setState(() {
      data = result['data'];
    });
  }

  void _navigateToEdit(String firstn,String lname, String email, String phone, String photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(firstn: firstn,lastname: lname,email:email,phone:phone,photo:photo, title: ''),
      ),
    );
  }

  Widget _buildProfile(dynamic content) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Avatar
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.tealAccent.withOpacity(0.3),
            backgroundImage: NetworkImage(
              '$url/static/media/${content['photo']}',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${content['fn']} ${content['ln']}',
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            content['e'],
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Info Cards
          _infoTile(Icons.phone, "Phone", content['ph']),
          _infoTile(Icons.email, "Email", content['e']),

          const SizedBox(height: 30),

          // Edit Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            onPressed: () {
              _navigateToEdit(content['fn'],content['ln'],content['e'],content['ph'],content['photo']);
            },
            icon: const Icon(Icons.edit, size: 20),
            label: const Text(
              "Edit Profile",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      color: const Color(0xFF10131F),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.tealAccent),
        title: Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(color: Colors.white),
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
              MaterialPageRoute(builder: (context) => const HomeApp()),
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
        child: Center(
          child: data.isEmpty
              ? const Text(
            'Cannot fetch data',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          )
              : _buildProfile(data[0]),
        ),
      ),
    );
  }
}
