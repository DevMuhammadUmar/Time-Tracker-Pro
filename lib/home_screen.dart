// home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '/providers/time_entry_provider.dart';
import 'add_time_entry_screen.dart';
import 'add_project_screen.dart';
import 'add_task_screen.dart';
import 'project_task_management_screen.dart';
import '/models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Widget _buildDrawer(TimeEntryProvider provider) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text(
            'Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.folder, color: Colors.blue),
          title: const Text('Projects'),
          trailing: Text(
            '${provider.projects.length}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProjectScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.task, color: Colors.green),
          title: const Text('Tasks'),
          trailing: Text(
            '${provider.tasks.length}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTaskScreen(),
              ),
            );
          },
        ),
      ],
    ),
  );
}

  Widget _buildAllEntriesTab(TimeEntryProvider provider) {
    final entries = provider.timeEntries.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No time entries yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start tracking your time!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final project = provider.getProject(entry.projectId);
        final task = provider.getTask(entry.taskId);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.timer,
                color: Colors.blue.shade700,
              ),
            ),
            title: Text(
              '${project?.name ?? 'Unknown'} - ${task?.name ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(DateFormat('MMM dd, yyyy • HH:mm').format(entry.date)),
                if (entry.notes?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry.notes!,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(entry.duration),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Delete Time Entry'),
                            content: const Text(
                              'Are you sure you want to delete this time entry?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deleteTimeEntry(entry.id);
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Time entry deleted'),
                                    ),
                                  );
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedByProjectsTab(TimeEntryProvider provider) {
    final timeByProject = provider.getTimeByProject();

    if (timeByProject.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No project data yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add some time entries to see project summaries',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.projects.length,
      itemBuilder: (context, index) {
        final project = provider.projects[index];
        final projectEntries = provider.getTimeEntriesForProject(project.id);
        final totalTime = provider.getTotalTimeForProject(project.id);
        final tasksCount = provider.getTasksForProject(project.id).length;

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
              project.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$tasksCount tasks • ${projectEntries.length} entries',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Text(
              _formatDuration(totalTime),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
            children: projectEntries.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No time entries for this project yet.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ]
                : projectEntries.map((entry) {
                    final task = provider.getTask(entry.taskId);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 4,
                      ),
                      leading: const Icon(Icons.schedule, size: 20),
                      title: Text(task?.name ?? 'Unknown Task'),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy').format(entry.date),
                      ),
                      trailing: Text(
                        _formatDuration(entry.duration),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    );
                  }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimeEntryProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Time Tracker',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 2,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.list),
                  text: 'All Entries',
                ),
                Tab(
                  icon: Icon(Icons.folder),
                  text: 'Grouped by Projects',
                ),
              ],
            ),
          ),
          drawer: _buildDrawer(provider),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAllEntriesTab(provider),
              _buildGroupedByProjectsTab(provider),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTimeEntryScreen(),
                ),
              );
            },
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}