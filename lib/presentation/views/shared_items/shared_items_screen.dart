import 'package:flutter/material.dart';
import 'package:dev_flow/core/utils/app_text_styles.dart';
import 'package:dev_flow/data/repositories/shared_items_repository.dart';
import 'package:dev_flow/data/models/project_model.dart';
import 'package:dev_flow/data/models/task_model.dart';
import 'package:dev_flow/presentation/widgets/shared_project_card.dart';
import 'package:dev_flow/presentation/widgets/shared_task_card.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SharedItemsScreen extends StatefulWidget {
  const SharedItemsScreen({super.key});

  @override
  State<SharedItemsScreen> createState() => _SharedItemsScreenState();
}

class _SharedItemsScreenState extends State<SharedItemsScreen> {
  final SharedItemsRepository _sharedItemsRepository = SharedItemsRepository();

  List<Map<String, dynamic>> _sharedProjects = [];
  List<Map<String, dynamic>> _sharedTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSharedItems();
  }

  Future<void> _loadSharedItems() async {
    print('🔍 DEBUG: Loading shared items...');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      print('🔍 DEBUG: Current user ID: $userId');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      print('🔍 DEBUG: Fetching shared projects...');
      final projects = await _sharedItemsRepository.getSharedProjects(userId);
      print('🔍 DEBUG: Found ${projects.length} shared projects');

      print('🔍 DEBUG: Fetching shared tasks...');
      final tasks = await _sharedItemsRepository.getSharedTasks(userId);
      print('🔍 DEBUG: Found ${tasks.length} shared tasks');

      setState(() {
        _sharedProjects = projects;
        _sharedTasks = tasks;
        _isLoading = false;
      });

      print('🔍 DEBUG: Shared items loaded successfully');
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error loading shared items: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Shared with Me',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading shared items',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadSharedItems,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSharedItems,
              color: Colors.purple,
              child: _sharedProjects.isEmpty && _sharedTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No shared items yet',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Projects and tasks shared with you\nwill appear here',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Shared Projects Section
                        if (_sharedProjects.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Shared Projects',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_sharedProjects.length}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...(_sharedProjects.map((projectData) {
                            final project = projectData['project'] as Project;
                            final sharedByEmail =
                                projectData['shared_by_email'] as String;
                            final sharedWithEmail =
                                projectData['shared_with_email'] as String;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SharedProjectCard(
                                project: project,
                                sharedByEmail: sharedByEmail,
                                sharedWithEmail: sharedWithEmail,
                                onTap: () {
                                  context.push(
                                    '/project-details/${project.id}',
                                  );
                                },
                              ),
                            );
                          })),
                          const SizedBox(height: 32),
                        ],

                        // Shared Tasks Section
                        if (_sharedTasks.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Shared Tasks',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_sharedTasks.length}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...(_sharedTasks.map((taskData) {
                            final task = taskData['task'] as Task;
                            final sharedByEmail =
                                taskData['shared_by_email'] as String;
                            final sharedWithEmail =
                                taskData['shared_with_email'] as String;
                            final projectColor =
                                taskData['project_color'] as Color? ??
                                Colors.blue;

                            return SharedTaskCard(
                              task: task,
                              projectColor: projectColor,
                              sharedByEmail: sharedByEmail,
                              sharedWithEmail: sharedWithEmail,
                              onTap: () {
                                if (task.projectId != null) {
                                  context.push(
                                    '/project-details/${task.projectId}',
                                  );
                                }
                              },
                            );
                          })),
                        ],
                      ],
                    ),
            ),
    );
  }
}
