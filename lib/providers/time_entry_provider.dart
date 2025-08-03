// time_entry_provider.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';
import 'package:collection/collection.dart';
import '/models/models.dart';

class TimeEntryProvider extends ChangeNotifier {
  final LocalStorage _localStorage = LocalStorage('time_tracker.json');

  List<Project> _projects = [];
  List<Task> _tasks = [];
  List<TimeEntry> _timeEntries = [];

  bool _isInitialized = false;

  List<Project> get projects => List.unmodifiable(_projects);
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<TimeEntry> get timeEntries => List.unmodifiable(_timeEntries);
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    await _localStorage.ready;
    await _loadData();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadData() async {
    try {
      final data = _localStorage.getItem('data');
      if (data != null) {
        final Map<String, dynamic> jsonData = Map<String, dynamic>.from(data);

        _projects =
            (jsonData['projects'] as List<dynamic>?)
                ?.map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];

        _tasks =
            (jsonData['tasks'] as List<dynamic>?)
                ?.map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];

        _timeEntries =
            (jsonData['timeEntries'] as List<dynamic>?)
                ?.map((e) => TimeEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
      }

      // Add default project and task if none exist
      if (_projects.isEmpty) {
        await addProject('General', 'General project for miscellaneous tasks');
      }
      if (_tasks.isEmpty && _projects.isNotEmpty) {
        await addTask('General Task', _projects.first.id, 'General task');
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final data = {
        'projects': _projects.map((e) => e.toJson()).toList(),
        'tasks': _tasks.map((e) => e.toJson()).toList(),
        'timeEntries': _timeEntries.map((e) => e.toJson()).toList(),
      };
      await _localStorage.setItem('data', data);
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  // Project methods
  Future<void> addProject(String name, [String? description]) async {
    final project = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
    );
    _projects.add(project);
    await _saveData();
    notifyListeners();
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    _tasks.removeWhere((t) => t.projectId == projectId);
    _timeEntries.removeWhere((e) => e.projectId == projectId);
    await _saveData();
    notifyListeners();
  }

  // Task methods
  Future<void> addTask(
    String name,
    String projectId, [
    String? description,
  ]) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      projectId: projectId,
      description: description,
    );
    _tasks.add(task);
    await _saveData();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    _timeEntries.removeWhere((e) => e.taskId == taskId);
    await _saveData();
    notifyListeners();
  }

  List<Task> getTasksForProject(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }

  // Time Entry methods
  Future<void> addTimeEntry({
    required String projectId,
    required String taskId,
    required Duration duration,
    required DateTime date,
    String? notes,
  }) async {
    final timeEntry = TimeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: projectId,
      taskId: taskId,
      duration: duration,
      date: date,
      notes: notes,
    );
    _timeEntries.add(timeEntry);
    await _saveData();
    notifyListeners();
  }

  Future<void> deleteTimeEntry(String timeEntryId) async {
    _timeEntries.removeWhere((entry) => entry.id == timeEntryId);
    await _saveData();
    notifyListeners();
  }

  // Utility methods
  Project? getProject(String projectId) {
    return _projects.firstWhereOrNull((p) => p.id == projectId);
  }

  Task? getTask(String taskId) {
    return _tasks.firstWhereOrNull((t) => t.id == taskId);
  }

  List<TimeEntry> getTimeEntriesForProject(String projectId) {
    return _timeEntries.where((entry) => entry.projectId == projectId).toList();
  }

  Map<String, Duration> getTimeByProject() {
    final Map<String, Duration> projectTimes = {};

    for (final entry in _timeEntries) {
      final project = getProject(entry.projectId);
      if (project != null) {
        final currentDuration = projectTimes[project.name] ?? Duration.zero;
        projectTimes[project.name] = currentDuration + entry.duration;
      }
    }

    return projectTimes;
  }

  Duration getTotalTimeForProject(String projectId) {
    return _timeEntries
        .where((entry) => entry.projectId == projectId)
        .fold(Duration.zero, (total, entry) => total + entry.duration);
  }

  List<TimeEntry> getTimeEntriesForTask(String taskId) {
    return _timeEntries.where((entry) => entry.taskId == taskId).toList();
  }

  Duration getTotalTimeForTask(String taskId) {
    return _timeEntries
        .where((entry) => entry.taskId == taskId)
        .fold(Duration.zero, (total, entry) => total + entry.duration);
  }
}
