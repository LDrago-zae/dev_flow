import 'package:flutter/material.dart';
import 'package:dev_flow/data/repositories/project_members_repository.dart';
import 'package:dev_flow/presentation/widgets/member_avatars_stack.dart';

/// Wrapper that fetches and displays project member avatars
class ProjectMemberAvatars extends StatefulWidget {
  final String projectId;
  final int maxVisible;
  final double size;

  const ProjectMemberAvatars({
    super.key,
    required this.projectId,
    this.maxVisible = 4,
    this.size = 32,
  });

  @override
  State<ProjectMemberAvatars> createState() => _ProjectMemberAvatarsState();
}

class _ProjectMemberAvatarsState extends State<ProjectMemberAvatars> {
  final ProjectMembersRepository _repository = ProjectMembersRepository();
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await _repository.getProjectMembers(widget.projectId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading project members: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }

    if (_members.isEmpty) {
      return const SizedBox.shrink();
    }

    return MemberAvatarsStack(
      members: _members,
      maxAvatars: widget.maxVisible,
      avatarSize: widget.size,
      overlapFactor: 0.4,
    );
  }
}
