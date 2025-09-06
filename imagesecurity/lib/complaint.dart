import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:imagesecurity/userhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ComplaintApp());
}

class ComplaintApp extends StatelessWidget {
  const ComplaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complaints',
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
      home: const ComplaintPage(title: 'Your Complaints'),
    );
  }
}

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key, required this.title});
  final String title;

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _complaint = TextEditingController();
  List<dynamic> data = [];

  @override
  void initState() {
    super.initState();
    _loadcomplaints();
  }

  Future<void> _loadcomplaints() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? uid = sh.getString('uid');
    var response = await http.post(
      Uri.parse('$url/api/viewcomplaint'),
      body: {'uid': uid},
    );
    var result = json.decode(response.body);
    setState(() {
      data = result['data'];
    });
  }

  Widget _buildComplaintCard(dynamic content) {
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
            color: Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Complaint:",
            style: TextStyle(
              color: Colors.cyanAccent.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            content["c"],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "Reply:",
            style: TextStyle(
              color: Colors.tealAccent.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            content["r"].isNotEmpty ? content["r"] : "No reply yet",
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Date: ${content["d"]}",
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: content["s"] == "Pending"
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  content["s"],
                  style: TextStyle(
                    color: content["s"] == "Pending"
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitComplaint() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? uid = sh.getString('uid');
    String complaint = _complaint.text.trim();

    if (complaint.isEmpty) return;

    await http.post(
      Uri.parse('$url/api/sendcomplaint'),
      body: {'uid': uid, 'complaint': complaint},
    );
    _complaint.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ComplaintApp()),
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
          Column(
            children: [
              // Complaint Input Box
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _complaint,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Enter your complaint...",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitComplaint,
                        icon: const Icon(Icons.send,
                            color: Colors.cyanAccent, size: 28),
                      ),
                    ],
                  ),
                ),
              ),

              // Complaints List
              Expanded(
                child: data.isEmpty
                    ? const Center(
                  child: Text(
                    "No complaints found",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return _buildComplaintCard(data[index]);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
