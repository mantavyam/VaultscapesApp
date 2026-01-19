import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/markdown_content_service.dart';
import '../../../data/services/markdown_parser.dart';
import '../../widgets/content/markdown_content_renderer.dart';
import '../../widgets/content/content_loading_skeleton.dart';

/// Generic screen for displaying Gitbook content
/// Fetches markdown from URL, parses it, and renders with shadcn_flutter
class GitbookContentScreen extends StatefulWidget {
  final String title;
  final String gitbookUrl;
  final String? subtitle;

  const GitbookContentScreen({
    super.key,
    required this.title,
    required this.gitbookUrl,
    this.subtitle,
  });

  @override
  State<GitbookContentScreen> createState() => _GitbookContentScreenState();
}

class _GitbookContentScreenState extends State<GitbookContentScreen> {
  final MarkdownContentService _contentService = MarkdownContentService();
  final MarkdownParser _parser = MarkdownParser();

  bool _isLoading = true;
  bool _isFromCache = false;
  String? _errorMessage;
  MarkdownErrorType? _errorType;
  List<ContentBlock> _contentBlocks = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      await _contentService.init();
      final result = await _contentService.fetchContent(widget.gitbookUrl);

      if (result.isSuccess && result.content != null) {
        final blocks = _parser.parse(result.content!);
        setState(() {
          _contentBlocks = blocks;
          _isFromCache = result.fromCache;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.errorMessage ?? 'Failed to load content';
          _errorType = result.errorType;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _errorType = MarkdownErrorType.unknown;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshContent() async {
    // Clear cache and reload
    await _contentService.clearCacheFor(widget.gitbookUrl);
    await _loadContent();
  }

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
          title: Text(widget.title),
          trailing: [
            if (!_isLoading)
              IconButton.ghost(
                icon: const Icon(RadixIcons.reload),
                onPressed: _refreshContent,
              ),
          ],
        ),
      ],
      child: Column(
        children: [
          // Header with subtitle and cache indicator
          if (widget.subtitle != null || _isFromCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.muted.withValues(alpha: 0.3),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.border),
                ),
              ),
              child: Row(
                children: [
                  if (widget.subtitle != null)
                    Expanded(
                      child: Text(widget.subtitle!).muted,
                    ),
                  if (_isFromCache)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            RadixIcons.clock,
                            size: 12,
                            color: theme.colorScheme.secondaryForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cached',
                            style: theme.typography.xSmall.copyWith(
                              color: theme.colorScheme.secondaryForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const ContentLoadingSkeleton();
    }

    if (_errorMessage != null) {
      return ContentErrorWidget(
        message: _getErrorTitle(),
        details: _errorMessage,
        onRetry: _loadContent,
      );
    }

    if (_contentBlocks.isEmpty) {
      return const ContentErrorWidget(
        message: 'No content available',
        details: 'The page appears to be empty.',
      );
    }

    return MarkdownContentRenderer(
      blocks: _contentBlocks,
    );
  }

  String _getErrorTitle() {
    return switch (_errorType) {
      MarkdownErrorType.networkError => 'No Internet Connection',
      MarkdownErrorType.serverError => 'Server Error',
      MarkdownErrorType.notFound => 'Content Not Found',
      MarkdownErrorType.parseError => 'Failed to Parse Content',
      _ => 'Error Loading Content',
    };
  }
}
