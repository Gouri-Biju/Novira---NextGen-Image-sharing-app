import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:imagesecurity/complaint.dart';
import 'package:imagesecurity/feedback.dart';
import 'package:imagesecurity/viewfriendrequests.dart';
import 'package:imagesecurity/viewfriends.dart';
import 'package:imagesecurity/viewusers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HomeApp());
}

class HomeApp extends StatelessWidget {
  const HomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF0A0F1C), // Dark Navy
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A0F1C),
          secondary: Color(0xFF00E5FF), // Cyan
          surface: Color(0xFF10131F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F1C),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Dashboard'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _cardController;
  late final AnimationController _headerController;
  String? _profileImage;
  String? name;

  final List<_DashboardItem> _items = [
    _DashboardItem('Users', Icons.person_outline, UserApp()),
    _DashboardItem('Friend Requests', Icons.group_add_outlined, ReqApp()),
    _DashboardItem('Friends', Icons.people_outline, FriendsApp()),
    _DashboardItem('Complaint', Icons.report_problem_outlined, ComplaintApp()),
    _DashboardItem('Feedback', Icons.feedback_outlined, FeedbackApp()),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  Future<void> _loadProfileImage() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    setState(() {
      _profileImage = sh.getString('img');
      name = sh.getString('name');

    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Widget buildCard(_DashboardItem item, int index) {
    final animation = CurvedAnimation(
      parent: _cardController,
      curve: Interval(index * 0.15, 1.0, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, __, ___) => item.page,
                transitionsBuilder: (_, anim, __, child) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  );
                },
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.black.withOpacity(0.35),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.6),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0.3),
                      Colors.tealAccent.withOpacity(0.25),
                      Colors.lightBlueAccent.withOpacity(0.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.tealAccent.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(-3, -3),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: item.title,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Colors.cyanAccent,
                              Colors.tealAccent,
                              Colors.lightBlueAccent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Icon(item.icon,
                              size: 48, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient mix
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0F1C),
                  Color(0xFF001F29),
                  Color(0xFF0A0F1C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.cyanAccent.withOpacity(0.15),
                  Colors.tealAccent.withOpacity(0.15),
                  Colors.transparent,
                ],
                radius: 1.2,
                center: const Alignment(0.7, -0.5),
              ),
            ),
          ),

          Column(
            children: [
              // Profile photo centered
              Padding(
                padding: const EdgeInsets.only(top: 80, bottom: 20),
                child: SlideTransition(
                  position: headerSlide,
                  child: FadeTransition(
                    opacity: _headerController,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.cyanAccent, Colors.tealAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.black,
                            backgroundImage: _profileImage != null
                                ? NetworkImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(Icons.person,
                                color: Colors.white, size: 50)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Welcome Back  👋",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Encrypted • Trusted • Secure",
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _items.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                    ),
                    itemBuilder: (context, index) =>
                        buildCard(_items[index], index),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Widget page;
  _DashboardItem(this.title, this.icon, this.page);
}
