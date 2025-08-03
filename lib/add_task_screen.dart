// add_task_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/time_entry_provider.dart';
import '/models/models.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  Project? _selectedProject;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    final provider = Provider.of<TimeEntryProvider>(context, listen: false);

    if (provider.projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a project first before adding tasks'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _selectedProject = provider.projects.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      hintText: 'Enter task name',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Project>(
                    value: _selectedProject,
                    decoration: const InputDecoration(
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        provider.projects.map((project) {
                          return DropdownMenuItem<Project>(
                            value: project,
                            child: Text(project.name),
                          );
                        }).toList(),
                    onChanged: (Project? newValue) {
                      setState(() {
                        _selectedProject = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _nameController.clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isNotEmpty && _selectedProject != null) {
                      provider.addTask(name, _selectedProject!.id);
                      _nameController.clear();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task "$name" added to "${_selectedProject!.name}"',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text(
            'Are you sure you want to delete "${task.name}"?\n\nThis will also delete all associated time entries.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final provider = Provider.of<TimeEntryProvider>(
                  context,
                  listen: false,
                );
                provider.deleteTask(task.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "${task.name}" deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeEntryProvider>(
      builder: (context, provider, child) {
        // Group tasks by project
        final tasksByProject = <String, List<Task>>{};
        for (final task in provider.tasks) {
          final project = provider.getProject(task.projectId);
          final projectName = project?.name ?? 'Unknown Project';
          tasksByProject.putIfAbsent(projectName, () => []).add(task);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Tasks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body:
              provider.tasks.isEmpty
                  ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tasks yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap the + button to add your first task',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasksByProject.keys.length,
                    itemBuilder: (context, projectIndex) {
                      final projectName = tasksByProject.keys.elementAt(
                        projectIndex,
                      );
                      final projectTasks = tasksByProject[projectName]!;
                      final project = provider.projects.firstWhere(
                        (p) => p.name == projectName,
                        orElse: () => Project(id: '', name: projectName),
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.folder,
                              color: Colors.green.shade700,
                            ),
                          ),
                          title: Text(
                            projectName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${projectTasks.length} tasks'),
                          children:
                              projectTasks.map((task) {
                                final totalTime = provider.getTotalTimeForTask(
                                  task.id,
                                );
                                final entriesCount =
                                    provider
                                        .getTimeEntriesForTask(task.id)
                                        .length;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    radius: 16,
                                    child: Icon(
                                      Icons.task,
                                      color: Colors.blue.shade700,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    task.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Text('$entriesCount entries'),
                                      Text(
                                        'Total time: ${_formatDuration(totalTime)}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    itemBuilder:
                                        (context) => [
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
                                    onSelected: (value) {
                                      if (value == 'delete') {
                                        _showDeleteConfirmation(task);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    },
                  ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskDialog,
            backgroundColor: Colors.green.shade600,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
