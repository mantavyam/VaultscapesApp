import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart'
    show DataTable, DataColumn, DataRow, DataCell, WidgetStatePropertyAll, Dialog, InteractiveViewer, TransformationController, Matrix4;
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../data/services/markdown_parser.dart';

/// Renders ContentBlocks as shadcn_flutter widgets
/// Following the gitbook-to-shadcn_flutter mapping recommendations
class MarkdownContentRenderer extends StatelessWidget {
  final List<ContentBlock> blocks;

  const MarkdownContentRenderer({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: blocks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) => _buildBlock(context, blocks[index]),
    );
  }

  Widget _buildBlock(BuildContext context, ContentBlock block) {
    // Wrap each block in a SizedBox with full width for consistent layout
    return SizedBox(
      width: double.infinity,
      child: switch (block) {
        HeadingBlock() => _buildHeading(context, block),
        ParagraphBlock() => _buildParagraph(context, block),
        UnorderedListBlock() => _buildUnorderedList(context, block),
        OrderedListBlock() => _buildOrderedList(context, block),
        TaskListBlock() => _buildTaskList(context, block),
        QuoteBlock() => _buildQuote(context, block),
        CodeBlock() => _CodeBlockWidget(block: block),
        ImageBlock() => _buildImage(context, block),
        DividerBlock() => _buildDivider(context),
        HintBlock() => _buildHint(context, block),
        TableBlock() => _buildTable(context, block),
        CardsBlock() => _buildCards(context, block),
        TabsBlock() => _TabsWidget(tabs: block.tabs),
        StepperBlock() => _buildStepper(context, block),
        ExpandableBlock() => _buildExpandable(context, block),
        FileBlock() => _buildFile(context, block),
        EmbedBlock() => _EmbedWidget(block: block),
        ContentRefBlock() => _buildContentRef(context, block),
        ButtonBlock() => _buildButton(context, block),
        MathBlock() => _buildMath(context, block),
        IconBlock() => _buildIcon(context, block),
      },
    );
  }

  // ===========================================================================
  // Block Builders
  // ===========================================================================

  /// Build heading using Text().h1, .h2, .h3, .h4
  Widget _buildHeading(BuildContext context, HeadingBlock block) {
    final text = _parseInlineFormatting(block.text);

    return switch (block.level) {
      1 => Text(text).h1(),
      2 => Text(text).h2(),
      3 => Text(text).h3(),
      4 => Text(text).h4(),
      _ => Text(text).h4(),
    };
  }

  /// Build paragraph using Text().p
  Widget _buildParagraph(BuildContext context, ParagraphBlock block) {
    if (_containsInlineElements(block.text)) {
      return _buildRichText(context, block.text);
    }
    return Text(_parseInlineFormatting(block.text)).p();
  }

  /// Build unordered list using Text().li with nested Columns
  Widget _buildUnorderedList(BuildContext context, UnorderedListBlock block) {
    return _buildNestedUnorderedList(context, block.items);
  }

  /// Build ordered list with proper level-based indexing (numbers, alphabets, bullets)
  Widget _buildOrderedList(BuildContext context, OrderedListBlock block) {
    return _buildNestedOrderedList(context, block.items);
  }

  /// Helper to build nested unordered lists
  Widget _buildNestedUnorderedList(
    BuildContext context,
    List<ListItemData> items,
  ) {
    final widgets = <Widget>[];

    for (final item in items) {
      final indent = item.level * 20.0;
      final bulletChar = _getBulletChar(item.level);

      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 20, child: Text(bulletChar).muted()),
              Expanded(
                child: _containsInlineElements(item.text)
                    ? _buildRichText(context, item.text)
                    : Text(item.text),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    ).gap(6);
  }

  /// Get bullet character based on level
  String _getBulletChar(int level) {
    switch (level % 3) {
      case 0:
        return '•';
      case 1:
        return '◦';
      case 2:
        return '▪';
      default:
        return '•';
    }
  }

  /// Helper to build nested ordered lists with level-based indexing
  Widget _buildNestedOrderedList(
    BuildContext context,
    List<ListItemData> items,
  ) {
    final widgets = <Widget>[];
    final levelCounters = <int, int>{};

    for (final item in items) {
      final level = item.level;
      final indent = level * 20.0;

      // Initialize or increment counter for this level
      levelCounters[level] = (levelCounters[level] ?? 0) + 1;

      // Reset counters for deeper levels
      for (final key in levelCounters.keys.toList()) {
        if (key > level) {
          levelCounters.remove(key);
        }
      }

      final indexStr = _getOrderedListIndex(level, levelCounters[level]!);

      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: Text(indexStr).muted()),
              Expanded(
                child: _containsInlineElements(item.text)
                    ? _buildRichText(context, item.text)
                    : Text(item.text),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    ).gap(6);
  }

  /// Get ordered list index based on level (numbers → alphabets → roman)
  String _getOrderedListIndex(int level, int index) {
    switch (level % 3) {
      case 0:
        return '$index.';
      case 1:
        return '${_numberToAlphabet(index)}.';
      case 2:
        return '${_numberToRoman(index)}.';
      default:
        return '$index.';
    }
  }

  /// Convert number to lowercase alphabet (1=a, 2=b, ...)
  String _numberToAlphabet(int n) {
    if (n <= 0) return '';
    final buffer = StringBuffer();
    while (n > 0) {
      n--;
      buffer.write(String.fromCharCode('a'.codeUnitAt(0) + (n % 26)));
      n ~/= 26;
    }
    return buffer.toString().split('').reversed.join();
  }

  /// Convert number to lowercase roman numerals
  String _numberToRoman(int n) {
    if (n <= 0 || n > 3999) return '$n';
    final romanNumerals = [
      (1000, 'm'),
      (900, 'cm'),
      (500, 'd'),
      (400, 'cd'),
      (100, 'c'),
      (90, 'xc'),
      (50, 'l'),
      (40, 'xl'),
      (10, 'x'),
      (9, 'ix'),
      (5, 'v'),
      (4, 'iv'),
      (1, 'i'),
    ];
    final buffer = StringBuffer();
    for (final (value, numeral) in romanNumerals) {
      while (n >= value) {
        buffer.write(numeral);
        n -= value;
      }
    }
    return buffer.toString();
  }

  /// Build task list using Checkbox
  Widget _buildTaskList(BuildContext context, TaskListBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: block.items.map((item) {
        final indent = item.level * 20.0;
        return Padding(
          padding: EdgeInsets.only(left: indent),
          child: _TaskItemWidget(item: item),
        );
      }).toList(),
    ).gap(6);
  }

  /// Build blockquote using Text().blockQuote
  Widget _buildQuote(BuildContext context, QuoteBlock block) {
    return Text(block.text).blockQuote();
  }

  /// Build image with optional caption and fullview on tap
  Widget _buildImage(BuildContext context, ImageBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _showImageFullView(context, block.url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: CachedNetworkImage(
                imageUrl: block.url,
                placeholder: (context, url) => Container(
                  height: 200,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.muted,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.muted,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Theme.of(context).colorScheme.mutedForeground,
                        ),
                        const SizedBox(height: 8),
                        Text('Failed to load image').muted(),
                      ],
                    ),
                  ),
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (block.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(block.caption).muted().small(),
          ),
      ],
    );
  }

  /// Show image in fullscreen with zoom capability
  void _showImageFullView(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => _ImageFullViewDialog(imageUrl: imageUrl),
    );
  }

  /// Build divider
  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Divider(),
    );
  }

  /// Build hint/alert using Alert widget with proper colors
  Widget _buildHint(BuildContext context, HintBlock block) {
    String title = '';
    String content = block.content;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Extract bold title if present
    final titleMatch = RegExp(r'^\*\*([^*]+)\*\*').firstMatch(content);
    if (titleMatch != null) {
      title = titleMatch.group(1) ?? '';
      content = content.substring(titleMatch.end).trim();
    }

    // Define colors and icons based on style - theme-aware
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (block.style) {
      case 'info':
        backgroundColor = isDark ? const Color(0xFF1A3A5C) : const Color(0xFFE3F2FD);
        iconColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
        icon = LucideIcons.info;
      case 'success':
        backgroundColor = isDark ? const Color(0xFF1B3D2F) : const Color(0xFFE8F5E9);
        iconColor = isDark ? const Color(0xFF81C784) : const Color(0xFF388E3C);
        icon = LucideIcons.circleCheck;
      case 'warning':
        backgroundColor = isDark ? const Color(0xFF3D3520) : const Color(0xFFFFF8E1);
        iconColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
        icon = LucideIcons.circleAlert;
      case 'danger':
        backgroundColor = isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFEBEE);
        iconColor = isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F);
        icon = LucideIcons.triangleAlert;
      default:
        backgroundColor = isDark ? const Color(0xFF1A3A5C) : const Color(0xFFE3F2FD);
        iconColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
        icon = LucideIcons.info;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                  ),
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: TextStyle(
                      color: theme.colorScheme.foreground,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build table using Material DataTable for stability
  Widget _buildTable(BuildContext context, TableBlock block) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.foreground;
    final borderColor = theme.colorScheme.border;

    // Filter out empty headers
    final headers = block.headers.where((h) => h.isNotEmpty).toList();

    if (headers.isEmpty && block.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            theme.colorScheme.muted.withValues(alpha: 0.3),
          ),
          columnSpacing: 16,
          horizontalMargin: 12,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 60,
          headingRowHeight: 48,
          dividerThickness: 1,
          columns: headers.isEmpty
              ? [DataColumn(label: Text('', style: TextStyle(color: textColor)))]
              : headers
                    .map(
                      (header) => DataColumn(
                        label: Text(
                          header,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          rows: block.rows.map((row) {
            // Ensure row has same number of cells as headers
            final paddedRow = List<String>.from(row);
            while (paddedRow.length < headers.length) {
              paddedRow.add('');
            }

            return DataRow(
              cells: paddedRow
                  .take(headers.length)
                  .map(
                    (cell) => DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: _containsInlineElements(cell)
                            ? _buildRichText(context, cell)
                            : Text(
                                cell,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textColor),
                              ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build cards using CardImage in horizontal scroll
  Widget _buildCards(BuildContext context, CardsBlock block) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: block.cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final card = block.cards[index];
          return SizedBox(
            width: 200,
            child: GestureDetector(
              onTap: card.url != null ? () => _launchUrl(card.url!) : null,
              child: Card(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: card.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) => Container(
                            height: 120,
                            color: Theme.of(context).colorScheme.muted,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ).semiBold(),
                            if (card.description.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    card.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ).muted().small(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build stepper using Steps with StepItem - fixed title parsing
  Widget _buildStepper(BuildContext context, StepperBlock block) {
    return Steps(
      children: block.steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;

        return StepItem(
          title: Text(step.title.isNotEmpty ? step.title : 'Step ${index + 1}'),
          content: step.content.isNotEmpty
              ? [_buildStepContent(context, step.content)]
              : [],
        );
      }).toList(),
    );
  }

  /// Build step content by parsing markdown
  Widget _buildStepContent(BuildContext context, String content) {
    final parser = MarkdownParser();
    final blocks = parser.parse(content);

    if (blocks.isEmpty) {
      return Text(content);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) => _buildBlock(context, block)).toList(),
    ).gap(12);
  }

  /// Build expandable using Accordion with AccordionItem
  Widget _buildExpandable(BuildContext context, ExpandableBlock block) {
    return Accordion(
      items: [
        AccordionItem(
          trigger: AccordionTrigger(child: Text(block.summary)),
          content: _buildExpandableContent(context, block.content),
        ),
      ],
    );
  }

  /// Build expandable content by parsing markdown
  Widget _buildExpandableContent(BuildContext context, String content) {
    final parser = MarkdownParser();
    final blocks = parser.parse(content);

    if (blocks.isEmpty) {
      return Text(content);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) => _buildBlock(context, block)).toList(),
    ).gap(12);
  }

  /// Build file download card
  Widget _buildFile(BuildContext context, FileBlock block) {
    return GestureDetector(
      onTap: () => _launchUrl(block.url),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.file,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).semiBold(),
                    if (block.caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          block.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).muted().small(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.download,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build content reference (page link) - now clickable
  Widget _buildContentRef(BuildContext context, ContentRefBlock block) {
    return GestureDetector(
      onTap: () => _launchUrl(block.url),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                LucideIcons.fileText,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  block.title.isNotEmpty
                      ? block.title
                      : _extractUrlName(block.url),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ).semiBold(),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extract readable name from URL
  String _extractUrlName(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        return Uri.decodeComponent(
          segments.last,
        ).replaceAll('-', ' ').replaceAll('_', ' ');
      }
    } catch (_) {}
    return url;
  }

  /// Build button - fixed secondary button visibility
  Widget _buildButton(BuildContext context, ButtonBlock block) {
    if (block.style == 'secondary') {
      return OutlineButton(
        onPressed: () => _launchUrl(block.url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(block.text),
            const SizedBox(width: 8),
            const Icon(LucideIcons.externalLink, size: 16),
          ],
        ),
      );
    }
    return PrimaryButton(
      onPressed: () => _launchUrl(block.url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(block.text),
          const SizedBox(width: 8),
          const Icon(LucideIcons.externalLink, size: 16),
        ],
      ),
    );
  }

  /// Build math/TeX block using flutter_math_fork
  Widget _buildMath(BuildContext context, MathBlock block) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.muted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Center(
        child: Math.tex(
          block.tex,
          textStyle: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.foreground,
          ),
          onErrorFallback: (error) {
            // Fallback to mono text if parsing fails
            return Text(block.tex).mono();
          },
        ),
      ),
    );
  }

  /// Build icon block - map gitbook icons to Lucide icons
  Widget _buildIcon(BuildContext context, IconBlock block) {
    final iconData = _mapGitbookIcon(block.name);
    return Icon(
      iconData,
      size: 24,
      color: Theme.of(context).colorScheme.foreground,
    );
  }

  /// Map gitbook icon names to Lucide icons
  IconData _mapGitbookIcon(String name) {
    switch (name.toLowerCase()) {
      case 'facebook':
        return LucideIcons.facebook;
      case 'github':
        return LucideIcons.github;
      case 'x-twitter':
      case 'twitter':
        return LucideIcons.twitter;
      case 'instagram':
        return LucideIcons.instagram;
      case 'linkedin':
        return LucideIcons.linkedin;
      case 'youtube':
        return LucideIcons.youtube;
      case 'discord':
        return LucideIcons.messageCircle;
      case 'slack':
        return LucideIcons.slack;
      default:
        return LucideIcons.link;
    }
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Check if text contains inline elements
  bool _containsInlineElements(String text) {
    return text.contains('[') ||
        text.contains('**') ||
        text.contains('*') ||
        text.contains('`') ||
        text.contains('<a ') ||
        text.contains('<strong>') ||
        text.contains('<em>') ||
        text.contains('<mark') ||
        text.contains('<span');
  }

  /// Parse inline formatting
  String _parseInlineFormatting(String text) {
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'\*([^*]+)\*'),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => match.group(1) ?? '',
    );
    text = text.replaceAll('&#x20;', ' ');
    text = text.replaceAll('\\[', '[');
    text = text.replaceAll('\\]', ']');

    return text.trim();
  }

  /// Build rich text with inline formatting support
  Widget _buildRichText(BuildContext context, String text) {
    final theme = Theme.of(context);
    final spans = <InlineSpan>[];

    final pattern = RegExp(
      r'(\*\*[^*]+\*\*)|'
      r'(\*[^*]+\*)|'
      r'(`[^`]+`)|'
      r'(\[[^\]]+\]\([^)]+\))|'
      r'(<a[^>]+>[^<]+</a>)|'
      r'(<span[^>]*>[^<]*</span>)|'
      r'(\[⤓\])|'
      r'([^*`\[\]<]+)',
    );

    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final fullMatch = match.group(0) ?? '';

      if (fullMatch.startsWith('**') && fullMatch.endsWith('**')) {
        final content = fullMatch.substring(2, fullMatch.length - 2);
        spans.add(
          TextSpan(
            text: content,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      } else if (fullMatch.startsWith('*') &&
          fullMatch.endsWith('*') &&
          !fullMatch.startsWith('**')) {
        final content = fullMatch.substring(1, fullMatch.length - 1);
        spans.add(
          TextSpan(
            text: content,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      } else if (fullMatch.startsWith('`') && fullMatch.endsWith('`')) {
        final content = fullMatch.substring(1, fullMatch.length - 1);
        spans.add(
          TextSpan(
            text: content,
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: theme.colorScheme.muted.withValues(alpha: 0.3),
            ),
          ),
        );
      } else if (fullMatch.startsWith('[') && fullMatch.contains('](')) {
        final linkMatch = RegExp(
          r'\[([^\]]+)\]\(([^)]+)\)',
        ).firstMatch(fullMatch);
        if (linkMatch != null) {
          final linkText = linkMatch.group(1) ?? '';
          final linkUrl = linkMatch.group(2) ?? '';
          spans.add(
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _launchUrl(linkUrl),
            ),
          );
        }
      } else if (fullMatch.startsWith('<a ')) {
        final hrefMatch = RegExp(r'href="([^"]+)"').firstMatch(fullMatch);
        final textMatch = RegExp(r'>([^<]+)</a>').firstMatch(fullMatch);
        if (hrefMatch != null && textMatch != null) {
          final linkUrl = hrefMatch.group(1) ?? '';
          final linkText = textMatch.group(1) ?? '';
          spans.add(
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => _launchUrl(linkUrl),
            ),
          );
        }
      } else if (fullMatch.startsWith('<span')) {
        final textMatch = RegExp(r'>([^<]*)</span>').firstMatch(fullMatch);
        final content = textMatch?.group(1) ?? '';
        spans.add(TextSpan(text: content));
      } else if (fullMatch == '[⤓]') {
        spans.add(
          TextSpan(
            text: '⬇ ',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        );
      } else {
        spans.add(TextSpan(text: fullMatch));
      }
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: theme.typography.sans.copyWith(
          color: theme.colorScheme.foreground,
        ),
      ),
    );
  }

  /// Launch URL in browser
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $url, error: $e');
    }
  }
}

