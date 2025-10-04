// lib/models/project_model.dart

class Project {
  final String? id;

  // Populated refs from backend
  final ProjectUser? client;          // { fullName, email, contactNumber, _id }
  final ProjectUser? projectManager;  // { fullName, contactNumber, _id }
  final List<ProjectUser> projectExtras;

  // Optional legacy/free-text
  final String? clientName;

  // Metadata
  final String? name;
  final String? location;
  final String? description;
  final DateTime? startDate;
  final DateTime? targetDeadline;

  final String? status;
  final double? budget;
  final double? expenses;
  final String? imageUrl;
  final int? progress;

  // Embedded collections
  final List<Employee> employees;
  final List<Activity> activities;
  final List<ProjectDocument> documents;

  // Timestamps / version
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Project({
    this.id,
    this.client,
    this.projectManager,
    this.projectExtras = const [],
    this.clientName,
    this.name,
    this.location,
    this.description,
    this.startDate,
    this.targetDeadline,
    this.status,
    this.budget,
    this.expenses,
    this.imageUrl,
    this.progress,
    this.employees = const [],
    this.activities = const [],
    this.documents = const [],
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Coerce helpers
    Map<String, dynamic>? _map(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v as Map) : null;

    double? _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int? _toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    List<T> _listOf<T>(dynamic v, T Function(Map<String, dynamic>) fromJson) {
      if (v is List) {
        return v
            .where((e) => e is Map)
            .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return <T>[];
    }

    return Project(
      id: json['_id']?.toString(),
      client: _map(json['client']) != null 
          ? ProjectUser.fromJson(_map(json['client'])!) 
          : null,
      projectManager: _map(json['projectManager']) != null
          ? ProjectUser.fromJson(_map(json['projectManager'])!)
          : null,
      projectExtras: (json['projectExtras'] is List)
          ? (json['projectExtras'] as List)
              .where((e) => e is Map)
              .map((e) => ProjectUser.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const <ProjectUser>[],
      clientName: json['clientName']?.toString(),
      name: json['name']?.toString(),
      location: json['location']?.toString(),
      description: json['description']?.toString(),
      startDate: json['startDate'] != null 
          ? DateTime.tryParse(json['startDate'].toString()) 
          : null,
      targetDeadline: json['targetDeadline'] != null 
          ? DateTime.tryParse(json['targetDeadline'].toString()) 
          : null,
      status: json['status']?.toString(),
      budget: _toDouble(json['budget']),
      expenses: _toDouble(json['expenses']),
      imageUrl: json['imageUrl']?.toString(),
      progress: _toInt(json['progress']),
      employees: _listOf<Employee>(json['employees'], Employee.fromJson),
      activities: _listOf<Activity>(json['activities'], Activity.fromJson),
      documents: _listOf<ProjectDocument>(json['documents'], ProjectDocument.fromJson),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) 
          : null,
      v: _toInt(json['__v']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'client': client?.toJson(),
      'projectManager': projectManager?.toJson(),
      'projectExtras': projectExtras.map((e) => e.toJson()).toList(),
      'clientName': clientName,
      'name': name,
      'location': location,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'targetDeadline': targetDeadline?.toIso8601String(),
      'status': status,
      'budget': budget,
      'expenses': expenses,
      'imageUrl': imageUrl,
      'progress': progress,
      'employees': employees.map((e) => e.toJson()).toList(),
      'activities': activities.map((e) => e.toJson()).toList(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }
}

/* ---------- Nested user ref (populated) ---------- */
class ProjectUser {
  final String? id;
  final String? fullName;
  final String? email;
  final String? contactNumber;

  ProjectUser({
    this.id,
    this.fullName,
    this.email,
    this.contactNumber,
  });

  factory ProjectUser.fromJson(Map<String, dynamic> json) {
    return ProjectUser(
      id: json['_id']?.toString(),
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'contactNumber': contactNumber,
    };
  }
}

/* ---------- Embedded docs ---------- */
class ProjectDocument {
  final String? id;
  final String? name;
  final String? url;
  final DateTime? uploadedAt;

  ProjectDocument({
    this.id,
    this.name,
    this.url,
    this.uploadedAt,
  });

  factory ProjectDocument.fromJson(Map<String, dynamic> json) {
    return ProjectDocument(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      url: json['url']?.toString(),
      uploadedAt: json['uploadedAt'] != null 
          ? DateTime.tryParse(json['uploadedAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'url': url,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }
}

class Employee {
  final String? id;
  final String? name;
  final String? role;
  final double? wagePerDay;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? assignedAt;

  Employee({
    this.id,
    this.name,
    this.role,
    this.wagePerDay,
    this.startDate,
    this.dueDate,
    this.assignedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return Employee(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      role: json['role']?.toString(),
      wagePerDay: _toDouble(json['wagePerDay']),
      startDate: json['startDate'] != null 
          ? DateTime.tryParse(json['startDate'].toString()) 
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.tryParse(json['dueDate'].toString()) 
          : null,
      assignedAt: json['assignedAt'] != null 
          ? DateTime.tryParse(json['assignedAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'role': role,
      'wagePerDay': wagePerDay,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
    };
  }
}

class Activity {
  final String? id;
  final String? name;
  final String? description;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? status;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Activity({
    this.id,
    this.name,
    this.description,
    this.startDate,
    this.dueDate,
    this.status,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      startDate: json['startDate'] != null 
          ? DateTime.tryParse(json['startDate'].toString()) 
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.tryParse(json['dueDate'].toString()) 
          : null,
      status: json['status']?.toString(),
      completedAt: json['completedAt'] != null 
          ? DateTime.tryParse(json['completedAt'].toString()) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}