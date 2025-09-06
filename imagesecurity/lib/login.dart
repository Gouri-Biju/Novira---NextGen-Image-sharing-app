import 'package:flutter/material.dart';
import 'package:imagesecurity/reg.dart';
import 'package:imagesecurity/userhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const LogApp());
}

class LogApp extends StatelessWidget {
  const LogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F1C),
        useMaterial3: true,
      ),
      home: const LogPage(title: 'Login'),
    );
  }
}

class LogPage extends StatefulWidget {
  const LogPage({super.key, required this.title});
  final String title;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final _logformkey = GlobalKey<FormState>();
  final TextEditingController _uname = TextEditingController();
  final TextEditingController _pwd = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _logformkey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 70, color: Colors.cyanAccent),
                const SizedBox(height: 20),
                const Text(
                  "Secure Login",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _uname,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon:
                    const Icon(Icons.person, color: Colors.cyanAccent),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: 'Username',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _pwd,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon:
                    const Icon(Icons.lock, color: Colors.orangeAccent),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: 'Password',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      SharedPreferences sh =
                      await SharedPreferences.getInstance();
                      String? url = sh.getString('url');
                      var response = await http.post(
                        Uri.parse('$url/api/userlogin/'),
                        body: {
                          'uname': _uname.text,
                          'pwd': _pwd.text,
                        },
                      );
                      final result = json.decode(response.body);
                      String? status = result['status'];
                      String? uid = result['uid'].toString();
                      String? img = result['img'].toString();
                      String? name = result['name'].toString();
                      if (status == 'success') {
                        sh.setString('uid', uid.toString());
                        sh.setString('img', '$url/static/media/$img');
                        sh.setString('name', name);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomeApp()),
                        );
                      }
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>RegisterApp()));
                    // Add register navigation if needed
                  },
                  child: const Text(
                    "Don’t have an account? Register",
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
