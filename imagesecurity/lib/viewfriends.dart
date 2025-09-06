import 'package:flutter/material.dart';
import 'package:imagesecurity/imagechat.dart';
import 'package:imagesecurity/userhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const FriendsApp());
}

class FriendsApp extends StatelessWidget {
  const FriendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friends',
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
      home: const FriendPage(title: 'My Friends'),
    );
  }
}

class FriendPage extends StatefulWidget {
  const FriendPage({super.key, required this.title});
  final String title;

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  String? url;
  List<dynamic> data = [];
  List<dynamic> filteredData = [];
  final TextEditingController _searchController = TextEditingController();

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
      Uri.parse('$url/api/viewfriends'),
      body: {'uid': uid},
    );
    var result = json.decode(response.body);
    setState(() {
      data = result['data'];
      filteredData = data;
    });
  }

  void _filterFriends(String query) {
    setState(() {
      filteredData = data
          .where((friend) =>
          friend['n'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Widget _buildGridCard(dynamic content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.tealAccent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(2, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min, // avoids overflow
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.tealAccent.withOpacity(0.3),
            backgroundImage: NetworkImage(
              '$url/static/media/${content['image']}',
            ),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(height: 6),

          // Friend Name
          Flexible(
            child: Text(
              content["n"],
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 6),

          // Chat Button
          SizedBox(
            width: 75,
            height: 28,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.zero,
                elevation: 3,
              ),
              onPressed: () async {
                SharedPreferences sh = await SharedPreferences.getInstance();
                sh.setString('rid', content['id'].toString());
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatApp()),
                );
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Chat',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
                context, MaterialPageRoute(builder: (_) => const HomeApp()));
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
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.tealAccent),
                  hintText: "Search friends...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterFriends,
              ),
            ),

            // Friends Grid
            Expanded(
              child: filteredData.isEmpty
                  ? const Center(
                child: Text(
                  "No friends found",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 cards per row
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75, // controls card height
                ),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  return _buildGridCard(filteredData[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
