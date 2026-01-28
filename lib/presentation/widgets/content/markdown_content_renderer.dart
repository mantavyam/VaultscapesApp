import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import '../../../data/services/markdown_parser.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/pdf_cache_service.dart';

/// Callback for internal navigation to a subject
typedef SubjectNavigationCallback = void Function(String subjectCode);

/// Renders ContentBlocks as shadcn_flutter widgets
/// Following the gitbook-to-shadcn_flutter mapping recommendations
class MarkdownContentRenderer extends StatelessWidget {
  final List<ContentBlock> blocks;

  /// Optional callback for navigating to subjects internally.
  /// When provided, card URLs matching subject code patterns will trigger this
  /// callback instead of launching external URLs.
  final SubjectNavigationCallback? onNavigateToSubject;

  /// Set of known subject codes for internal navigation matching.
  /// If empty, all card URLs will be treated as external.
  final Set<String> knownSubjectCodes;

  const MarkdownContentRenderer({
    super.key,
    required this.blocks,
    this.onNavigateToSubject,
    this.knownSubjectCodes = const {},
  });

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

  /// Build paragraph using Text().p - handles inline button + text combinations
  Widget _buildParagraph(BuildContext context, ParagraphBlock block) {
    final text = block.text;

    // Check for inline button + text combination
    final buttonMatch = RegExp(
      r'<a[^>]*href="([^"]*)"[^>]*class="button[^"]*"[^>]*data-icon="([^"]*)"[^>]*></a>\s*\[([^\]]+)\]\(([^)]+)\)',
    ).firstMatch(text);

    if (buttonMatch != null) {
      final buttonUrl = buttonMatch.group(1) ?? '';
      final iconName = buttonMatch.group(2) ?? '';
      final linkText = buttonMatch.group(3) ?? '';
      final linkUrl = buttonMatch.group(4) ?? '';

      IconData iconData;
      switch (iconName) {
        case 'arrow-down-to-square':
        case 'download':
          iconData = LucideIcons.download;
          break;
        default:
          iconData = LucideIcons.download;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            size: ButtonSize.small,
            onPressed: () => _launchUrl(buttonUrl),
            child: Icon(iconData, size: 16),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _launchUrl(linkUrl),
            child: Text(
              linkText,
              style: const TextStyle(
                color: Color(0xFF1976D2),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      );
    }

    if (_containsInlineElements(text)) {
      return _buildRichText(context, text);
    }
    return Text(_parseInlineFormatting(text)).p();
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
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
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

  /// Build hint/alert using Alert widget with proper colors and markdown support
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
        backgroundColor = isDark
            ? const Color(0xFF1A3A5C)
            : const Color(0xFFE3F2FD);
        iconColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
        icon = LucideIcons.info;
      case 'success':
        backgroundColor = isDark
            ? const Color(0xFF1B3D2F)
            : const Color(0xFFE8F5E9);
        iconColor = isDark ? const Color(0xFF81C784) : const Color(0xFF388E3C);
        icon = LucideIcons.circleCheck;
      case 'warning':
        backgroundColor = isDark
            ? const Color(0xFF3D3520)
            : const Color(0xFFFFF8E1);
        iconColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFF57C00);
        icon = LucideIcons.circleAlert;
      case 'danger':
        backgroundColor = isDark
            ? const Color(0xFF3D1F1F)
            : const Color(0xFFFFEBEE);
        iconColor = isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F);
        icon = LucideIcons.triangleAlert;
      default:
        backgroundColor = isDark
            ? const Color(0xFF1A3A5C)
            : const Color(0xFFE3F2FD);
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
                if (content.isNotEmpty) _buildHintContent(context, content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build hint content with markdown formatting support
  Widget _buildHintContent(BuildContext context, String content) {
    // Check if content has markdown formatting
    if (_containsInlineElements(content)) {
      return _buildRichText(context, content);
    }
    return Text(
      content,
      style: TextStyle(color: Theme.of(context).colorScheme.foreground),
    );
  }

  /// Build modern table with clean design
  /// Supports: buttons, links, markdown formatting (bold, italic), lists
  Widget _buildTable(BuildContext context, TableBlock block) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.foreground;
    final borderColor = theme.colorScheme.border;
    final headerBgColor = theme.colorScheme.muted.withValues(alpha: 0.15);
    final alternateBgColor = theme.colorScheme.muted.withValues(alpha: 0.05);

    // Filter out empty headers
    final headers = block.headers.where((h) => h.isNotEmpty).toList();

    if (headers.isEmpty && block.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate column count
    final columnCount = headers.isNotEmpty
        ? headers.length
        : (block.rows.isNotEmpty ? block.rows.first.length : 1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          if (headers.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: headerBgColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: headers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final header = entry.value;
                    final isLast = index == headers.length - 1;

                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  right: BorderSide(
                                    color: borderColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(
                          header,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Data rows
          ...block.rows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;
            final isAlternate = rowIndex.isOdd;
            final isLast = rowIndex == block.rows.length - 1;

            // Pad row to match column count
            final paddedRow = List<String>.from(row);
            while (paddedRow.length < columnCount) {
              paddedRow.add('');
            }

            return Container(
              decoration: BoxDecoration(
                color: isAlternate ? alternateBgColor : Colors.transparent,
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: borderColor.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: paddedRow
                      .take(columnCount)
                      .toList()
                      .asMap()
                      .entries
                      .map((cellEntry) {
                        final cellIndex = cellEntry.key;
                        final cell = cellEntry.value;
                        final isLastCell = cellIndex == columnCount - 1;

                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: isLastCell
                                  ? null
                                  : Border(
                                      right: BorderSide(
                                        color: borderColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _buildTableCell(context, cell, textColor),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            );
          }),
        ],
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

          // Determine if this card should navigate internally
          final bool isInternalNavigation = _shouldNavigateInternally(card.url);

          return SizedBox(
            width: 200,
            child: GestureDetector(
              onTap: card.url != null
                  ? () {
                      if (isInternalNavigation && onNavigateToSubject != null) {
                        // Extract the subject code from the URL (could be path like "mat301" or "cse302/cse322")
                        final subjectCode = _extractSubjectCodeFromUrl(
                          card.url!,
                        );
                        if (subjectCode != null) {
                          onNavigateToSubject!(subjectCode);
                        }
                      } else {
                        _launchUrl(card.url!);
                      }
                    }
                  : null,
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
          trigger: AccordionTrigger(
            child: _buildAccordionSummary(context, block.summary),
          ),
          content: _buildExpandableContent(context, block.content),
        ),
      ],
    );
  }

  /// Build accordion summary with link support and rich formatting
  Widget _buildAccordionSummary(BuildContext context, String summary) {
    // Handle newlines in summary
    summary = summary.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      ' ',
    );

    // Check if summary contains an anchor link
    final linkMatch = RegExp(
      r'<a\s+href="([^"]+)"[^>]*>([^<]+)</a>',
      dotAll: true,
    ).firstMatch(summary);

    if (linkMatch != null) {
      final url = linkMatch.group(1) ?? '';
      final linkText = linkMatch.group(2) ?? '';
      // Get text before and after the link
      final beforeLink = summary.substring(0, linkMatch.start);
      final afterLink = summary.substring(linkMatch.end);

      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (beforeLink.trim().isNotEmpty) Text(beforeLink.trim()).bold(),
          GestureDetector(
            onTap: () => _launchUrl(url),
            child: Text(
              linkText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF1976D2),
              ),
            ),
          ),
          if (afterLink.trim().isNotEmpty) Text(afterLink.trim()).bold(),
        ],
      );
    }

    // Check for markdown-style links
    final mdLinkMatch = RegExp(r'\[([^\]]+)\]\(([^)]+)\)').firstMatch(summary);
    if (mdLinkMatch != null) {
      final linkText = mdLinkMatch.group(1) ?? '';
      final url = mdLinkMatch.group(2) ?? '';
      final beforeLink = summary.substring(0, mdLinkMatch.start);
      final afterLink = summary.substring(mdLinkMatch.end);

      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (beforeLink.trim().isNotEmpty) Text(beforeLink.trim()).bold(),
          GestureDetector(
            onTap: () => _launchUrl(url),
            child: Text(
              linkText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF1976D2),
              ),
            ),
          ),
          if (afterLink.trim().isNotEmpty) Text(afterLink.trim()).bold(),
        ],
      );
    }

    // No link, return bold text
    return Text(summary).bold();
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

  /// Build button - handles inline button with optional accompanying text
  Widget _buildButton(BuildContext context, ButtonBlock block) {
    Widget buttonWidget;

    if (block.style == 'secondary') {
      buttonWidget = OutlineButton(
        onPressed: () => _launchUrl(block.url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (block.text.isNotEmpty && block.text != 'Button') ...[
              Text(block.text),
              const SizedBox(width: 8),
            ],
            const Icon(LucideIcons.download, size: 16),
          ],
        ),
      );
    } else {
      buttonWidget = PrimaryButton(
        onPressed: () => _launchUrl(block.url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (block.text.isNotEmpty && block.text != 'Button') ...[
              Text(block.text),
              const SizedBox(width: 8),
            ],
            const Icon(LucideIcons.download, size: 16),
          ],
        ),
      );
    }

    return buttonWidget;
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

  /// Build table cell content - handles buttons, links, lists, newlines, HTML tags and text
  Widget _buildTableCell(BuildContext context, String cell, Color textColor) {
    const linkColor = Color(0xFF2563EB); // Modern blue

    // Preprocess HTML tags - convert <br> to newlines, extract <p> content
    String processedCell = cell;

    // Handle <br> and <br/> tags - convert to newlines
    processedCell = processedCell.replaceAll(
      RegExp(r'<br\s*/?>', caseSensitive: false),
      '\n',
    );

    // Handle <p>...</p> tags - extract content and add newlines
    processedCell = processedCell.replaceAllMapped(
      RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true),
      (match) => '${match.group(1) ?? ''}\n',
    );

    // Clean up multiple consecutive newlines
    processedCell = processedCell.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    processedCell = processedCell.trim();

    // Empty cell after processing
    if (processedCell.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check for button-style anchor with data-icon attribute
    final buttonWithIconMatch = RegExp(
      r'<a[^>]*href="([^"]*)"[^>]*class="button\s*(\w*)"[^>]*data-icon="([^"]*)"[^>]*>.*?</a>',
      dotAll: true,
    ).firstMatch(processedCell);

    if (buttonWithIconMatch != null) {
      final url = buttonWithIconMatch.group(1) ?? '';
      final style = buttonWithIconMatch.group(2) ?? 'primary';
      final iconName = buttonWithIconMatch.group(3) ?? '';
      return _buildTableButtonCell(context, url, style, iconName);
    }

    // Check for alternate attribute order (class before href)
    final buttonAltMatch = RegExp(
      r'<a[^>]*class="button\s*(\w*)"[^>]*href="([^"]*)"[^>]*data-icon="([^"]*)"[^>]*>.*?</a>',
      dotAll: true,
    ).firstMatch(processedCell);

    if (buttonAltMatch != null) {
      final style = buttonAltMatch.group(1) ?? 'primary';
      final url = buttonAltMatch.group(2) ?? '';
      final iconName = buttonAltMatch.group(3) ?? '';
      return _buildTableButtonCell(context, url, style, iconName);
    }

    // Check for list items (markdown or plain)
    if (_containsListItems(processedCell)) {
      return _buildTableCellList(context, processedCell, textColor, linkColor);
    }

    // Check for multiple links (list of links)
    final allLinks = RegExp(
      r'<a[^>]*href="([^"]*)"[^>]*>([^<]+)</a>',
      dotAll: true,
    ).allMatches(processedCell).toList();

    if (allLinks.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: allLinks.asMap().entries.map((entry) {
          final linkMatch = entry.value;
          final url = linkMatch.group(1) ?? '';
          final linkText = linkMatch.group(2) ?? '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildTableLink(linkText, url, linkColor),
          );
        }).toList(),
      );
    }

    // Check for single link anchor
    if (allLinks.length == 1) {
      final url = allLinks.first.group(1) ?? '';
      final linkText = allLinks.first.group(2) ?? '';
      return _buildTableLink(linkText, url, linkColor);
    }

    // Handle cells with newlines (including those from <br> tags)
    if (processedCell.contains('\n')) {
      final lines = processedCell
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lines.asMap().entries.map((entry) {
          final line = entry.value;
          final isLast = entry.key == lines.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
            child: _containsInlineElements(line)
                ? _buildRichText(context, line)
                : Text(
                    line.trim(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
          );
        }).toList(),
      );
    }

    // Regular text or inline elements
    if (_containsInlineElements(processedCell)) {
      return _buildRichText(context, processedCell);
    }

    return Text(
      processedCell,
      style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
    );
  }

  /// Check if cell contains list items
  bool _containsListItems(String cell) {
    return cell.contains(RegExp(r'^\s*[\*\-\+]\s+', multiLine: true)) ||
        cell.contains(RegExp(r'^\s*\d+\.\s+', multiLine: true));
  }

  /// Build list content within a table cell
  Widget _buildTableCellList(
    BuildContext context,
    String cell,
    Color textColor,
    Color linkColor,
  ) {
    final lines = cell.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Check for unordered list item
      final unorderedMatch = RegExp(
        r'^(\s*)([\*\-\+])\s+(.+)$',
      ).firstMatch(line);
      if (unorderedMatch != null) {
        final indent = unorderedMatch.group(1)?.length ?? 0;
        final content = unorderedMatch.group(3) ?? '';
        final level = indent ~/ 2;

        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: level * 12.0, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: _containsInlineElements(content)
                      ? _buildRichText(context, content)
                      : Text(
                          content,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Check for ordered list item
      final orderedMatch = RegExp(r'^(\s*)(\d+)\.\s+(.+)$').firstMatch(line);
      if (orderedMatch != null) {
        final indent = orderedMatch.group(1)?.length ?? 0;
        final number = orderedMatch.group(2) ?? '1';
        final content = orderedMatch.group(3) ?? '';
        final level = indent ~/ 2;

        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: level * 12.0, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '$number.',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: _containsInlineElements(content)
                      ? _buildRichText(context, content)
                      : Text(
                          content,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular line (not a list item)
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _containsInlineElements(line)
              ? _buildRichText(context, line)
              : Text(
                  line.trim(),
                  style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Build a styled link for table cells
  Widget _buildTableLink(String text, String url, Color linkColor) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: linkColor,
                fontSize: 13,
                height: 1.4,
                decoration: TextDecoration.underline,
                decorationColor: linkColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.externalLink,
            size: 12,
            color: linkColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  /// Build a button widget for table cells - uses fixed size for consistency
  Widget _buildTableButtonCell(
    BuildContext context,
    String url,
    String style,
    String iconName,
  ) {
    IconData iconData;
    switch (iconName) {
      case 'arrow-down-to-square':
      case 'download':
        iconData = LucideIcons.download;
        break;
      case 'external-link':
        iconData = LucideIcons.externalLink;
        break;
      case 'eye':
        iconData = LucideIcons.eye;
        break;
      case 'link':
        iconData = LucideIcons.link;
        break;
      case 'arrow-right':
        iconData = LucideIcons.arrowRight;
        break;
      default:
        // For any other icon or empty, use external link / web icon
        iconData = LucideIcons.externalLink;
    }

    // Fixed button size (44x44) per iOS/Android recommended tap target guidelines
    // The button should not expand to fill the cell
    if (style == 'secondary') {
      return SizedBox(
        width: 44,
        height: 44,
        child: OutlineButton(
          size: ButtonSize.small,
          onPressed: () => _launchUrl(url),
          child: Icon(iconData, size: 18),
        ),
      );
    }

    return SizedBox(
      width: 44,
      height: 44,
      child: PrimaryButton(
        size: ButtonSize.small,
        onPressed: () => _launchUrl(url),
        child: Icon(iconData, size: 18),
      ),
    );
  }

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

    // Define link color - always blue for external hyperlink feel
    const linkColor = Color(0xFF1976D2);

    final pattern = RegExp(
      r'(\*\*[^*]+\*\*)|'
      r'(\*[^*]+\*)|'
      r'(`[^`]+`)|'
      r'(\[[^\]]+\]\([^)]+\))|'
      r'(<a[^>]+>[^<]+</a>)|'
      r'(<span[^>]*>[^<]*</span>)|'
      r'(\[⤓\])|'
      r'(\[▶\])|'
      r'(⤓)|'
      r'(▶)|'
      r'([^*`\[\]<⤓▶]+)',
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
          var linkText = linkMatch.group(1) ?? '';
          final linkUrl = linkMatch.group(2) ?? '';

          // Check if link text contains bold formatting **text**
          final isBold = linkText.startsWith('**') && linkText.endsWith('**');
          if (isBold) {
            // Remove bold markers
            linkText = linkText.substring(2, linkText.length - 2);
          }

          // Check if link text contains italic formatting *text*
          final isItalic =
              linkText.startsWith('*') &&
              linkText.endsWith('*') &&
              !linkText.startsWith('**');
          if (isItalic) {
            // Remove italic markers
            linkText = linkText.substring(1, linkText.length - 1);
          }

          spans.add(
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: linkColor,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
                fontWeight: isBold ? FontWeight.bold : null,
                fontStyle: isItalic ? FontStyle.italic : null,
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
              style: const TextStyle(
                color: linkColor,
                decoration: TextDecoration.underline,
                decorationColor: linkColor,
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
      } else if (fullMatch == '[⤓]' || fullMatch == '⤓') {
        // Downwards Arrow to Bar - display as actual character
        spans.add(TextSpan(text: '[⤓]'));
      } else if (fullMatch == '[▶]' || fullMatch == '▶') {
        // Black Right-Pointing Triangle - display as actual character
        spans.add(TextSpan(text: '[▶]'));
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
      // Sanitize URL - remove leading/trailing brackets and whitespace
      url = _sanitizeUrl(url);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $url, error: $e');
    }
  }

  /// Check if a URL should navigate internally to a subject page.
  /// Returns true if the URL is a relative path that matches a known subject code.
  bool _shouldNavigateInternally(String? url) {
    if (url == null || url.isEmpty) return false;

    // Skip if it's an absolute URL (http://, https://, etc.)
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return false;
    }

    // Extract the subject code from the path
    final subjectCode = _extractSubjectCodeFromUrl(url);
    if (subjectCode == null) return false;

    // Check if it matches a known subject code
    return knownSubjectCodes.any(
      (code) => code.toLowerCase() == subjectCode.toLowerCase(),
    );
  }

  /// Extract the subject code from a URL path.
  /// Handles paths like "mat301", "cse302/cse322", "specialisation/csc301"
  /// Returns the last segment of the path in uppercase.
  String? _extractSubjectCodeFromUrl(String url) {
    if (url.isEmpty) return null;

    // Remove any leading/trailing slashes
    url = url.replaceAll(RegExp(r'^/+|/+$'), '');

    // Get the last segment of the path
    final segments = url.split('/');
    final lastSegment = segments.last;

    // Check if it looks like a subject code (alphanumeric, 3-10 chars)
    if (RegExp(r'^[a-zA-Z0-9]{3,10}$').hasMatch(lastSegment)) {
      return lastSegment.toUpperCase();
    }

    return null;
  }

  /// Sanitize URL by removing invalid characters
  String _sanitizeUrl(String url) {
    // Remove leading brackets, whitespace
    url = url.replaceAll(RegExp(r'^[\[\s]+'), '');
    // Remove trailing brackets, whitespace
    url = url.replaceAll(RegExp(r'[\]\s]+$'), '');
    // Handle URLs wrapped in angle brackets
    if (url.startsWith('<') && url.endsWith('>')) {
      url = url.substring(1, url.length - 1);
    }
    return url.trim();
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
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.tabs.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _index = index;
                          _copiedIndex = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.border,
                          ),
                        ),
                        child: Text(
                          widget.tabs[index].title,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.foreground,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  },
                ),
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
  bool _showInDialog = false;
  bool _isOffline = false;
  bool _hasWebViewError = false;
  bool _isLoading = true;
  String _webViewErrorMessage = '';
  late WebViewController _webViewController;
  final ConnectivityService _connectivityService = ConnectivityService();

  // PDF-specific state
  bool _showDocumentDialog = false;
  bool _isPdfLoading = false;
  bool _hasPdfError = false;
  String _pdfErrorMessage = '';
  PdfControllerPinch? _pdfController;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkConnectivityAndAutoLoad();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true) // Enable pinch-to-zoom
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _hasWebViewError = false;
                _webViewErrorMessage = '';
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _hasWebViewError = true;
                _webViewErrorMessage = error.description;
                _isLoading = false;
              });
            }
          },
        ),
      );
  }

  Future<void> _checkConnectivityAndAutoLoad() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!mounted) return;

    setState(() {
      _isOffline = !isConnected;
    });

    // Documents now show a simple card by default, no auto-load needed
    // The user taps the card to open the document in dialog view
  }

  /// Transform URL to interactive/preview URL for better gesture support
  String _getInteractiveUrl(String url) {
    // For Google Drive file URLs, transform to preview URL
    if (url.contains('drive.google.com') && url.contains('/file/d/')) {
      // Extract file ID and create preview URL
      final fileId = _extractGoogleDriveFileId(url);
      if (fileId != null) {
        return 'https://drive.google.com/file/d/$fileId/preview';
      }
    }
    // For other Google URLs, they usually work well as-is
    return url;
  }

  /// Extract Google Drive file ID from URL
  String? _extractGoogleDriveFileId(String url) {
    try {
      // Pattern: /file/d/FILE_ID/...
      final regex = RegExp(r'/file/d/([^/]+)');
      final match = regex.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    } catch (e) {
      debugPrint('Error extracting Google Drive file ID: $e');
    }
    return null;
  }

  /// Check if URL is a Google Drive PDF
  bool _isGoogleDrivePdf(String url) {
    return url.contains('drive.google.com') && url.contains('/file/d/');
  }

  /// Check if URL is a direct PDF URL (Internet Archive, Gitbook, or any .pdf URL)
  bool _isDirectPdfUrl(String url) {
    // Internet Archive PDF URLs
    if (url.contains('archive.org') && url.endsWith('.pdf')) {
      return true;
    }
    // Gitbook file URLs with PDF
    if (url.contains('gitbook.io') && url.contains('.pdf')) {
      return true;
    }
    // Any direct .pdf URL (ends with .pdf or has .pdf before query params)
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final path = uri.path.toLowerCase();
      if (path.endsWith('.pdf')) {
        return true;
      }
    }
    return false;
  }

  /// Open document in dialog view (default for documents)
  Future<void> _openDocumentDialog() async {
    await _checkConnectivity();
    if (_isOffline) return;

    final url = _sanitizedUrl;

    // For direct PDF URLs (Internet Archive, Gitbook, etc.), use modal bottom sheet PDF viewer
    if (_isDirectPdfUrl(url)) {
      if (!mounted) return;

      // Show modal bottom sheet covering 85% of screen
      material.showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        enableDrag: false, // Disable drag to prevent conflict with PDF gestures
        backgroundColor: material.Colors.transparent,
        builder: (context) => _PdfBottomSheetViewer(
          url: url,
          title: widget.block.caption.isNotEmpty
              ? widget.block.caption
              : 'PDF Document',
        ),
      );
      return;
    }
    // For Google Drive PDFs, redirect to external browser (API complexity)
    else if (_isGoogleDrivePdf(url)) {
      _launchUrl(url);
      return;
    } else {
      // For other documents (Docs, Sheets, Slides), use WebView dialog
      final interactiveUrl = _getInteractiveUrl(url);
      setState(() {
        _showDocumentDialog = true;
        _showWebView = true;
        _isLoading = true;
      });
      _webViewController.loadRequest(Uri.parse(interactiveUrl));
    }
  }

  /// Load PDF from direct URL (Internet Archive, Gitbook, etc.)
  Future<void> _loadPdfFromDirectUrl(String url) async {
    try {
      debugPrint('Loading PDF from direct URL: $url');

      // Download PDF bytes with progress tracking
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      // Add user agent to avoid some servers blocking requests
      request.headers['User-Agent'] =
          'Mozilla/5.0 (compatible; Vaultscapes/1.0)';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];
      int received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() {
            _downloadProgress = received / contentLength;
          });
        }
      }

      client.close();

      if (!mounted) return;

      debugPrint('Downloaded ${bytes.length} bytes, creating PDF controller');

      // Create PDF controller with Future<PdfDocument>
      setState(() {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openData(Uint8List.fromList(bytes)),
        );
        _isPdfLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading PDF from direct URL: $e');
      if (mounted) {
        setState(() {
          _hasPdfError = true;
          _pdfErrorMessage = e.toString();
          _isPdfLoading = false;
        });
      }
    }
  }

  /// Close document dialog and reset state
  void _closeDocumentDialog() {
    setState(() {
      _showDocumentDialog = false;
      _showWebView = false;
      _showInDialog = false;
      _isPdfLoading = false;
      _hasPdfError = false;
      _pdfErrorMessage = '';
    });
    _pdfController?.dispose();
    _pdfController = null;
  }

  Future<void> _checkConnectivity() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = !isConnected;
      });
    }
  }

  EmbedType _getEmbedType(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      // Check if it's a channel link
      if (url.contains('/@') ||
          url.contains('/channel/') ||
          url.contains('/c/') ||
          url.contains('/user/')) {
        return EmbedType.youtubeChannel;
      }
      // Check if it's a playlist
      if (url.contains('playlist?') || url.contains('&list=')) {
        return EmbedType.youtubePlaylist;
      }
      return EmbedType.youtube;
    } else if (url.contains('docs.google.com')) {
      return EmbedType.googleDocs;
    } else if (url.contains('sheets.google.com')) {
      return EmbedType.googleSheets;
    } else if (url.contains('slides.google.com')) {
      return EmbedType.googleSlides;
    } else if (url.contains('drive.google.com')) {
      return EmbedType.googleDrive;
    } else if (_isDirectPdfUrl(url)) {
      return EmbedType.directPdf;
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
    // Sanitize the URL first
    url = _sanitizeUrl(url);

    try {
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
        // For playlists, try to extract playlist ID and get a thumbnail
        final uri = Uri.parse(url);
        final listId = uri.queryParameters['list'];
        if (listId != null && listId.length >= 11) {
          // Use YouTube's playlist thumbnail API
          return 'https://i.ytimg.com/vi/${listId.substring(0, 11)}/hqdefault.jpg';
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error parsing YouTube URL: $url, error: $e');
      return null;
    }

    if (videoId != null) {
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return null;
  }

  /// Extract YouTube channel name from URL
  String _getYouTubeChannelName(String url) {
    // Handle @username format
    final atMatch = RegExp(r'/@([^/]+)').firstMatch(url);
    if (atMatch != null) {
      return '@${atMatch.group(1)}';
    }
    // Handle /channel/ format
    final channelMatch = RegExp(r'/channel/([^/]+)').firstMatch(url);
    if (channelMatch != null) {
      return channelMatch.group(1) ?? 'Channel';
    }
    // Handle /c/ format
    final cMatch = RegExp(r'/c/([^/]+)').firstMatch(url);
    if (cMatch != null) {
      return cMatch.group(1) ?? 'Channel';
    }
    // Handle /user/ format
    final userMatch = RegExp(r'/user/([^/]+)').firstMatch(url);
    if (userMatch != null) {
      return userMatch.group(1) ?? 'Channel';
    }
    return 'YouTube Channel';
  }

  Future<void> _launchUrl(String url) async {
    try {
      // Sanitize URL - remove leading/trailing brackets and whitespace
      url = _sanitizeUrl(url);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $url, error: $e');
    }
  }

  /// Sanitize URL by removing invalid characters
  String _sanitizeUrl(String url) {
    // Remove leading brackets, whitespace
    url = url.replaceAll(RegExp(r'^[\[\s]+'), '');
    // Remove trailing brackets, whitespace
    url = url.replaceAll(RegExp(r'[\]\s]+$'), '');
    // Handle URLs wrapped in angle brackets
    if (url.startsWith('<') && url.endsWith('>')) {
      url = url.substring(1, url.length - 1);
    }
    return url.trim();
  }

  void _openInAppBrowser() async {
    // Check connectivity before loading
    await _checkConnectivity();
    if (_isOffline) {
      return; // Don't try to load if offline
    }
    final url = _getInteractiveUrl(_sanitizedUrl);
    setState(() {
      _showWebView = true;
      _isLoading = true;
    });
    _webViewController.loadRequest(Uri.parse(url));
  }

  void _closeDialog() {
    setState(() {
      _showInDialog = false;
      _showWebView = false;
    });
  }

  /// Get the sanitized URL from the block
  String get _sanitizedUrl => _sanitizeUrl(widget.block.url);

  /// Build offline error widget
  Widget _buildOfflineError(
    BuildContext context, {
    IconData? icon,
    Color? iconColor,
    String? label,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.border),
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.wifiOff,
            size: 48,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 16),
          Text(
            'No Internet Connection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to load ${label ?? 'content'}. Please check your connection and try again.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlineButton(
                onPressed: () async {
                  await _checkConnectivity();
                  if (!_isOffline) {
                    _openInAppBrowser();
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 14),
                    SizedBox(width: 8),
                    Text('Retry'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlineButton(
                onPressed: () => _launchUrl(_sanitizedUrl),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.externalLink, size: 14),
                    SizedBox(width: 8),
                    Text('Open in Browser'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build webview error widget (for in-webview errors)
  Widget _buildWebViewError(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.destructive.withValues(alpha: 0.3),
        ),
        color: theme.colorScheme.destructive.withValues(alpha: 0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 48,
            color: theme.colorScheme.destructive,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Content',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _webViewErrorMessage.isNotEmpty
                ? _webViewErrorMessage
                : 'An error occurred while loading the content.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlineButton(
                onPressed: () {
                  setState(() {
                    _hasWebViewError = false;
                    _showWebView = false;
                  });
                  _openInAppBrowser();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 14),
                    SizedBox(width: 8),
                    Text('Retry'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlineButton(
                onPressed: () => _launchUrl(_sanitizedUrl),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.externalLink, size: 14),
                    SizedBox(width: 8),
                    Text('Open in Browser'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show document dialog (PDF or WebView) if requested
    if (_showDocumentDialog) {
      final embedType = _getEmbedType(_sanitizedUrl);
      return _buildDocumentDialogView(context, embedType);
    }

    // Show dialog if requested (legacy WebView dialog)
    if (_showInDialog && _showWebView) {
      return _buildDialogWebView(context);
    }

    if (_showWebView) {
      // Show webview error if there's an error
      if (_hasWebViewError) {
        return _buildWebViewError(context);
      }
      return _buildWebView(context);
    }

    final embedType = _getEmbedType(_sanitizedUrl);

    switch (embedType) {
      case EmbedType.youtube:
        return _buildYouTubeEmbed(context);
      case EmbedType.youtubeChannel:
        return _buildYouTubeChannelEmbed(context);
      case EmbedType.youtubePlaylist:
        return _buildYouTubePlaylistEmbed(context);
      case EmbedType.googleDocs:
      case EmbedType.googleDrive:
      case EmbedType.googleSheets:
      case EmbedType.googleSlides:
      case EmbedType.directPdf:
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
                    _sanitizedUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).muted().small(),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _launchUrl(_sanitizedUrl),
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

  /// Build dialog-style webview for documents
  Widget _buildDialogWebView(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _closeDialog, // Dismiss on tap outside
      child: Container(
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping the dialog
            child: Container(
              width: screenSize.width * 0.9,
              height: screenSize.height * 0.8,
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with close button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.block.caption.isNotEmpty
                                ? widget.block.caption
                                : 'Document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // Open in browser button
                            GestureDetector(
                              onTap: () => _launchUrl(_sanitizedUrl),
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: Icon(
                                  LucideIcons.externalLink,
                                  size: 18,
                                  color: theme.colorScheme.mutedForeground,
                                ),
                              ),
                            ),
                            // Close button with 44x44 tap target
                            GestureDetector(
                              onTap: _closeDialog,
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                child: Icon(
                                  LucideIcons.x,
                                  size: 20,
                                  color: theme.colorScheme.foreground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // WebView content
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      child: _hasWebViewError
                          ? _buildWebViewError(context)
                          : WebViewWidget(controller: _webViewController),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubeEmbed(BuildContext context) {
    final url = _sanitizedUrl;
    final thumbnail = _getYouTubeThumbnail(url);
    final isPlaylist = url.contains('playlist');

    return GestureDetector(
      onTap: () => _launchUrl(url),
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

  /// Build YouTube channel embed - smaller card-like appearance
  Widget _buildYouTubeChannelEmbed(BuildContext context) {
    final url = _sanitizedUrl;
    final channelName = _getYouTubeChannelName(url);

    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.youtube,
                  size: 28,
                  color: Color(0xFFFF0000),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.block.caption.isNotEmpty
                          ? widget.block.caption
                          : channelName,
                    ).semiBold(),
                    const SizedBox(height: 4),
                    Text(
                      'YouTube Channel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
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

  /// Build YouTube playlist embed - try thumbnail first, fallback to small card
  Widget _buildYouTubePlaylistEmbed(BuildContext context) {
    final url = _sanitizedUrl;
    final thumbnail = _getYouTubePlaylistThumbnail(url);
    final playlistTitle = _getPlaylistTitle(url);

    // If we have a thumbnail, show the large card style
    if (thumbnail != null) {
      return GestureDetector(
        onTap: () => _launchUrl(url),
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
                              LucideIcons.listVideo,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Playlist indicator overlay
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.listVideo,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'PLAYLIST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                      LucideIcons.listVideo,
                      size: 20,
                      color: Color(0xFFFF0000),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.block.caption.isNotEmpty
                            ? widget.block.caption
                            : playlistTitle,
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

    // Fallback: Show small card style (like channel embed)
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.listVideo,
                  size: 28,
                  color: Color(0xFFFF0000),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.block.caption.isNotEmpty
                          ? widget.block.caption
                          : playlistTitle,
                    ).semiBold(),
                    const SizedBox(height: 4),
                    Text(
                      'YouTube Playlist',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
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

  /// Get YouTube playlist thumbnail - uses the first video's thumbnail
  String? _getYouTubePlaylistThumbnail(String url) {
    try {
      url = _sanitizeUrl(url);
      final uri = Uri.parse(url);
      final listId = uri.queryParameters['list'];

      if (listId != null && listId.isNotEmpty) {
        // YouTube doesn't provide a direct playlist thumbnail API
        // We return null to trigger the small card fallback
        // The large card will only show if the thumbnail actually loads
        return 'https://i.ytimg.com/vi/$listId/hqdefault.jpg';
      }
    } catch (e) {
      debugPrint('Error parsing playlist URL: $url, error: $e');
    }
    return null;
  }

  /// Extract playlist title from URL or return default
  String _getPlaylistTitle(String url) {
    // Try to get a meaningful name from the URL
    try {
      final uri = Uri.parse(_sanitizeUrl(url));
      final listId = uri.queryParameters['list'];
      if (listId != null) {
        return 'YouTube Playlist';
      }
    } catch (_) {}
    return 'YouTube Playlist';
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
      case EmbedType.directPdf:
        icon = LucideIcons.fileText;
        iconColor = const Color(0xFFE53935); // PDF red
        label = 'PDF Document';
      default:
        icon = LucideIcons.fileText;
        iconColor = const Color(0xFF4285F4);
        label = 'Document';
    }

    // Show offline error if not connected
    if (_isOffline) {
      return _buildOfflineError(
        context,
        icon: icon,
        iconColor: iconColor,
        label: label,
      );
    }

    final theme = Theme.of(context);

    // For Google Drive files (PDFs), show external link card only (no dialog)
    final isGoogleDrivePdf = _isGoogleDrivePdf(_sanitizedUrl);
    if (isGoogleDrivePdf) {
      return _buildExternalLinkCard(
        context,
        icon: icon,
        iconColor: iconColor,
        label: 'Google Drive PDF',
        subtitle: 'Open in Google Drive',
      );
    }

    // Simple "Open Document" card - tapping opens dialog view
    return GestureDetector(
      onTap: _openDocumentDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.border),
          color: theme.colorScheme.muted.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                        : 'Open Document',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Open in browser button
            GestureDetector(
              onTap: () => _launchUrl(_sanitizedUrl),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.externalLink,
                  size: 18,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
            // Open in dialog button
            Icon(
              LucideIcons.maximize2,
              size: 18,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  /// Build external link card for Google Drive PDFs (external only, no dialog)
  Widget _buildExternalLinkCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _launchUrl(_sanitizedUrl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.border),
          color: theme.colorScheme.muted.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.externalLink, size: 20, color: iconColor),
          ],
        ),
      ),
    );
  }

  /// Build document dialog view - full screen PDF or WebView
  Widget _buildDocumentDialogView(BuildContext context, EmbedType type) {
    IconData icon;
    Color iconColor;
    String label;

    switch (type) {
      case EmbedType.googleDocs:
        icon = LucideIcons.fileText;
        iconColor = const Color(0xFF4285F4);
        label = 'Google Document';
      case EmbedType.googleSheets:
        icon = LucideIcons.sheet;
        iconColor = const Color(0xFF34A853);
        label = 'Google Sheets';
      case EmbedType.googleSlides:
        icon = LucideIcons.presentation;
        iconColor = const Color(0xFFFBBC04);
        label = 'Google Slides';
      case EmbedType.googleDrive:
        icon = LucideIcons.folderOpen;
        iconColor = const Color(0xFF34A853);
        label = 'Google Drive';
      case EmbedType.directPdf:
        icon = LucideIcons.fileText;
        iconColor = const Color(0xFFE53935);
        label = 'PDF Document';
      default:
        icon = LucideIcons.fileText;
        iconColor = const Color(0xFF4285F4);
        label = 'Document';
    }

    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isPdf =
        _isGoogleDrivePdf(_sanitizedUrl) || _isDirectPdfUrl(_sanitizedUrl);

    return GestureDetector(
      onTap: _closeDocumentDialog, // Dismiss on tap outside
      child: Container(
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping the dialog
            child: Container(
              width: screenSize.width * 0.95,
              height: screenSize.height * 0.85,
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with close button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: iconColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.block.caption.isNotEmpty
                                ? widget.block.caption
                                : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                        ),
                        // Open in browser button
                        GestureDetector(
                          onTap: () => _launchUrl(_sanitizedUrl),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.externalLink,
                              size: 18,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                        ),
                        // Close button
                        GestureDetector(
                          onTap: _closeDocumentDialog,
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.x,
                              size: 20,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content area
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      child: isPdf
                          ? _buildPdfContent(context, icon, iconColor)
                          : _buildWebViewContent(context, icon, iconColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build PDF content for dialog
  Widget _buildPdfContent(
    BuildContext context,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    // Show loading state
    if (_isPdfLoading) {
      return Container(
        color: theme.colorScheme.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 16),
              if (_downloadProgress > 0 && _downloadProgress < 1)
                Column(
                  children: [
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: theme.colorScheme.muted,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Downloading... ${(_downloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading PDF...',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_hasPdfError) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: theme.colorScheme.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.triangleAlert,
                size: 48,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load PDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _pdfErrorMessage.isNotEmpty
                    ? _pdfErrorMessage
                    : 'An error occurred while loading the PDF.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlineButton(
                    onPressed: () {
                      setState(() {
                        _hasPdfError = false;
                        _isPdfLoading = true;
                        _downloadProgress = 0.0;
                      });
                      // Retry with direct PDF URL loader
                      _loadPdfFromDirectUrl(_sanitizedUrl);
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.refreshCw, size: 14),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlineButton(
                    onPressed: () => _launchUrl(_sanitizedUrl),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.externalLink, size: 14),
                        SizedBox(width: 8),
                        Text('Open in Browser'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Show PDF viewer with proper gesture handling
    if (_pdfController != null) {
      return GestureDetector(
        // Prevent parent scroll from capturing gestures
        onVerticalDragStart: (_) {},
        onVerticalDragUpdate: (_) {},
        onVerticalDragEnd: (_) {},
        onHorizontalDragStart: (_) {},
        onHorizontalDragUpdate: (_) {},
        onHorizontalDragEnd: (_) {},
        child: PdfViewPinch(
          controller: _pdfController!,
          builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(),
            documentLoaderBuilder: (_) =>
                Center(child: CircularProgressIndicator(color: iconColor)),
            pageLoaderBuilder: (_) =>
                Center(child: CircularProgressIndicator(color: iconColor)),
            errorBuilder: (_, error) => Center(
              child: Text(
                error.toString(),
                style: TextStyle(color: theme.colorScheme.destructive),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Build WebView content for dialog (for Docs, Sheets, Slides)
  Widget _buildWebViewContent(
    BuildContext context,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: theme.colorScheme.background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48, color: iconColor),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Loading document...',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
    final url = _sanitizedUrl;
    return GestureDetector(
      onTap: () => _launchUrl(url),
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
                      url,
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
  final material.TransformationController _transformationController =
      material.TransformationController();

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
    _transformationController.value = material.Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return material.Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen interactive image
          material.InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(Icons.broken_image, size: 64, color: _white54),
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
                child: const Icon(LucideIcons.x, color: Colors.white, size: 24),
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
                  Icon(LucideIcons.zoomIn, color: _white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Pinch to zoom',
                    style: TextStyle(color: _white70, fontSize: 12),
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
  youtubeChannel,
  youtubePlaylist,
  googleDocs,
  googleSheets,
  googleSlides,
  googleDrive,
  directPdf, // Direct PDF URLs (Internet Archive, Gitbook, etc.)
  codepen,
  spotify,
  notion,
  discord,
  other,
}

/// Modal bottom sheet PDF viewer covering 85% of screen
/// Uses pdfx PdfViewPinch with caching support via flutter_cache_manager
class _PdfBottomSheetViewer extends StatefulWidget {
  final String url;
  final String title;

  const _PdfBottomSheetViewer({required this.url, required this.title});

  @override
  State<_PdfBottomSheetViewer> createState() => _PdfBottomSheetViewerState();
}

class _PdfBottomSheetViewerState extends State<_PdfBottomSheetViewer> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _downloadProgress = 0.0;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      debugPrint('Loading PDF from: ${widget.url}');

      // Check if already cached
      _isCached = await PdfCacheService.instance.isCached(widget.url);
      debugPrint('PDF cached: $_isCached');

      // Download PDF with progress tracking using cache service
      final bytes = await PdfCacheService.instance.downloadPdfWithProgress(
        widget.url,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      debugPrint('Downloaded ${bytes.length} bytes, creating PDF controller');

      // Create PDF controller with initial page
      final controller = PdfControllerPinch(
        document: PdfDocument.openData(bytes),
        initialPage: 1,
      );

      setState(() {
        _pdfController = controller;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF1a1a1a)
        : const Color(0xFFF5F5F5);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85, // 85% of screen height
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle indicator (visual only, drag is disabled)
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with close button, title, and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2d2d2d) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.x,
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 24,
                    ),
                  ),
                ),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (_isCached && !_isLoading)
                        Text(
                          'Cached',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.green.shade300
                                : Colors.green.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Page indicator
                if (_totalPages > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.54),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Open in browser button
                GestureDetector(
                  onTap: () => _launchUrl(widget.url),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.externalLink,
                      color: isDarkMode ? Colors.white : Colors.black,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // PDF content area
          Expanded(child: _buildContent(context, theme, backgroundColor)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    Color backgroundColor,
  ) {
    // Loading state
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.fileText,
              size: 64,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 24),
            if (_downloadProgress > 0 && _downloadProgress < 1)
              Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: material.LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: theme.colorScheme.muted,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFE53935),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isCached ? 'Loading from cache...' : 'Connecting...',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    // Error state
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.triangleAlert,
                size: 64,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load PDF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlineButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                        _downloadProgress = 0.0;
                      });
                      _loadPdf();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.refreshCw, size: 16),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlineButton(
                    onPressed: () => _launchUrl(widget.url),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.externalLink, size: 16),
                        SizedBox(width: 8),
                        Text('Open in Browser'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // PDF viewer - full control to pdfx for gestures
    if (_pdfController != null) {
      return Container(
        color: backgroundColor,
        child: PdfViewPinch(
          controller: _pdfController!,
          scrollDirection: Axis.vertical,
          padding: 8,
          onDocumentLoaded: (document) {
            if (mounted) {
              setState(() {
                _totalPages = document.pagesCount;
              });
            }
          },
          onPageChanged: (page) {
            if (mounted) {
              setState(() {
                _currentPage = page;
              });
            }
          },
          builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(),
            documentLoaderBuilder: (_) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: const Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rendering PDF...',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            pageLoaderBuilder: (_) => Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFFE53935),
                ),
              ),
            ),
            errorBuilder: (_, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 48,
                      color: theme.colorScheme.destructive,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error rendering page',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
