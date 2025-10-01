import 'package:flutter/material.dart';
import 'package:chat_app/models/project.dart'; // Import your Project model
import 'package:intl/intl.dart'; // For date formatting
import 'package:cached_network_image/cached_network_image.dart'; // For CachedNetworkImage and CachedNetworkImageProvider
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMMM d, yyyy') // Changed to 'YYYY' for clarity
        .format(date);
  }

  // Helper widget for "No Image" content
  Widget _buildNoImageContent() {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFF262626), // Very dark grey, closer to black
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

  // Helper for section titles with consistent styling and optional icon
  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0), // Consistent padding
      child: Row(
        children: [
          if (icon != null) ...[
            // Add icon if provided
            Icon(icon, color: const Color(0xFF412ad5), size: 24),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            // Pushes the divider to the right
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Divider(color: Colors.grey[300], thickness: 1),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for detail rows with consistent styling and optional icon
  // Designed for single line items, useful within Wrap or Column
  Widget _buildDetailItem(String label, String? value,
      {IconData? icon, Color? valueColor}) {
    if (value == null || value.isEmpty || value == 'N/A') {
      return const SizedBox.shrink();
    }
    return Column(
      // Use Column to stack label and value if needed
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
            ],
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.0,
            color: valueColor ?? Colors.black54,
          ),
          maxLines: 2, // Allow value to wrap
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // _buildDeadlineItem (retains original look for now)
  // This is used for 'Upcoming Deadlines' which are usually a vertical list
  Widget _buildDeadlineItem(String name, DateTime? deadline) {
    if (deadline == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            ),
            const Text(
              'N/A',
              style: TextStyle(fontSize: 16.0, color: Colors.black54),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16.0, color: Colors.black87),
          ),
          Text(
            _formatDate(deadline),
            style: const TextStyle(fontSize: 16.0, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Helper to build an activity list item for a grouped display
  Widget _buildActivityListItem(Activity activity) {
    final activityName = activity.name ?? 'Activity';
    final activityStatus = activity.status ?? 'N/A';
    final activityDueDate = _formatDate(activity.dueDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(
            activityStatus.toLowerCase() == 'completed'
                ? Icons.check_circle_outline
                : Icons.pending_actions,
            color: activityStatus.toLowerCase() == 'completed'
                ? Colors.green
                : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityName,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Due: $activityDueDate',
                  style: const TextStyle(fontSize: 12.0, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New helper to build an employee list item for a grouped display
  Widget _buildEmployeeListItem(Employee employee) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline, color: Colors.black54),
          title: Text(employee.name ?? 'Unknown Employee',
              style: const TextStyle(fontSize: 16.0, color: Colors.black87)),
          subtitle: Text(employee.role ?? 'N/A',
              style: const TextStyle(fontSize: 14.0, color: Colors.black54)),
        ),
        Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey[200]),
      ],
    );
  }

  // Refactored: _buildDocumentItem to use ListTile for better aesthetics and dividers
  Widget _buildDocumentItem(BuildContext context, String name, String url) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.insert_drive_file_outlined,
              color: Colors.black54),
          title: Text(
            name,
            style: const TextStyle(fontSize: 16.0, color: Colors.blue),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () async {
            if (url.isNotEmpty) {
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Could not open document. No app available.')),
                  );
                }
              } catch (e) {
                print('Error parsing or launching URL "$url": $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Invalid document link. Please check the URL.')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document URL is empty.')),
              );
            }
          },
        ),
        Divider(indent: 16.0, endIndent: 16.0, color: Colors.grey[200]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = project.imageUrl;

    // Filter activities by status
    final List<Activity> completedActivities = project.activities
            ?.where((activity) => activity.status?.toLowerCase() == 'completed')
            .toList() ??
        [];
    final List<Activity> pendingActivities = project.activities
            ?.where((activity) => activity.status?.toLowerCase() == 'pending')
            .toList() ??
        [];
    final List<Activity> otherActivities = project.activities
            ?.where((activity) =>
                activity.status?.toLowerCase() != 'completed' &&
                activity.status?.toLowerCase() != 'pending')
            .toList() ??
        []; // For any other statuses

    // Group employees by role
    final Map<String, List<Employee>> employeesByRole = {};
    for (var employee in project.employees ?? []) {
      final role = employee.role ?? 'Unassigned';
      if (!employeesByRole.containsKey(role)) {
        employeesByRole[role] = [];
      }
      employeesByRole[role]?.add(employee);
    }

    // Sort roles alphabetically for consistent display
    final List<String> sortedRoles = employeesByRole.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent, // Scaffold transparent
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.only(left: 16.0, top: 8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Container(
        // The main background color/texture
        decoration: const BoxDecoration(
          color: Color.fromARGB(
              255, 245, 233, 255), // Your desired light background color
          // Removed image property to use solid color
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Header (Image, Client Name, Description, Location)
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.grey.shade400),
                                ),
                                errorWidget: (context, url, error) {
                                  print(
                                      'Error loading detail screen image: $error');
                                  return _buildNoImageContent();
                                },
                              )
                            : _buildNoImageContent(),
                      ),
                    ),
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
                    Positioned(
                      bottom: 16.0,
                      left: 16.0,
                      right: 16.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  project.location ?? 'N/A Location',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            project.description ?? 'No description available',
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area with Padding and Cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Project Progress ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Project Progress',
                                icon: Icons.bar_chart),
                            const SizedBox(height: 16.0),
                            Center(
                              child: SizedBox(
                                width: 110,
                                height: 110,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF412ad5),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 88,
                                      height: 88,
                                      child: CircularProgressIndicator(
                                        value: (project.progress ?? 0) / 100,
                                        strokeWidth: 6,
                                        backgroundColor:
                                            const Color(0xFF412ad5),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    Text(
                                      '${project.progress ?? 0}%',
                                      style: const TextStyle(
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if ((project.progress ?? 0) == 0 ||
                                        (project.progress ?? 0) == 100)
                                      Positioned(
                                        top: 10,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Image.asset(
                                'assets/construction_noBG.png',
                                fit: BoxFit
                                    .contain, // Ensure the whole image fits
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            const Center(
                              child: Text(
                                'Keep up the great work!',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.black54),
                              ),
                            ),
                            const SizedBox(height: 12.0),
                          ],
                        ),
                      ),
                    ),

                    // --- COMBINED & EXPANDABLE: Project Details (Dates, Status, Budget, Contact Info, Activities) ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        // Using ExpansionTile here
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        title: _buildSectionTitle('Project Details',
                            icon: Icons.info_outline),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        children: <Widget>[
                          const SizedBox(height: 8.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailItem('Start Date',
                                        _formatDate(project.startDate),
                                        icon: Icons.calendar_today),
                                    const SizedBox(
                                        height: 12.0), // Spacing between items
                                    _buildDetailItem('Deadline',
                                        _formatDate(project.targetDeadline),
                                        icon: Icons.event),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  width: 20), // Space between columns
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailItem('Status', project.status,
                                        icon: Icons.pending_actions,
                                        valueColor:
                                            project.status?.toLowerCase() ==
                                                    'pending'
                                                ? Colors.orange
                                                : Colors.green),
                                    const SizedBox(height: 12.0),
                                    _buildDetailItem(
                                        'Budget',
                                        project.budget != null
                                            ? '₱${project.budget!.toStringAsFixed(2)}'
                                            : 'N/A',
                                        icon: Icons.currency_exchange),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          _buildDetailItem(
                              'Project Manager', project.projectManager,
                              icon: Icons.person_outline),
                          _buildDetailItem(
                              'Contact Person', project.contactPerson,
                              icon: Icons.contacts),
                          _buildDetailItem(
                              'Contact Email', project.contactEmail,
                              icon: Icons.email_outlined),
                          _buildDetailItem(
                              'Contact Phone', project.contactPhone,
                              icon: Icons.phone_outlined),

                          const Divider(
                              height: 30,
                              thickness: 1,
                              indent: 0,
                              endIndent: 0), // Separator for activities

                          // Group 3: Activities:
                          const Text(
                            'Activities:',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8.0),

                          // --- Completed Activities Section ---
                          if (completedActivities.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Divider(
                                          color: Colors.grey[300],
                                          thickness: 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...completedActivities
                                .map((activity) =>
                                    _buildActivityListItem(activity))
                                .toList(),
                            const SizedBox(
                                height: 16.0), // Add spacing between groups
                          ],

                          // --- Pending Activities Section ---
                          if (pendingActivities.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.pending_actions,
                                      color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Divider(
                                          color: Colors.grey[300],
                                          thickness: 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...pendingActivities
                                .map((activity) =>
                                    _buildActivityListItem(activity))
                                .toList(),
                            const SizedBox(
                                height: 16.0), // Add spacing between groups
                          ],

                          // --- Other Activities Section (if any) ---
                          if (otherActivities.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.blueGrey, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Other Status',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Divider(
                                          color: Colors.grey[300],
                                          thickness: 1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...otherActivities
                                .map((activity) =>
                                    _buildActivityListItem(activity))
                                .toList(),
                            const SizedBox(
                                height: 16.0), // Add spacing between groups
                          ],

                          // Fallback if no activities at all
                          if (project.activities == null ||
                              project.activities!.isEmpty)
                            const Text(
                              'No specific activities with deadlines.',
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.black54),
                            ),
                        ],
                      ),
                    ),

                    // --- Assigned Employees ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        title: _buildSectionTitle('Assigned Employees',
                            icon: Icons.people),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        children: <Widget>[
                          const SizedBox(height: 8.0),
                          if (project.employees != null &&
                              project.employees!.isNotEmpty)
                            ...sortedRoles.map((role) {
                              final employeesInRole = employeesByRole[role]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      children: [
                                        // Icon for the role, if desired (e.g., specific icon for "Engineer")
                                        const Icon(Icons.person,
                                            color: Colors.blueGrey, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          role, // Display the role name as a sub-heading
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Divider(
                                                color: Colors.grey[300],
                                                thickness: 1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...employeesInRole
                                      .map((employee) =>
                                          _buildEmployeeListItem(employee))
                                      .toList(),
                                  if (role !=
                                      sortedRoles
                                          .last) // Add spacing between role groups
                                    const SizedBox(height: 16.0),
                                ],
                              );
                            }).toList()
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'No employees assigned.',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.black54),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // --- Project Documents ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        title: _buildSectionTitle('Project Documents',
                            icon: Icons.folder_open),
                        childrenPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        children: <Widget>[
                          const SizedBox(height: 8.0),
                          if (project.documents != null &&
                              project.documents!.isNotEmpty)
                            ...project.documents!.map((document) {
                              if (document.name != null &&
                                  document.name != 'Object' &&
                                  document.url != null &&
                                  document.url != 'Object' &&
                                  document.url!.isNotEmpty) {
                                return _buildDocumentItem(
                                    context, document.name!, document.url!);
                              } else {
                                print(
                                    'Skipping invalid document: ${document.name} - ${document.url}');
                                return const SizedBox.shrink();
                              }
                            }).toList()
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Text(
                                'No documents uploaded.',
                                style: TextStyle(
                                    fontSize: 14.0, color: Colors.black54),
                              ),
                            ),
                        ],
                      ),
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
}
