import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imagesecurity/login.dart';
import 'package:imagesecurity/profilepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const EditApp());
}

class EditApp extends StatelessWidget {
  const EditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0F1C),
        useMaterial3: true,
      ),
      home: const EditPage(
        title: '',
        firstn: '',
        lastname: '',
        email: '',
        phone: '',
        photo: '',
      ),
    );
  }
}

class EditPage extends StatefulWidget {
  const EditPage({
    super.key,
    required this.title,
    required this.firstn,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.photo,
  });

  final String title;
  final String firstn;
  final String lastname;
  final String email;
  final String phone;
  final String photo; // old image filename from backend

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _regformkey = GlobalKey<FormState>();

  late TextEditingController _fname;
  late TextEditingController _lname;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _username;
  late TextEditingController _pwd;

  File? _profileImage; // new picked image
  String? baseUrl; // backend base URL

  @override
  void initState() {
    super.initState();
    _fname = TextEditingController(text: widget.firstn);
    _lname = TextEditingController(text: widget.lastname);
    _email = TextEditingController(text: widget.email);
    _phone = TextEditingController(text: widget.phone);
    _username = TextEditingController();
    _pwd = TextEditingController();

    _loadUrl(); // load base url from shared preferences
  }

  Future<void> _loadUrl() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    setState(() {
      baseUrl = sh.getString('url');
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  Future<void> _register() async {
    if (_regformkey.currentState!.validate()) {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? uid = sh.getString('uid');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/api/editcreg/'),
      );
      request.fields['uid']=uid!;
      request.fields['uname'] = _username.text;
      request.fields['pwd'] = _pwd.text;
      request.fields['fname'] = _fname.text;
      request.fields['lname'] = _lname.text;
      request.fields['email'] = _email.text;
      request.fields['phone'] = _phone.text;

      if (_profileImage != null) {
        // new image selected
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _profileImage!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        // send old photo filename so backend keeps it
        request.fields['old_photo'] = widget.photo;
      }

      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      print("Register Response: $respStr");

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileApp()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Form(
            key: _regformkey,
            child: Column(
              children: [
                const Icon(Icons.person_add,
                    size: 70, color: Colors.cyanAccent),
                const SizedBox(height: 16),
                const Text(
                  "Edit Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(height: 25),

                // First Row: First & Last Name
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _fname,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration("First Name", Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "First name required";
                          }
                          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                            return "Only letters allowed";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lname,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Last Name", Icons.person),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Last name required";
                          }
                          if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                            return "Only letters allowed";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _email,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Email", Icons.email),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email required";
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                        .hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Phone", Icons.phone),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Phone number required";
                    }
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return "Enter a valid 10-digit number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username

                // Profile Image Picker
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (baseUrl != null && widget.photo.isNotEmpty
                            ? NetworkImage(
                            "$baseUrl/static/media/${widget.photo}")
                            : null),
                        child: (_profileImage == null && widget.photo.isEmpty)
                            ? const Icon(Icons.camera_alt,
                            size: 30, color: Colors.orangeAccent)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Tap to select a profile picture",
                        style:
                        TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),

                // Register Button
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
                    onPressed: _register,
                    child: const Text(
                      "Update",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Back to login
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfileApp()),
                    );
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.cyanAccent),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
