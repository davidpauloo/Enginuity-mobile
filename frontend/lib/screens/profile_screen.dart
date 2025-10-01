// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:chat_app/services/auth_service.dart'; // This import now brings CurrentUser
import 'package:chat_app/screens/login_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:chat_app/screens/help_and_support_screen.dart';
import 'package:chat_app/services/project_service.dart';
import 'package:chat_app/models/project.dart';
import 'package:chat_app/screens/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ProjectService _projectService = ProjectService();

  CurrentUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  int _ongoingUpcomingProjectsCount = 0;
  int _finishedProjectsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndProjects();
  }

  Future<void> _loadUserProfileAndProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user =
          await _authService.getCurrentUser(); // This only reads from storage
      if (user == null) {
        throw Exception('User not logged in or profile data missing.');
      }
      setState(() {
        _currentUser = user;
      });

      if (_currentUser != null && _currentUser!.fullName.isNotEmpty) {
        // This will attempt to fetch projects, but if ProjectService uses a token
        // and getToken() in AuthService relies on storage, it might fail if the token
        // isn't ready or if ProjectService expects a fresh backend call.
        final fetchedProjects = await _projectService.fetchProjects(
            clientName: _currentUser!.fullName,
            token: await _authService.getToken());

        final now = DateTime.now().toLocal();

        int ongoingCount = 0;
        int finishedCount = 0;

        for (var project in fetchedProjects) {
          if (project.targetDeadline != null &&
              project.targetDeadline!.isBefore(now)) {
            finishedCount++;
          } else {
            ongoingCount++;
          }
        }

        setState(() {
          _ongoingUpcomingProjectsCount = ongoingCount;
          _finishedProjectsCount = finishedCount;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile or projects: ${e.toString()}';
        print('Error loading profile/projects: $e');
      });
      Fluttertoast.showToast(
        msg: _errorMessage!,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      // If unauthorized (e.g., token invalid or expired), redirect to login
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Forbidden') ||
          e.toString().contains('token not found')) {
        // Added check for token not found
        _authService.logout(); // Use old logout for now
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      Fluttertoast.showToast(msg: "Logged out successfully!");
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
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
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _currentUser == null
                  ? const Center(
                      child: Text(
                        'No user data found. Please log in.',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade50,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Picture Display (likely a placeholder or simple icon)
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage:
                                  _currentUser!.profilePic != null &&
                                          _currentUser!.profilePic!.isNotEmpty
                                      ? NetworkImage(_currentUser!.profilePic!)
                                      : null,
                              child: _currentUser!.profilePic == null ||
                                      _currentUser!.profilePic!.isEmpty
                                  ? Icon(Icons.person,
                                      size: 60, color: Colors.blue.shade700)
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            // Full Name displayed below avatar
                            Text(
                              _currentUser!.fullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // User Details Rows (Email, Mobile Number, and Role)
                            _buildProfileInfoRow(
                              'Email',
                              _currentUser!.email,
                              Icons.email,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            _buildProfileInfoRow(
                              'Mobile Number',
                              _currentUser!.mobileNumber != null &&
                                      _currentUser!.mobileNumber!.isNotEmpty
                                  ? _currentUser!.mobileNumber!
                                  : 'Unknown',
                              Icons.call,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            _buildProfileInfoRow(
                              'Role',
                              _currentUser!.isAdmin ? 'Admin' : 'Client',
                              Icons.badge,
                              borderRadius: BorderRadius.circular(10.0),
                            ),

                            const SizedBox(height: 30),

                            // Projects Overview Section (as it was)
                            _buildProjectsOverview(
                              ongoingUpcoming: _ongoingUpcomingProjectsCount,
                              finished: _finishedProjectsCount,
                            ),

                            const SizedBox(height: 30),

                            // Action Buttons
                            ElevatedButton.icon(
                              onPressed: () {
                                // This button just showed a toast originally
                                Fluttertoast.showToast(
                                    msg: "Edit Profile feature coming soon!");
                              },
                              icon: const Icon(Icons.edit, size: 20),
                              label: const Text('Edit Profile',
                                  style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 80, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0)),
                                backgroundColor: const Color(0xFF412ad5),
                                foregroundColor: Colors.white,
                                elevation: 4,
                              ),
                            ),
                            const SizedBox(height: 10),

                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HelpAndSupportScreen()),
                                );
                              },
                              icon: const Icon(Icons.help_outline, size: 20),
                              label: const Text('Help & Support',
                                  style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                backgroundColor: Colors.blue.shade100,
                                foregroundColor: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),

                            ElevatedButton.icon(
                              onPressed: _showLogoutConfirmationDialog,
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text('Logout',
                                  style: TextStyle(fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value, IconData icon,
      {BorderRadius? borderRadius}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0),
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsOverview(
      {required int ongoingUpcoming, required int finished}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Projects',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ongoing & Upcoming',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                '$ongoingUpcoming',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Finished Projects',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              Text(
                '$finished',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialIndex: 0)),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              backgroundColor: const Color(0xFF412ad5),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text(
              'View Projects',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
