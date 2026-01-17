import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/cards/semester_card.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/constants/route_constants.dart';

/// Root homepage screen displaying semester cards
class RootHomepageScreen extends StatelessWidget {
  const RootHomepageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Vaultscapes'),
          trailing: [
            IconButton.ghost(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Search functionality - Phase 2
                _showSearchPlaceholder(context);
              },
            ),
          ],
        ),
      ],
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer2<AuthProvider, NavigationProvider>(
      builder: (context, authProvider, navProvider, child) {
        final theme = Theme.of(context);

        if (navProvider.isLoading && navProvider.semesters.isEmpty) {
          return const LoadingIndicator(message: 'Loading semesters...');
        }

        if (navProvider.errorMessage != null && navProvider.semesters.isEmpty) {
          return AppErrorWidget.generic(
            message: navProvider.errorMessage,
            onRetry: () => navProvider.loadSemesters(),
          );
        }

        return CustomScrollView(
            slivers: [
              // Greeting Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Helpers.getGreeting(
                          name: authProvider.isAuthenticated
                              ? authProvider.user?.displayName
                              : null,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'What would you like to study today?',
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Semester Cards Grid
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final semester = navProvider.semesters[index];
                      return SemesterCard(
                        semester: semester,
                        onTap: () {
                          context.push(
                            RouteConstants.semesterPath(semester.id.toString()),
                          );
                        },
                      );
                    },
                    childCount: navProvider.semesters.length,
                  ),
                ),
              ),
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
      },
    );
  }

  void _showSearchPlaceholder(BuildContext context) {
    showToast(
      context: context,
      builder: (context, overlay) {
        return SurfaceCard(
          child: Basic(
            title: const Text('Search coming soon'),
            subtitle: const Text('Search functionality will be available in Phase 2'),
            leading: const Icon(Icons.search),
            trailing: IconButton.ghost(
              icon: const Icon(Icons.close),
              onPressed: () => overlay.close(),
            ),
          ),
        );
      },
      location: ToastLocation.bottomCenter,
    );
  }
}