// =============================================================================
// Stateful Widgets for Interactive Components
// =============================================================================

/// Code block widget with copy functionality
class _CodeBlockWidget extends StatefulWidget {
  final CodeBlock block;

  const _CodeBlockWidget({required this.block});

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  void _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.block.code));
    setState(() => _copied = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.block.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.block.title).semiBold().small(),
          ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with language and copy button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.block.language.isNotEmpty)
                      Text(widget.block.language).muted().small()
                    else
                      const SizedBox.shrink(),
                    GestureDetector(
                      onTap: _copyCode,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied ? LucideIcons.check : LucideIcons.copy,
                            size: 14,
                            color: _copied
                                ? const Color(0xFF388E3C)
                                : theme.colorScheme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(_copied ? 'Copied!' : 'Copy').muted().small(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Code content
              Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  widget.block.code,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: theme.colorScheme.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Task item widget with checkbox state
class _TaskItemWidget extends StatefulWidget {
  final TaskItemData item;

  const _TaskItemWidget({required this.item});

  @override
  State<_TaskItemWidget> createState() => _TaskItemWidgetState();
}

class _TaskItemWidgetState extends State<_TaskItemWidget> {
  late CheckboxState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.item.isChecked
        ? CheckboxState.checked
        : CheckboxState.unchecked;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          state: _state,
          onChanged: (value) {
            setState(() {
              _state = value;
            });
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.item.text,
            softWrap: true,
            style: TextStyle(
              decoration: _state == CheckboxState.checked
                  ? TextDecoration.lineThrough
                  : null,
              color: _state == CheckboxState.checked
                  ? Theme.of(context).colorScheme.mutedForeground
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tabs widget with state management and copy for code blocks
class _TabsWidget extends StatefulWidget {
  final List<TabData> tabs;

  const _TabsWidget({required this.tabs});

  @override
  State<_TabsWidget> createState() => _TabsWidgetState();
}

class _TabsWidgetState extends State<_TabsWidget> {
  int _index = 0;
  bool _copiedIndex = false;

  void _copyTabContent(String content) {
    // Extract just the code content if it's a code block
    final parser = MarkdownParser();
    final blocks = parser.parse(content);
    
    String textToCopy = content;
    if (blocks.isNotEmpty && blocks.first is CodeBlock) {
      textToCopy = (blocks.first as CodeBlock).code;
    }
    
    Clipboard.setData(ClipboardData(text: textToCopy));
    setState(() {
      _copiedIndex = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedIndex = false;
        });
      }
    });
  }

  bool _isCodeContent(String content) {
    final parser = MarkdownParser();
    final blocks = parser.parse(content);
    return blocks.isNotEmpty && blocks.first is CodeBlock;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentTab = widget.tabs[_index];
    final isCode = _isCodeContent(currentTab.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Tabs(
                index: _index,
                onChanged: (value) {
                  setState(() {
                    _index = value;
                    _copiedIndex = false;
                  });
                },
                children: widget.tabs.map((tab) {
                  return TabItem(child: Text(tab.title));
                }).toList(),
              ),
            ),
            if (isCode)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GhostButton(
                  density: ButtonDensity.icon,
                  onPressed: () => _copyTabContent(currentTab.content),
                  child: Icon(
                    _copiedIndex ? LucideIcons.check : LucideIcons.copy,
                    size: 16,
                    color: _copiedIndex 
                        ? const Color(0xFF22C55E)
                        : Theme.of(context).colorScheme.mutedForeground,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        IndexedStack(
          index: _index,
          sizing: StackFit.passthrough,
          children: widget.tabs.map((tab) {
            final parser = MarkdownParser();
            final blocks = parser.parse(tab.content);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: blocks.isEmpty
                    ? [Text(tab.content)]
                    : blocks.map((block) {
                        return _TabContentBuilder(block: block);
                      }).toList(),
              ).gap(8),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Helper widget to build tab content without nesting ListView
class _TabContentBuilder extends StatelessWidget {
  final ContentBlock block;

  const _TabContentBuilder({required this.block});

  @override
  Widget build(BuildContext context) {
    final renderer = MarkdownContentRenderer(blocks: const []);
    return renderer._buildBlock(context, block);
  }
}

/// Embed widget with proper handling for different URL types
class _EmbedWidget extends StatefulWidget {
  final EmbedBlock block;

  const _EmbedWidget({required this.block});

  @override
  State<_EmbedWidget> createState() => _EmbedWidgetState();
}

class _EmbedWidgetState extends State<_EmbedWidget> {
  bool _showWebView = false;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
        ),
      );
  }

  EmbedType _getEmbedType(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return EmbedType.youtube;
    } else if (url.contains('docs.google.com')) {
      return EmbedType.googleDocs;
    } else if (url.contains('sheets.google.com')) {
      return EmbedType.googleSheets;
    } else if (url.contains('slides.google.com')) {
      return EmbedType.googleSlides;
    } else if (url.contains('drive.google.com')) {
      return EmbedType.googleDrive;
    } else if (url.contains('codepen.io')) {
      return EmbedType.codepen;
    } else if (url.contains('spotify.com')) {
      return EmbedType.spotify;
    } else if (url.contains('notion.site') || url.contains('notion.so')) {
      return EmbedType.notion;
    } else if (url.contains('discord')) {
      return EmbedType.discord;
    }
    return EmbedType.other;
  }

  String? _getYouTubeThumbnail(String url) {
    String? videoId;

    if (url.contains('youtube.com/watch')) {
      final uri = Uri.parse(url);
      videoId = uri.queryParameters['v'];
    } else if (url.contains('youtu.be/')) {
      final segments = Uri.parse(url).pathSegments;
      if (segments.isNotEmpty) {
        videoId = segments.first;
      }
    } else if (url.contains('youtube.com/embed/')) {
      final segments = Uri.parse(url).pathSegments;
      final embedIndex = segments.indexOf('embed');
      if (embedIndex >= 0 && embedIndex < segments.length - 1) {
        videoId = segments[embedIndex + 1];
      }
    } else if (url.contains('youtube.com/playlist')) {
      // For playlists, return a generic thumbnail
      return null;
    }

    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $url, error: $e');
    }
  }

  void _openInAppBrowser() {
    setState(() {
      _showWebView = true;
      _webViewController.loadRequest(Uri.parse(widget.block.url));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView) {
      return _buildWebView(context);
    }

    final embedType = _getEmbedType(widget.block.url);

    switch (embedType) {
      case EmbedType.youtube:
        return _buildYouTubeEmbed(context);
      case EmbedType.googleDocs:
      case EmbedType.googleDrive:
      case EmbedType.googleSheets:
      case EmbedType.googleSlides:
        return _buildDocumentEmbed(context, embedType);
      case EmbedType.codepen:
      case EmbedType.spotify:
      case EmbedType.notion:
      case EmbedType.discord:
      case EmbedType.other:
        return _buildGenericEmbed(context, embedType);
    }
  }

  Widget _buildWebView(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.muted.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.block.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).muted().small(),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _launchUrl(widget.block.url),
                      child: Icon(
                        LucideIcons.externalLink,
                        size: 16,
                        color: Theme.of(context).colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _showWebView = false),
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Theme.of(context).colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(7),
              ),
              child: WebViewWidget(controller: _webViewController),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeEmbed(BuildContext context) {
    final thumbnail = _getYouTubeThumbnail(widget.block.url);
    final isPlaylist = widget.block.url.contains('playlist');

    return GestureDetector(
      onTap: () => _launchUrl(widget.block.url),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnail != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: thumbnail,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF282828),
                          child: const Center(
                            child: Icon(
                              LucideIcons.youtube,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF282828),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(7),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isPlaylist
                              ? LucideIcons.listVideo
                              : LucideIcons.youtube,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.play,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.youtube,
                    size: 20,
                    color: Color(0xFFFF0000),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.block.caption.isNotEmpty
                          ? widget.block.caption
                          : (isPlaylist ? 'YouTube Playlist' : 'YouTube Video'),
                    ).semiBold(),
                  ),
                  Icon(
                    LucideIcons.externalLink,
                    size: 16,
                    color: Theme.of(context).colorScheme.mutedForeground,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentEmbed(BuildContext context, EmbedType type) {
    IconData icon;
    Color iconColor;
    String label;

    switch (type) {
      case EmbedType.googleDocs:
        icon = LucideIcons.fileText;
        iconColor = const Color(0xFF4285F4); // Google Docs blue
        label = 'Google Document';
      case EmbedType.googleSheets:
        icon = LucideIcons.sheet;
        iconColor = const Color(0xFF34A853); // Google Sheets green
        label = 'Google Sheets';
      case EmbedType.googleSlides:
        icon = LucideIcons.presentation;
        iconColor = const Color(0xFFFBBC04); // Google Slides yellow
        label = 'Google Slides';
      case EmbedType.googleDrive:
        icon = LucideIcons.folderOpen;
        iconColor = const Color(0xFF34A853); // Google Drive green
        label = 'Google Drive';
      default:
        icon = LucideIcons.fileText;
        iconColor = const Color(0xFF4285F4);
        label = 'Document';
    }

    // Auto-load the webview for document embeds
    // Load URL on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_showWebView) {
        _openInAppBrowser();
      }
    });

    // Show loading state while webview initializes
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 210 / 150,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.muted.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: iconColor,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.block.caption.isNotEmpty
                        ? widget.block.caption
                        : label,
                  ).semiBold(),
                ),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericEmbed(BuildContext context, EmbedType type) {
    IconData icon;
    Color iconColor;
    String label;

    switch (type) {
      case EmbedType.codepen:
        icon = LucideIcons.code;
        iconColor = const Color(0xFF47CF73);
        label = 'CodePen';
      case EmbedType.spotify:
        icon = LucideIcons.music;
        iconColor = const Color(0xFF1DB954);
        label = 'Spotify';
      case EmbedType.notion:
        icon = LucideIcons.stickyNote;
        iconColor = Theme.of(context).colorScheme.foreground;
        label = 'Notion Page';
      case EmbedType.discord:
        icon = LucideIcons.messageCircle;
        iconColor = const Color(0xFF5865F2);
        label = 'Discord';
      default:
        icon = LucideIcons.link;
        iconColor = Theme.of(context).colorScheme.primary;
        label = 'External Link';
    }

    // Open in external browser for Discord, Notion, and other links
    return GestureDetector(
      onTap: () => _launchUrl(widget.block.url),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.block.caption.isNotEmpty
                          ? widget.block.caption
                          : label,
                    ).semiBold(),
                    const SizedBox(height: 4),
                    Text(
                      widget.block.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).muted().small(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                LucideIcons.externalLink,
                size: 20,
                color: Theme.of(context).colorScheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen image viewer with zoom capability
class _ImageFullViewDialog extends StatefulWidget {
  final String imageUrl;

  const _ImageFullViewDialog({required this.imageUrl});

  @override
  State<_ImageFullViewDialog> createState() => _ImageFullViewDialogState();
}

class _ImageFullViewDialogState extends State<_ImageFullViewDialog> {
  final TransformationController _transformationController =
      TransformationController();

  // Define colors that shadcn Colors doesn't have
  static const Color _white54 = Color(0x8AFFFFFF);
  static const Color _white70 = Color(0xB3FFFFFF);
  static const Color _black54 = Color(0x8A000000);

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen interactive image
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: _white54,
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  LucideIcons.x,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // Reset zoom button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: GestureDetector(
              onTap: _resetZoom,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  LucideIcons.maximize,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // Zoom hint
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.zoomIn,
                    color: _white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pinch to zoom',
                    style: TextStyle(
                      color: _white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum EmbedType {
  youtube,
  googleDocs,
  googleSheets,
  googleSlides,
  googleDrive,
  codepen,
  spotify,
  notion,
  discord,
  other,
}
