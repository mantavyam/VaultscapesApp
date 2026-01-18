import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/markdown_parser.dart';

/// Widget that renders parsed markdown content blocks using shadcn_flutter components
class MarkdownContentRenderer extends StatelessWidget {
  final List<ContentBlock> blocks;
  final EdgeInsets padding;

  const MarkdownContentRenderer({
    super.key,
    required this.blocks,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Center(
        child: Text('No content available'),
      );
    }

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blocks.map((block) => _buildBlock(context, block)).toList(),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block) {
    final theme = Theme.of(context);

    return switch (block) {
      HeadingBlock() => _buildHeading(theme, block),
      ParagraphBlock() => _buildParagraph(theme, block),
      UnorderedListBlock() => _buildUnorderedList(theme, block),
      OrderedListBlock() => _buildOrderedList(theme, block),
      TaskItemBlock() => _buildTaskItem(theme, block),
      QuoteBlock() => _buildQuote(theme, block),
      CodeBlock() => _buildCodeBlock(theme, block),
      InlineCodeBlock() => _buildInlineCode(theme, block),
      ImageBlock() => _buildImage(theme, block),
      LinkBlock() => _buildLink(theme, block),
      DividerBlock() => _buildDivider(),
      HintBlock() => _buildHint(theme, block),
      TableBlock() => _buildTable(theme, block),
      TabsBlock() => _buildTabs(context, block),
      CollapsibleBlock() => _buildCollapsible(context, block),
      FileDownloadBlock() => _buildFileDownload(theme, block),
      EmbedBlock() => _buildEmbed(theme, block),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildHeading(ThemeData theme, HeadingBlock block) {
    final style = switch (block.level) {
      1 => theme.typography.h1,
      2 => theme.typography.h2,
      3 => theme.typography.h3,
      _ => theme.typography.h4,
    };

    return Padding(
      padding: EdgeInsets.only(
        top: block.level == 1 ? 0 : 24,
        bottom: 12,
      ),
      child: Text(
        block.text,
        style: style,
      ),
    );
  }

  Widget _buildParagraph(ThemeData theme, ParagraphBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildRichText(theme, block.text),
    );
  }

  Widget _buildRichText(ThemeData theme, String text) {
    // Parse inline formatting: **bold**, *italic*, `code`
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    
    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add text before match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: theme.typography.p,
        ));
      }
      
      // Add formatted text
      if (match.group(1) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(1),
          style: theme.typography.p.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(2),
          style: theme.typography.p.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null) {
        // Inline code
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: theme.colorScheme.muted,
            fontSize: theme.typography.p.fontSize,
          ),
        ));
      }
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: theme.typography.p,
      ));
    }
    
    if (spans.isEmpty) {
      return Text(text, style: theme.typography.p);
    }
    
    return Text.rich(TextSpan(children: spans));
  }

  Widget _buildUnorderedList(ThemeData theme, UnorderedListBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.map((item) => _buildListItem(
          theme,
          item,
          bullet: '•',
        )).toList(),
      ),
    );
  }

  Widget _buildOrderedList(ThemeData theme, OrderedListBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: block.items.asMap().entries.map((entry) => _buildListItem(
          theme,
          entry.value,
          number: entry.key + 1,
        )).toList(),
      ),
    );
  }

  Widget _buildListItem(
    ThemeData theme,
    ListItemData item, {
    String? bullet,
    int? number,
  }) {
    Widget marker;
    if (item.isChecked != null) {
      // Task list item
      marker = Checkbox(
        state: item.isChecked! ? CheckboxState.checked : CheckboxState.unchecked,
        onChanged: null,
      );
    } else if (bullet != null) {
      marker = SizedBox(
        width: 20,
        child: Text(bullet, style: theme.typography.p),
      );
    } else {
      marker = SizedBox(
        width: 24,
        child: Text('$number.', style: theme.typography.p, textAlign: TextAlign.right),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              marker,
              const SizedBox(width: 8),
              Expanded(child: _buildRichText(theme, item.text)),
            ],
          ),
          // Nested items
          if (item.nestedItems != null && item.nestedItems!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.nestedItems!.map((nested) => _buildListItem(
                  theme,
                  nested,
                  bullet: '◦',
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(ThemeData theme, TaskItemBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Checkbox(
            state: block.isChecked ? CheckboxState.checked : CheckboxState.unchecked,
            onChanged: null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(block.text, style: theme.typography.p)),
        ],
      ),
    );
  }

  Widget _buildQuote(ThemeData theme, QuoteBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.border,
              width: 4,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: Text(
          block.text,
          style: theme.typography.p.copyWith(fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildCodeBlock(ThemeData theme, CodeBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.title != null || block.language != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.border),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(RadixIcons.code, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      block.title ?? block.language ?? 'Code',
                      style: theme.typography.small,
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.muted,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  block.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineCode(ThemeData theme, InlineCodeBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          block.code,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme, ImageBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: block.url,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                height: 200,
                color: theme.colorScheme.muted,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: theme.colorScheme.muted,
                child: const Center(
                  child: Icon(RadixIcons.image),
                ),
              ),
            ),
          ),
          if (block.caption != null || block.alt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                block.caption ?? block.alt ?? '',
              ).muted(),
            ),
        ],
      ),
    );
  }

  Widget _buildLink(ThemeData theme, LinkBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _launchUrl(block.url),
        child: Text(
          block.text,
          style: theme.typography.p.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(),
    );
  }

  Widget _buildHint(ThemeData theme, HintBlock block) {
    final (icon, isDestructive) = switch (block.style) {
      HintStyle.info => (RadixIcons.infoCircled, false),
      HintStyle.success => (RadixIcons.checkCircled, false),
      HintStyle.warning => (RadixIcons.exclamationTriangle, false),
      HintStyle.danger => (RadixIcons.crossCircled, true),
    };

    final title = block.title ?? switch (block.style) {
      HintStyle.info => 'Info',
      HintStyle.success => 'Success',
      HintStyle.warning => 'Warning',
      HintStyle.danger => 'Error',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Alert(
        leading: Icon(icon),
        title: Text(title),
        content: Text(block.content),
        destructive: isDestructive,
      ),
    );
  }

  Widget _buildTable(ThemeData theme, TableBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          rows: [
            // Header row
            if (block.headers.isNotEmpty)
              TableRow(
                cells: block.headers.map((h) => TableCell(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: theme.colorScheme.muted,
                    child: Text(h).semiBold(),
                  ),
                )).toList(),
              ),
            // Data rows
            ...block.rows.map((row) => TableRow(
              cells: row.map((cell) => TableCell(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(cell),
                ),
              )).toList(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, TabsBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _TabsWidget(block: block),
    );
  }

  Widget _buildCollapsible(BuildContext context, CollapsibleBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _CollapsibleWidget(block: block),
    );
  }

  Widget _buildFileDownload(ThemeData theme, FileDownloadBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Clickable(
          onPressed: () => _launchUrl(block.url),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(RadixIcons.file),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.filename ?? _extractFilename(block.url),
                      ).semiBold(),
                      if (block.caption != null)
                        Text(block.caption!).muted(),
                    ],
                  ),
                ),
                const Icon(RadixIcons.download),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmbed(ThemeData theme, EmbedBlock block) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Clickable(
          onPressed: () => _launchUrl(block.url),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(RadixIcons.link2),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_extractDomain(block.url)).semiBold(),
                      Text(
                        block.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).muted(),
                    ],
                  ),
                ),
                const Icon(RadixIcons.externalLink),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractFilename(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'Download';
    final segments = uri.pathSegments;
    if (segments.isEmpty) return 'Download';
    return segments.last;
  }

  String _extractDomain(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.host;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Stateful widget for tabs
class _TabsWidget extends StatefulWidget {
  final TabsBlock block;

  const _TabsWidget({required this.block});

  @override
  State<_TabsWidget> createState() => _TabsWidgetState();
}

class _TabsWidgetState extends State<_TabsWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Tabs(
          index: _currentIndex,
          onChanged: (i) => setState(() => _currentIndex = i),
          children: widget.block.tabs.map((tab) => TabItem(
            child: Text(tab.title),
          )).toList(),
        ),
        const SizedBox(height: 8),
        if (widget.block.tabs.isNotEmpty && _currentIndex < widget.block.tabs.length)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.block.tabs[_currentIndex].content
                .map((block) => MarkdownContentRenderer(
                  blocks: [block],
                  padding: EdgeInsets.zero,
                ))
                .toList(),
          ),
      ],
    );
  }
}

/// Stateful widget for collapsible sections
class _CollapsibleWidget extends StatefulWidget {
  final CollapsibleBlock block;

  const _CollapsibleWidget({required this.block});

  @override
  State<_CollapsibleWidget> createState() => _CollapsibleWidgetState();
}

class _CollapsibleWidgetState extends State<_CollapsibleWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        children: [
          Clickable(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? RadixIcons.chevronDown : RadixIcons.chevronRight,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.block.title).semiBold(),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.block.content
                    .map((block) => MarkdownContentRenderer(
                      blocks: [block],
                      padding: EdgeInsets.zero,
                    ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
