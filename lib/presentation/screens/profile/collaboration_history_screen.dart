import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

/// Screen to display user's collaboration submission history
class CollaborationHistoryScreen extends StatelessWidget {
  const CollaborationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return _buildUnauthenticatedView(context);
        }
        return _CollaborationHistoryContent(userId: authProvider.user!.uid);
      },
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ],
          title: const Text('Your Collaborations'),
        ),
      ],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text(
                'Sign in to view your submissions',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollaborationHistoryContent extends StatelessWidget {
  final String userId;

  const _CollaborationHistoryContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ],
          title: const Text('Your Collaborations'),
        ),
      ],
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('collaborate-submit')
            .where('userId', isEqualTo: userId)
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.destructive,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading submissions',
                    style: TextStyle(color: theme.colorScheme.mutedForeground),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildCollaborationCard(context, theme, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.upload_file_outlined,
                size: 40,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No contributions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share notes, assignments, or other academic resources with the community',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () => context.go('/main/synergy'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 8),
                  Text('Submit Contribution'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborationCard(
      BuildContext context, ThemeData theme, Map<String, dynamic> data) {
    final submissionTypes = (data['submissionTypes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final subjectDetails = data['subjectDetails'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final submittedAt = data['submittedAt'] as String?;
    final semester = data['semesterSelection'] as int?;

    DateTime? date;
    if (submittedAt != null) {
      try {
        date = DateTime.parse(submittedAt);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => _showSubmissionDetails(context, theme, data),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusBadge(theme, status),
                  const Spacer(),
                  if (date != null)
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subjectDetails,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (semester != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Semester $semester',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
              if (submissionTypes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: submissionTypes.map((type) {
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.muted.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatSubmissionType(type),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.1);
        textColor = const Color(0xFF22C55E);
        label = 'Approved';
        break;
      case 'published':
        bgColor = const Color(0xFF0EA5E9).withValues(alpha: 0.1);
        textColor = const Color(0xFF0EA5E9);
        label = 'Published';
        break;
      case 'rejected':
        bgColor = const Color(0xFFDC2626).withValues(alpha: 0.1);
        textColor = const Color(0xFFDC2626);
        label = 'Rejected';
        break;
      default:
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.1);
        textColor = const Color(0xFF22C55E);
        label = 'Sent for review';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatSubmissionType(String type) {
    switch (type.toLowerCase()) {
      case 'notes':
        return 'Notes';
      case 'assignment':
        return 'Assignment';
      case 'labmanual':
        return 'Lab Manual';
      case 'questionbank':
        return 'Question Bank';
      case 'exampapers':
        return 'Exam Papers';
      case 'codeexamples':
        return 'Code Examples';
      case 'externallinks':
        return 'External Links';
      default:
        return type;
    }
  }

  void _showSubmissionDetails(
      BuildContext context, ThemeData theme, Map<String, dynamic> data) {
    final submissionTypes = (data['submissionTypes'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Submission Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                      const Spacer(),
                      IconButton.ghost(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildDetailRow(
                          theme, 'Status', _buildStatusBadge(theme, data['status'] as String? ?? 'pending')),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                          theme,
                          'Subject',
                          Text(data['subjectDetails'] as String? ?? 'N/A')),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                          theme,
                          'Semester',
                          Text('Semester ${data['semesterSelection'] ?? 'N/A'}')),
                      if (submissionTypes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                            theme,
                            'Submission Types',
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: submissionTypes.map((type) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.muted.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatSubmissionType(type),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.foreground,
                                    ),
                                  ),
                                );
                              }).toList(),
                            )),
                      ],
                      const SizedBox(height: 16),
                      _buildDetailRow(
                          theme,
                          'Source',
                          Text(data['source'] as String? ?? 'N/A')),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                          theme,
                          'Description',
                          Text(data['description'] as String? ?? 'N/A')),
                      if (data['submissionUrl'] != null && (data['submissionUrl'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                            theme, 'URL', Text(data['submissionUrl'] as String)),
                      ],
                      if (data['wantsCredit'] == true) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                            theme,
                            'Credit Name',
                            Text(data['creditName'] as String? ?? 'N/A')),
                      ],
                      const SizedBox(height: 16),
                      _buildDetailRow(
                          theme,
                          'Submitted',
                          Text(_formatFullDate(data['submittedAt'] as String?))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.foreground,
          ),
          child: value,
        ),
      ],
    );
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'N/A';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
