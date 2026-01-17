import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../../data/models/semester_model.dart';

/// Subject card widget for displaying subject info
class SubjectCard extends StatelessWidget {
  final SubjectInfo subject;
  final VoidCallback? onTap;

  const SubjectCard({
    super.key,
    required this.subject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Clickable(
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Subject code badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getSubjectInitials(subject.code),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Subject info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.code,
                      style: TextStyle(
                        color: theme.colorScheme.mutedForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subject.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubjectInitials(String code) {
    // Extract letters from code (e.g., CS301 -> CS)
    final letters = code.replaceAll(RegExp(r'[0-9]'), '');
    if (letters.length >= 2) {
      return letters.substring(0, 2).toUpperCase();
    }
    return letters.toUpperCase();
  }
}

/// Subject list tile for compact display
class SubjectListTile extends StatelessWidget {
  final SubjectInfo subject;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SubjectListTile({
    super.key,
    required this.subject,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Clickable(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Basic(
          leading: Avatar(
            size: 40,
            initials: subject.code.substring(0, 2),
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          title: Text(
            subject.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subject.code,
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
              fontSize: 12,
            ),
          ),
          trailing: trailing ??
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.mutedForeground,
              ),
        ),
      ),
    );
  }
}
