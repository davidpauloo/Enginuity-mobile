// lib/screens/home_screen.dart
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/screens/projects_screen.dart';
import 'package:chat_app/screens/video_conference_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  // NEW: Add initialIndex to constructor
  final int initialIndex;
  const HomeScreen(
      {super.key, this.initialIndex = 0}); // Default to 0 (Projects)

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Will be set by initialIndex on first build
  final AuthService _authService = AuthService();

  static const List<Widget> _widgetOptions = <Widget>[
    ProjectsScreen(),
    ChatScreen(),
    VideoConferenceScreen(),
    ProfileScreen(),
  ];

  final List<String> _appBarTitles = [
    'Enginuity',
    'Chats',
    'Video Conference',
    'Profile'
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        widget.initialIndex; // Set initial index from widget property
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                  Fluttertoast.showToast(msg: "Logged out successfully!");
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _appBarTitles[_selectedIndex],
          style: const TextStyle(
              color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF412ad5),
        actions: const [], // No actions in AppBar as per your last request
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30.0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wechat, size: 30.0),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_camera_front, size: 30.0),
            label: 'Video Conference',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, size: 30.0),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF412ad5),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
