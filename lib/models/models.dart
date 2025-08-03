// models.dart
class Project {
  final String id;
  final String name;
  final String? description;

  Project({required this.id, required this.name, this.description});

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Task {
  final String id;
  final String name;
  final String projectId;
  final String? description;

  Task({
    required this.id,
    required this.name,
    required this.projectId,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'projectId': projectId,
      'description': description,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      name: json['name'],
      projectId: json['projectId'],
      description: json['description'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TimeEntry {
  final String id;
  final String projectId;
  final String taskId;
  final Duration duration;
  final DateTime date;
  final String? notes;

  TimeEntry({
    required this.id,
    required this.projectId,
    required this.taskId,
    required this.duration,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'taskId': taskId,
      'duration': duration.inMinutes,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'],
      projectId: json['projectId'],
      taskId: json['taskId'],
      duration: Duration(minutes: json['duration']),
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
