import 'package:flutter/material.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/repositories/offline_project_repository.dart';
import 'package:dev_flow/presentation/views/project_details/project_details_screen.dart';
import 'package:go_router/go_router.dart';

/// A screen that loads a project by ID and displays the ProjectDetailsScreen
class ProjectLoaderScreen extends StatefulWidget {
  final String projectId;

  const ProjectLoaderScreen({super.key, required this.projectId});

  @override
  State<ProjectLoaderScreen> createState() => _ProjectLoaderScreenState();
}

class _ProjectLoaderScreenState extends State<ProjectLoaderScreen> {
  final OfflineProjectRepository _projectRepository =
      OfflineProjectRepository();
  Project? _project;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📂 Loading project: ${widget.projectId}');
      final project = await _projectRepository.getProjectById(widget.projectId);

      print('📂 Project loaded successfully: ${project.title}');
      setState(() {
        _project = project;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading project: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0E21),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    if (_error != null || _project == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0E21),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Project not found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'The project may have been deleted',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return ProjectDetailsScreen(
      project: _project!,
      onUpdate: (updatedProject) {
        setState(() {
          _project = updatedProject;
        });
      },
    );
  }
}
