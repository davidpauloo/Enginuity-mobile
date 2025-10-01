// lib/screens/projects_screen.dart
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/models/project.dart'; // Import your Project model
import 'package:chat_app/services/project_service.dart'; // Import your ProjectService
import 'package:get/get_core/src/get_main.dart';
import 'package:get/route_manager.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fluttertoast/fluttertoast.dart'; // Import fluttertoast
import 'package:chat_app/screens/project_detail_screen.dart'; // Import the detail screen
import 'package:chat_app/services/auth_service.dart'; // NEW: Import AuthService to get current user name
import 'package:cached_network_image/cached_network_image.dart'; // Still needed for CachedNetworkImageProvider if you use it elsewhere, or for future use

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  final ProjectService _projectService = ProjectService();
  final AuthService _authService = AuthService();

  List<Project> _allProjects = [];
  List<Project> _ongoingProjects = [];
  List<Project> _finishedProjects = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentClientFullName;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUserDataAndFetchProjects();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadUserDataAndFetchProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.getCurrentUser();
      if (user == null || user.fullName.isEmpty) {
        throw Exception('User not logged in or full name not found.');
      }
      _currentClientFullName = user.fullName;
      await _fetchProjects();
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization failed: ${e.toString()}';
      });
      Fluttertoast.showToast(
        msg: _errorMessage!,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProjects() async {
    if (_currentClientFullName == null) {
      setState(() {
        _errorMessage = 'User not identified. Cannot load projects.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allProjects = [];
      _ongoingProjects = [];
      _finishedProjects = [];
    });
    try {
      final fetchedProjects = await _projectService.fetchProjects(
          clientName: _currentClientFullName);
      final now = DateTime.now().toLocal();

      List<Project> tempOngoing = [];
      List<Project> tempFinished = [];

      for (var project in fetchedProjects) {
        if (project.targetDeadline != null &&
            project.targetDeadline!.isBefore(now)) {
          tempFinished.add(project);
        } else {
          tempOngoing.add(project);
        }
      }

      tempOngoing.sort((a, b) => (a.targetDeadline ?? DateTime(3000))
          .compareTo(b.targetDeadline ?? DateTime(3000)));
      tempFinished.sort((a, b) => (b.targetDeadline ?? DateTime(3000))
          .compareTo(a.targetDeadline ?? DateTime(3000)));

      setState(() {
        _allProjects = fetchedProjects;
        _ongoingProjects = tempOngoing;
        _finishedProjects = tempFinished;
      });
      Fluttertoast.showToast(
        msg: 'Projects refreshed successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load projects: ${e.toString()}';
        print('Error fetching projects: $e'); // Keep this print for debugging
      });
      Fluttertoast.showToast(
        msg: _errorMessage!,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Forbidden')) {
        _authService.logout();
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('M/d/yyyy').format(date);
  }

  Widget _buildProjectCard(Project project, {bool isFinished = false}) {
    final String? imageUrl = project.imageUrl;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(
              project: project,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          height: 180,
          color: const Color(0xFF262626),
          child: Stack(
            children: [
              // Conditional for Background Image or "No Image" text
              Positioned.fill(
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? FadeInImage.assetNetwork(
                        // Make sure 'assets/loading_placeholder.png' exists and is declared
                        placeholder: 'assets/loading_placeholder.png',
                        imageErrorBuilder: (context, error, stackTrace) {
                          print(
                              'Error loading image for ${project.clientName}: $error');
                          // If there's an error loading the network image, fallback to "No Image"
                          return _buildNoImageContent();
                        },
                        image: imageUrl,
                        fit: BoxFit.cover,
                      )
                    : _buildNoImageContent(), // Display "No Image" content when imageUrl is empty
              ),

              // Gradient Overlay for text readability (applied over image or "No Image" content)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Text Content (Client Name, Location, Dates)
              Positioned(
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.description ?? 'No Description',
                      style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      project.location ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start: ${_formatDate(project.startDate)}',
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          'Deadline: ${_formatDate(project.targetDeadline)}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isFinished
                                ? Colors.white54
                                : Colors.redAccent.shade100,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Widget for "No Image" display
  Widget _buildNoImageContent() {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFF262626), // Match background color from reference
      child: const Text(
        'No Image',
        style: TextStyle(
          fontSize: 36.0, // Large font size
          fontWeight: FontWeight.bold,
          color: Colors.grey, // Grey color for "No Image"
        ),
      ),
    );
  }

  Widget _buildNoProjectsContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Get.offAll(() => const HomeScreen(initialIndex: 1));
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                'Chat with Project Managers',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF412ad5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Projects',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchProjects,
          ),
        ],
      ),
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
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF412ad5),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF412ad5),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: const [
                          Tab(text: 'Ongoing & Upcoming'),
                          Tab(text: 'Finished'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _ongoingProjects.isEmpty
                              ? _buildNoProjectsContent(
                                  'No ongoing or upcoming projects.',
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    childAspectRatio: 3 / 2,
                                    crossAxisSpacing: 16.0,
                                    mainAxisSpacing: 16.0,
                                  ),
                                  itemCount: _ongoingProjects.length,
                                  itemBuilder: (context, index) =>
                                      _buildProjectCard(
                                          _ongoingProjects[index]),
                                ),
                          _finishedProjects.isEmpty
                              ? _buildNoProjectsContent(
                                  'No finished projects.',
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    childAspectRatio: 3 / 2,
                                    crossAxisSpacing: 16.0,
                                    mainAxisSpacing: 16.0,
                                  ),
                                  itemCount: _finishedProjects.length,
                                  itemBuilder: (context, index) =>
                                      _buildProjectCard(
                                          _finishedProjects[index],
                                          isFinished: true),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
