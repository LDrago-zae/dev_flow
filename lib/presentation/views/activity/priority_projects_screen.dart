import 'package:dev_flow/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/repositories/project_repository.dart';
import 'package:dev_flow/presentation/views/project_details/project_details_screen.dart';
import 'package:dev_flow/presentation/widgets/project_card.dart';
import 'package:dev_flow/presentation/dialogs/add_project_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PriorityProjectsScreen extends StatefulWidget {
  final ProjectPriority priority;
  final String title;
  final Color color;

  const PriorityProjectsScreen({
    super.key,
    required this.priority,
    required this.title,
    required this.color,
  });

  @override
  State<PriorityProjectsScreen> createState() => _PriorityProjectsScreenState();
}

class _PriorityProjectsScreenState extends State<PriorityProjectsScreen> {
  final ProjectRepository _projectRepository = ProjectRepository();
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final allProjects = await _projectRepository.getProjects(userId);
        final filteredProjects = allProjects
            .where((project) => project.priority == widget.priority)
            .toList();

        if (mounted) {
          setState(() {
            _projects = filteredProjects;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          AddProjectDialog.show(
            context,
            onProjectCreated: (project) async {
              try {
                await _projectRepository.createProject(project);
                // Reload projects to update the list
                await _loadProjects();
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Project created successfully!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to create project: $e')),
                  );
                }
              }
            },
          );
        },
        backgroundColor: DarkThemeColors.primary100,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: Colors.blue[400],
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Project Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_projects.length} Project',
                  style: TextStyle(
                    color: DarkThemeColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Projects List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.blue[400]),
                    )
                  : _projects.isEmpty
                  ? Center(
                      child: Text(
                        'No projects found',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ProjectCard(
                            title: project.title,
                            description: project.description,
                            deadline: project.deadline,
                            progress: project.progress,
                            cardColor: project.cardColor,
                            category: project.category,
                            priority: project.priority,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProjectDetailsScreen(
                                    project: project,
                                    onUpdate: (updatedProject) {
                                      setState(() {
                                        final index = _projects.indexWhere(
                                          (p) => p.id == updatedProject.id,
                                        );
                                        if (index != -1) {
                                          _projects[index] = updatedProject;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
