// lib/models/project.dart
class Project {
  final String? id;
  final String? clientName;
  final String? location;
  final String? description;
  final DateTime? startDate;
  final DateTime? targetDeadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final List<Document>? documents; // New
  final double? budget;
  final List<Employee>? employees; // New
  final double? expenses;
  final int? progress;
  final String? status;
  final List<Activity>? activities; // New
  final String? imageUrl; // New
  final String? projectManager; // Added based on image content
  final String? contactPerson; // Added based on image content
  final String? contactEmail; // Added based on image content
  final String? contactPhone; // Added based on image content

  Project({
    this.id,
    this.clientName,
    this.location,
    this.description,
    this.startDate,
    this.targetDeadline,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.documents,
    this.budget,
    this.employees,
    this.expenses,
    this.progress,
    this.status,
    this.activities,
    this.imageUrl,
    this.projectManager,
    this.contactPerson,
    this.contactEmail,
    this.contactPhone,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse a double
    double? _safeParseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.tryParse(value);
      }
      // If it's a map or any other type, return null
      return null;
    }

    // Helper function to safely parse an int
    int? _safeParseInt(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is num) {
        return value.toInt(); // Handles doubles like 5.0 gracefully
      } else if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    // --- START DEBUGGING ADDITIONS ---
    print('--- Parsing Project.fromJson ---');
    print('Full JSON map keys: ${json.keys}'); // See all top-level keys
    print(
        'JSON documents field type: ${json['documents']?.runtimeType}'); // Check the actual type of 'documents'
    print(
        'JSON documents field value: ${json['documents']}'); // See the raw value

    List<Document>? parsedDocuments;
    if (json.containsKey('documents') && json['documents'] is List) {
      try {
        parsedDocuments = (json['documents'] as List<dynamic>)
            .map((e) {
              if (e is Map<String, dynamic>) {
                return Document.fromJson(e);
              } else {
                print('Error: Document item in list is not a Map: $e');
                return null; // Return null for items that aren't maps
              }
            })
            .whereType<Document>() // Filters out any nulls from failed parsing
            .toList();
        print('Successfully parsed ${parsedDocuments.length} documents.');
      } catch (e) {
        print('Error parsing documents list: $e');
        parsedDocuments = null; // Ensure it's null on error
      }
    } else {
      print('Documents field is missing or not a List.');
      parsedDocuments = null; // Ensure it's null if conditions aren't met
    }
    // --- END DEBUGGING ADDITIONS ---

    return Project(
      id: json['_id'] as String?,
      clientName: json['clientName'] as String?,
      location: json['location'] as String?,
      description: json['description'] as String?,
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      targetDeadline: json['targetDeadline'] != null
          ? DateTime.parse(json['targetDeadline'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      v: json['__v'] as int?,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => Document.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Use safe parsing for budget, expenses, and progress
      budget: _safeParseDouble(json['budget']),
      employees: (json['employees'] as List<dynamic>?)
          ?.map((e) => Employee.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: _safeParseDouble(json['expenses']),
      progress: _safeParseInt(json['progress']),
      status: json['status'] as String?,
      activities: (json['activities'] as List<dynamic>?)
          ?.map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      projectManager: json['projectManager'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
    );
  }
}

class Document {
  final String? name;
  final String? url;
  final String? id;

  Document({this.name, this.url, this.id});

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      name: json['name'] as String?,
      url: json['url'] as String?,
      id: json['_id'] as String?,
    );
  }
}

class Employee {
  final String? name;
  final String? role;

  Employee({this.name, this.role});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'] as String?,
      role: json['role'] as String?,
    );
  }
}

class Activity {
  final String? name;
  final DateTime? dueDate;
  final String? status;

  Activity({this.name, this.dueDate, this.status});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      name: json['name'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      status: json['status'] as String?,
    );
  }
}
