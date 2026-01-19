/// Markdown parser that handles Gitbook-specific syntax and converts to ContentBlocks
class MarkdownParser {
  /// Parse markdown content into a list of ContentBlocks
  List<ContentBlock> parse(String markdown) {
    final blocks = <ContentBlock>[];
    final lines = markdown.split('\n');
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) {
        i++;
        continue;
      }

      // Check for Gitbook-specific blocks first
      if (trimmedLine.startsWith('{% hint')) {
        final result = _parseHint(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      if (trimmedLine.startsWith('{% tabs %}')) {
        final result = _parseTabs(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      if (trimmedLine.startsWith('{% stepper %}')) {
        final result = _parseStepper(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      if (trimmedLine.startsWith('{% file')) {
        final result = _parseFile(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      if (trimmedLine.startsWith('{% embed')) {
        final result = _parseEmbed(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      if (trimmedLine.startsWith('{% code')) {
        final result = _parseCodeBlock(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      if (trimmedLine.startsWith('{% content-ref')) {
        final result = _parseContentRef(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Check for HTML expandable blocks
      if (trimmedLine.startsWith('<details>')) {
        final result = _parseExpandable(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Check for HTML figures/images
      if (trimmedLine.contains('<figure>') || trimmedLine.contains('<img')) {
        final result = _parseHtmlImage(lines, i);
        if (result != null) {
          blocks.add(result.block);
          i = result.nextIndex;
          continue;
        }
      }

      // Check for HTML tables
      if (trimmedLine.startsWith('<table')) {
        final result = _parseHtmlTable(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Check for HTML buttons
      if (trimmedLine.contains('<a') && trimmedLine.contains('class="button')) {
        final result = _parseButton(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Standard Markdown parsing

      // Headings
      if (trimmedLine.startsWith('#')) {
        final headingMatch = RegExp(
          r'^(#{1,6})\s+(.+)$',
        ).firstMatch(trimmedLine);
        if (headingMatch != null) {
          final level = headingMatch.group(1)!.length;
          final text = headingMatch.group(2)!;
          blocks.add(HeadingBlock(level: level, text: text));
          i++;
          continue;
        }
      }

      // Code blocks with triple backticks
      if (trimmedLine.startsWith('```')) {
        final result = _parseMarkdownCodeBlock(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Horizontal rule
      if (trimmedLine == '---' ||
          trimmedLine == '***' ||
          trimmedLine == '___') {
        blocks.add(const DividerBlock());
        i++;
        continue;
      }

      // Blockquote
      if (trimmedLine.startsWith('>')) {
        final result = _parseBlockquote(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Task list (check before unordered list)
      if (trimmedLine.startsWith('* [') || trimmedLine.startsWith('- [')) {
        final result = _parseTaskList(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Unordered list
      if (trimmedLine.startsWith('* ') ||
          trimmedLine.startsWith('- ') ||
          trimmedLine.startsWith('+ ')) {
        final result = _parseUnorderedList(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Ordered list
      if (RegExp(r'^\d+\.\s+').hasMatch(trimmedLine)) {
        final result = _parseOrderedList(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Math blocks
      if (trimmedLine.startsWith(r'$$')) {
        final result = _parseMathBlock(lines, i);
        blocks.add(result.block);
        i = result.nextIndex;
        continue;
      }

      // Default: paragraph
      final result = _parseParagraph(lines, i);
      blocks.add(result.block);
      i = result.nextIndex;
    }

    return blocks;
  }

  /// Parse a hint block: {% hint style="info" %} ... {% endhint %}
  _ParseResult _parseHint(List<String> lines, int start) {
    final openLine = lines[start].trim();
    final styleMatch = RegExp(r'style="(\w+)"').firstMatch(openLine);
    final style = styleMatch?.group(1) ?? 'info';

    final contentLines = <String>[];
    int i = start + 1;

    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.contains('{% endhint %}')) {
        break;
      }
      contentLines.add(lines[i]);
      i++;
    }

    return _ParseResult(
      block: HintBlock(style: style, content: contentLines.join('\n').trim()),
      nextIndex: i + 1,
    );
  }

  /// Parse a tabs block: {% tabs %} {% tab title="..." %} ... {% endtab %} {% endtabs %}
  _ParseResult _parseTabs(List<String> lines, int start) {
    final tabs = <TabData>[];
    int i = start + 1;

    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.contains('{% endtabs %}')) {
        break;
      }

      if (line.startsWith('{% tab title="')) {
        final titleMatch = RegExp(r'title="([^"]+)"').firstMatch(line);
        final title = titleMatch?.group(1) ?? 'Tab';

        final tabContentLines = <String>[];
        i++;

        while (i < lines.length) {
          final tabLine = lines[i].trim();
          if (tabLine.contains('{% endtab %}')) {
            break;
          }
          tabContentLines.add(lines[i]);
          i++;
        }

        tabs.add(
          TabData(title: title, content: tabContentLines.join('\n').trim()),
        );
      }

      i++;
    }

    return _ParseResult(
      block: TabsBlock(tabs: tabs),
      nextIndex: i + 1,
    );
  }

  /// Parse a stepper block: {% stepper %} {% step %} ... {% endstep %} {% endstepper %}
  _ParseResult _parseStepper(List<String> lines, int start) {
    final steps = <StepData>[];
    int i = start + 1;

    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.contains('{% endstepper %}')) {
        break;
      }

      if (line.contains('{% step %}')) {
        final stepContentLines = <String>[];
        i++;

        while (i < lines.length) {
          final stepLine = lines[i].trim();
          if (stepLine.contains('{% endstep %}')) {
            break;
          }
          stepContentLines.add(lines[i]);
          i++;
        }

        final stepContent = stepContentLines.join('\n').trim();
        // Extract title from ### or #### heading
        final titleMatch = RegExp(
          r'^#{1,4}\s+(.+)$',
          multiLine: true,
        ).firstMatch(stepContent);
        final title = titleMatch?.group(1)?.trim() ?? '';
        // Remove the heading from content
        final content = stepContent
            .replaceFirst(RegExp(r'^#{1,4}\s+.+\n?', multiLine: true), '')
            .trim();

        steps.add(StepData(title: title, content: content));
      }

      i++;
    }

    return _ParseResult(
      block: StepperBlock(steps: steps),
      nextIndex: i + 1,
    );
  }

  /// Parse a file block: {% file src="..." %}caption{% endfile %} or single-line {% file src="..." %}
  _ParseResult _parseFile(List<String> lines, int start) {
    final line = lines[start].trim();

    // Extract URL from src attribute
    final srcMatch = RegExp(r'src="<?([^">]+)>?"').firstMatch(line);
    final url = srcMatch?.group(1) ?? '';

    // Get caption from content between {% file %} and {% endfile %}
    String caption = '';
    int i = start;

    // Check if this is a single-line format (no content, just {% file src="..." %})
    // or if {% endfile %} is on the same line
    final hasSingleLineEnd = line.contains('{% endfile %}');
    final isSingleLineOnly = line.endsWith('%}') && !hasSingleLineEnd;

    if (hasSingleLineEnd) {
      // Format: {% file src="..." %}caption{% endfile %}
      final captionMatch = RegExp(
        r'%}\s*(.*?)\s*\{%\s*endfile',
      ).firstMatch(line);
      caption = captionMatch?.group(1)?.trim() ?? '';
      i = start + 1;
    } else if (isSingleLineOnly) {
      // Single line format: {% file src="..." %} with no endfile tag
      // Just move to next line
      i = start + 1;
    } else {
      // Multi-line format - look for {% endfile %}
      final contentLines = <String>[];
      i = start + 1;

      while (i < lines.length) {
        final currentLine = lines[i].trim();
        if (currentLine.contains('{% endfile %}')) {
          i++; // Move past the endfile line
          break;
        }
        // Don't absorb other gitbook blocks
        if (currentLine.startsWith('{%') && !currentLine.contains('endfile')) {
          break;
        }
        contentLines.add(lines[i]);
        i++;
      }
      caption = contentLines.join('\n').trim();
    }

    // Extract filename from URL
    // Gitbook file URLs format: .../uploads%2F<id>%2F<filename>?alt=media...
    // or: .../uploads/<id>/<filename>?alt=media...
    String filename = 'Document';
    try {
      // First, decode the URL to handle %2F encoding
      final decodedUrl = Uri.decodeComponent(url);
      final uri = Uri.parse(decodedUrl);
      
      // Try to extract filename from path (before query params)
      final path = uri.path;
      final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
      
      if (pathSegments.isNotEmpty) {
        // Get the last segment which should be the filename
        String lastSegment = pathSegments.last;
        
        // If the URL contains 'uploads', the filename is typically after it
        final uploadsIndex = pathSegments.indexWhere(
          (s) => s.contains('uploads'),
        );
        if (uploadsIndex >= 0 && uploadsIndex < pathSegments.length - 1) {
          // Take the last segment after 'uploads' - it should be the filename
          // Sometimes there's an ID between uploads and filename
          lastSegment = pathSegments.last;
        }
        
        // Clean up the filename
        filename = lastSegment;
        
        // Remove any query parameters that might be attached
        if (filename.contains('?')) {
          filename = filename.split('?').first;
        }
        
        // Final decode in case there's remaining encoding
        filename = Uri.decodeComponent(filename);
      }
    } catch (_) {
      // If parsing fails, try a simple regex extraction
      final filenameMatch = RegExp(r'([^/]+\.[a-zA-Z0-9]+)(?:\?|$)').firstMatch(url);
      if (filenameMatch != null) {
        filename = Uri.decodeComponent(filenameMatch.group(1) ?? 'Document');
      }
    }

    return _ParseResult(
      block: FileBlock(url: url, filename: filename, caption: caption),
      nextIndex: i,
    );
  }

  /// Parse an embed block: {% embed url="..." %}
  /// Embeds can be:
  /// 1. Single-line: {% embed url="..." %}
  /// 2. Multi-line with caption and closing tag:
  ///    {% embed url="..." %}
  ///    Caption text
  ///    {% endembed %}
  _ParseResult _parseEmbed(List<String> lines, int start) {
    final line = lines[start].trim();
    final urlMatch = RegExp(r'url="<?([^">]+)>?"').firstMatch(line);
    final url = urlMatch?.group(1) ?? '';

    // Check if the line also ends with %} - single line embed
    // Single line embeds: {% embed url="..." %}
    if (line.endsWith('%}') && !line.contains('endembed')) {
      // Check if next line is {% endembed %} or something else
      if (start + 1 < lines.length) {
        final nextLine = lines[start + 1].trim();
        if (nextLine == '{% endembed %}') {
          // Single embed with immediate close tag, no caption
          return _ParseResult(
            block: EmbedBlock(url: url, caption: ''),
            nextIndex: start + 2,
          );
        } else if (nextLine.isEmpty || 
                   nextLine.startsWith('#') || 
                   nextLine.startsWith('*') ||
                   nextLine.startsWith('-') ||
                   nextLine.startsWith('>') ||
                   nextLine.startsWith('{%') ||
                   nextLine.startsWith('<') ||
                   nextLine.startsWith('```') ||
                   nextLine.startsWith('1.') ||
                   nextLine.startsWith('|')) {
          // Next line is a new block, this is a single-line embed
          return _ParseResult(
            block: EmbedBlock(url: url, caption: ''),
            nextIndex: start + 1,
          );
        }
      } else {
        // Last line in file
        return _ParseResult(
          block: EmbedBlock(url: url, caption: ''),
          nextIndex: start + 1,
        );
      }
    }

    // Multi-line embed - look for caption and {% endembed %}
    String caption = '';
    int i = start + 1;
    bool foundEndEmbed = false;

    // Only look for endembed within a reasonable range (max 10 lines)
    final maxSearchLines = (start + 10 < lines.length) ? start + 10 : lines.length;
    
    while (i < maxSearchLines) {
      final currentLine = lines[i].trim();
      
      if (currentLine.contains('{% endembed %}')) {
        foundEndEmbed = true;
        break;
      }
      
      // If we hit another block marker, stop looking
      if (currentLine.startsWith('{%') && !currentLine.contains('endembed')) {
        break;
      }
      if (currentLine.startsWith('#') || 
          currentLine.startsWith('<table') ||
          currentLine.startsWith('<div') ||
          currentLine.startsWith('<details')) {
        break;
      }
      
      if (currentLine.isNotEmpty && !currentLine.startsWith('{%')) {
        caption = currentLine;
      }
      i++;
    }

    // If we found {% endembed %}, skip past it; otherwise just move past the embed line
    final nextIndex = foundEndEmbed ? i + 1 : start + 1;

    return _ParseResult(
      block: EmbedBlock(url: url, caption: caption),
      nextIndex: nextIndex,
    );
  }

  /// Parse a code block with title: {% code title="..." %}
  _ParseResult _parseCodeBlock(List<String> lines, int start) {
    final openLine = lines[start].trim();
    final titleMatch = RegExp(r'title="([^"]+)"').firstMatch(openLine);
    final title = titleMatch?.group(1) ?? '';

    final lineNumbersMatch = RegExp(
      r'lineNumbers="(true|false)"',
    ).firstMatch(openLine);
    final showLineNumbers = lineNumbersMatch?.group(1) == 'true';

    final codeLines = <String>[];
    String language = '';
    int i = start + 1;
    bool insideCode = false;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.contains('{% endcode %}')) {
        break;
      }

      if (trimmed.startsWith('```')) {
        if (!insideCode) {
          // Start of code block
          language = trimmed.substring(3).trim();
          insideCode = true;
        } else {
          // End of code block
          insideCode = false;
        }
        i++;
        continue;
      }

      if (insideCode) {
        codeLines.add(line);
      }

      i++;
    }

    return _ParseResult(
      block: CodeBlock(
        code: codeLines.join('\n'),
        language: language,
        title: title,
        showLineNumbers: showLineNumbers,
      ),
      nextIndex: i + 1,
    );
  }

  /// Parse a content reference block
  _ParseResult _parseContentRef(List<String> lines, int start) {
    final line = lines[start].trim();
    final urlMatch = RegExp(r'url="([^"]*)"').firstMatch(line);
    final url = urlMatch?.group(1) ?? '';

    String title = '';
    int i = start + 1;

    while (i < lines.length) {
      final currentLine = lines[i].trim();
      if (currentLine.contains('{% endcontent-ref %}')) {
        break;
      }
      // Extract link text from [text](url) pattern
      final linkMatch = RegExp(r'\[([^\]]*)\]').firstMatch(currentLine);
      if (linkMatch != null) {
        title = linkMatch.group(1) ?? url;
      }
      i++;
    }

    return _ParseResult(
      block: ContentRefBlock(url: url, title: title),
      nextIndex: i + 1,
    );
  }

  /// Parse an HTML expandable/details block
  _ParseResult _parseExpandable(List<String> lines, int start) {
    final contentLines = <String>[];
    String summary = '';
    int i = start + 1;

    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.contains('</details>')) {
        break;
      }

      // Extract summary
      if (line.contains('<summary>')) {
        final summaryMatch = RegExp(
          r'<summary>(.+?)</summary>',
        ).firstMatch(line);
        if (summaryMatch != null) {
          summary = summaryMatch.group(1) ?? '';
        } else {
          // Multi-line summary
          i++;
          while (i < lines.length && !lines[i].contains('</summary>')) {
            summary += lines[i].trim();
            i++;
          }
        }
        i++;
        continue;
      }

      if (line.isNotEmpty) {
        contentLines.add(lines[i]);
      }
      i++;
    }

    return _ParseResult(
      block: ExpandableBlock(
        summary: summary,
        content: contentLines.join('\n').trim(),
      ),
      nextIndex: i + 1,
    );
  }

  /// Parse HTML image/figure
  _ParseResult? _parseHtmlImage(List<String> lines, int start) {
    final line = lines[start];

    // Extract image URL
    final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(line);
    if (srcMatch == null) {
      return null;
    }

    final url = srcMatch.group(1)!.replaceAll('&#x26;', '&');

    // Extract alt text
    final altMatch = RegExp(r'alt="([^"]*)"').firstMatch(line);
    final alt = altMatch?.group(1) ?? '';

    // Extract caption
    String caption = '';
    int i = start;

    // Look for figcaption
    if (line.contains('<figcaption>')) {
      final captionMatch = RegExp(
        r'<figcaption>(?:<p>)?(.+?)(?:</p>)?</figcaption>',
      ).firstMatch(line);
      caption = captionMatch?.group(1) ?? '';
    } else {
      // Check next lines for caption
      i++;
      while (i < lines.length) {
        final currentLine = lines[i];
        if (currentLine.contains('</figure>')) {
          break;
        }
        if (currentLine.contains('<figcaption>')) {
          final captionMatch = RegExp(
            r'<figcaption>(?:<p>)?(.+?)(?:</p>)?</figcaption>',
          ).firstMatch(currentLine);
          caption = captionMatch?.group(1) ?? '';
        }
        i++;
      }
    }

    return _ParseResult(
      block: ImageBlock(url: url, alt: alt, caption: caption),
      nextIndex: i + 1,
    );
  }

  /// Parse HTML table
  _ParseResult _parseHtmlTable(List<String> lines, int start) {
    final tableLines = <String>[];
    int i = start;
    int depth = 0;

    // Collect all table content
    while (i < lines.length) {
      final line = lines[i];
      tableLines.add(line);

      if (line.contains('<table')) depth++;
      if (line.contains('</table>')) {
        depth--;
        if (depth <= 0) break;
      }
      i++;
    }

    final tableHtml = tableLines.join('\n');

    // Check if this is a cards view
    final isCards = tableHtml.contains('data-view="cards"');

    // Parse table structure
    final headers = <String>[];
    final hiddenColumnIndices = <int>{};
    final rows = <List<String>>[];
    final cardData = <CardData>[];

    // Extract headers and identify hidden columns
    final headerMatches = RegExp(
      r'<th([^>]*)>([^<]*)</th>',
    ).allMatches(tableHtml);
    int headerIndex = 0;
    for (final match in headerMatches) {
      final attributes = match.group(1) ?? '';
      final headerText = match.group(2)?.trim() ?? '';

      // Check if this column is hidden
      if (attributes.contains('data-hidden')) {
        hiddenColumnIndices.add(headerIndex);
      } else if (headerText.isNotEmpty) {
        headers.add(headerText);
      }
      headerIndex++;
    }

    // Extract rows
    final rowMatches = RegExp(
      r'<tr>(.+?)</tr>',
      dotAll: true,
    ).allMatches(tableHtml);
    for (final rowMatch in rowMatches) {
      final rowHtml = rowMatch.group(1) ?? '';

      // Skip header row
      if (rowHtml.contains('<th')) continue;

      final allCellValues = <String>[];
      final cellMatches = RegExp(
        r'<td[^>]*>(.*?)</td>',
        dotAll: true,
      ).allMatches(rowHtml);

      for (final cellMatch in cellMatches) {
        var cellContent = cellMatch.group(1) ?? '';
        // Clean up HTML
        cellContent = _stripHtmlTags(cellContent).trim();
        allCellValues.add(cellContent);
      }

      // Filter out hidden columns
      final cellValues = <String>[];
      for (int j = 0; j < allCellValues.length; j++) {
        if (!hiddenColumnIndices.contains(j)) {
          cellValues.add(allCellValues[j]);
        }
      }

      if (cellValues.isNotEmpty) {
        rows.add(cellValues);

        // For cards, extract card data
        if (isCards) {
          String title = cellValues.isNotEmpty ? cellValues[0] : '';
          String description = cellValues.length > 1 ? cellValues[1] : '';
          String? url;
          String? imageUrl;

          // Extract link
          final linkMatch = RegExp(
            r'<a[^>]*href="([^"]+)"',
          ).firstMatch(rowHtml);
          url = linkMatch?.group(1);

          // Extract image
          final imgMatch = RegExp(
            r'<a[^>]*href="(https?://[^"]+\.(png|jpg|jpeg|gif|webp)[^"]*)"',
          ).firstMatch(rowHtml);
          imageUrl = imgMatch?.group(1);

          cardData.add(
            CardData(
              title: title,
              description: description,
              url: url,
              imageUrl: imageUrl,
            ),
          );
        }
      }
    }

    if (isCards) {
      return _ParseResult(
        block: CardsBlock(cards: cardData),
        nextIndex: i + 1,
      );
    }

    return _ParseResult(
      block: TableBlock(headers: headers, rows: rows),
      nextIndex: i + 1,
    );
  }

  /// Parse HTML button
  _ParseResult _parseButton(List<String> lines, int start) {
    final line = lines[start];

    final hrefMatch = RegExp(r'href="([^"]+)"').firstMatch(line);
    final url = hrefMatch?.group(1) ?? '';

    final classMatch = RegExp(r'class="button\s+(\w+)"').firstMatch(line);
    final style = classMatch?.group(1) ?? 'primary';

    final textMatch = RegExp(r'>([^<]+)</a>').firstMatch(line);
    final text = textMatch?.group(1) ?? 'Button';

    return _ParseResult(
      block: ButtonBlock(text: text, url: url, style: style),
      nextIndex: start + 1,
    );
  }

  /// Parse standard markdown code block
  _ParseResult _parseMarkdownCodeBlock(List<String> lines, int start) {
    final firstLine = lines[start].trim();
    final language = firstLine.length > 3 ? firstLine.substring(3).trim() : '';

    final codeLines = <String>[];
    int i = start + 1;

    while (i < lines.length) {
      final line = lines[i];
      if (line.trim() == '```') {
        break;
      }
      codeLines.add(line);
      i++;
    }

    return _ParseResult(
      block: CodeBlock(
        code: codeLines.join('\n'),
        language: language,
        title: '',
        showLineNumbers: false,
      ),
      nextIndex: i + 1,
    );
  }

  /// Parse blockquote
  _ParseResult _parseBlockquote(List<String> lines, int start) {
    final quoteLines = <String>[];
    int i = start;

    while (i < lines.length) {
      final line = lines[i].trim();
      if (!line.startsWith('>')) {
        break;
      }
      // Remove > prefix and trim
      final content = line.substring(1).trim();
      if (content.isNotEmpty) {
        quoteLines.add(content);
      }
      i++;
    }

    return _ParseResult(
      block: QuoteBlock(text: quoteLines.join('\n')),
      nextIndex: i,
    );
  }

  /// Parse unordered list
  _ParseResult _parseUnorderedList(List<String> lines, int start) {
    final items = <ListItemData>[];
    int i = start;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Check for empty line (end of list)
      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // Check if still a list item
      if (!trimmed.startsWith('* ') &&
          !trimmed.startsWith('- ') &&
          !trimmed.startsWith('+ ') &&
          !line.startsWith('  ') &&
          !line.startsWith('\t')) {
        break;
      }

      // Check for task list item - break and let task list parser handle
      if (trimmed.startsWith('* [') || trimmed.startsWith('- [')) {
        break;
      }

      // Calculate indent level
      final leadingSpaces = line.length - line.trimLeft().length;
      final level = leadingSpaces ~/ 2;

      // Extract text (remove bullet point)
      final bulletMatch = RegExp(r'^[\*\-\+]\s+(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        final text = bulletMatch.group(1) ?? trimmed;
        items.add(ListItemData(text: text, level: level));
      }
      i++;
    }

    return _ParseResult(
      block: UnorderedListBlock(items: items),
      nextIndex: i,
    );
  }

  /// Parse ordered list
  _ParseResult _parseOrderedList(List<String> lines, int start) {
    final items = <ListItemData>[];
    int i = start;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Check for empty line
      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // Check if still a list item or continuation
      if (!RegExp(r'^\d+\.\s+').hasMatch(trimmed) &&
          !line.startsWith('   ') &&
          !line.startsWith('\t')) {
        break;
      }

      if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
        // Calculate indent level
        final leadingSpaces = line.length - line.trimLeft().length;
        final level = leadingSpaces ~/ 3;

        // Extract text (remove number prefix)
        final text = trimmed.replaceFirst(RegExp(r'^\d+\.\s+'), '');

        items.add(ListItemData(text: text, level: level));
      }
      i++;
    }

    return _ParseResult(
      block: OrderedListBlock(items: items),
      nextIndex: i,
    );
  }

  /// Parse task list
  _ParseResult _parseTaskList(List<String> lines, int start) {
    final items = <TaskItemData>[];
    int i = start;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Check for empty line
      if (trimmed.isEmpty) {
        i++;
        continue;
      }

      // Check if still a task list item
      if (!trimmed.startsWith('* [') &&
          !trimmed.startsWith('- [') &&
          !line.startsWith('  ') &&
          !line.startsWith('\t')) {
        break;
      }

      if (trimmed.startsWith('* [') || trimmed.startsWith('- [')) {
        // Check checkbox state
        final isChecked = trimmed.contains('[x]') || trimmed.contains('[X]');

        // Calculate indent level
        final leadingSpaces = line.length - line.trimLeft().length;
        final level = leadingSpaces ~/ 2;

        // Extract text
        final textMatch = RegExp(r'\[[xX ]?\]\s+(.+)$').firstMatch(trimmed);
        final text = textMatch?.group(1) ?? '';

        items.add(TaskItemData(text: text, isChecked: isChecked, level: level));
      }
      i++;
    }

    return _ParseResult(
      block: TaskListBlock(items: items),
      nextIndex: i,
    );
  }

  /// Parse math block
  _ParseResult _parseMathBlock(List<String> lines, int start) {
    final mathLines = <String>[];
    int i = start + 1;

    // Handle single-line $$...$$ or multi-line
    final firstLine = lines[start].trim();
    if (firstLine.length > 4 && firstLine.endsWith(r'$$')) {
      // Single line math
      return _ParseResult(
        block: MathBlock(
          tex: firstLine.substring(2, firstLine.length - 2).trim(),
        ),
        nextIndex: start + 1,
      );
    }

    while (i < lines.length) {
      final line = lines[i].trim();
      if (line == r'$$') {
        break;
      }
      mathLines.add(line);
      i++;
    }

    return _ParseResult(
      block: MathBlock(tex: mathLines.join('\n').trim()),
      nextIndex: i + 1,
    );
  }

  /// Parse paragraph (default)
  _ParseResult _parseParagraph(List<String> lines, int start) {
    final paragraphLines = <String>[];
    int i = start;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Break on empty line or special block start
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('```') ||
          trimmed.startsWith('---') ||
          trimmed.startsWith('***') ||
          trimmed.startsWith('___') ||
          trimmed.startsWith('>') ||
          trimmed.startsWith('* ') ||
          trimmed.startsWith('- ') ||
          trimmed.startsWith('+ ') ||
          trimmed.startsWith('* [') ||
          trimmed.startsWith('- [') ||
          RegExp(r'^\d+\.\s+').hasMatch(trimmed) ||
          trimmed.startsWith('{%') ||
          trimmed.startsWith('<table') ||
          trimmed.startsWith('<details') ||
          trimmed.startsWith('<figure') ||
          trimmed.startsWith(r'$$')) {
        break;
      }

      paragraphLines.add(trimmed);
      i++;
    }

    return _ParseResult(
      block: ParagraphBlock(text: paragraphLines.join(' ')),
      nextIndex: i,
    );
  }

  /// Strip HTML tags from string
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&#x26;', '&')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x20;', ' ');
  }
}

/// Parse result containing the block and next line index
class _ParseResult {
  final ContentBlock block;
  final int nextIndex;

  _ParseResult({required this.block, required this.nextIndex});
}

// ============================================================================
// Content Block Types
// ============================================================================

/// Base class for all content blocks
sealed class ContentBlock {
  const ContentBlock();
}

/// Heading block (h1-h6)
class HeadingBlock extends ContentBlock {
  final int level;
  final String text;

  const HeadingBlock({required this.level, required this.text});
}

/// Paragraph block
class ParagraphBlock extends ContentBlock {
  final String text;

  const ParagraphBlock({required this.text});
}

/// Unordered list block
class UnorderedListBlock extends ContentBlock {
  final List<ListItemData> items;

  const UnorderedListBlock({required this.items});
}

/// Ordered list block
class OrderedListBlock extends ContentBlock {
  final List<ListItemData> items;

  const OrderedListBlock({required this.items});
}

/// Task list block
class TaskListBlock extends ContentBlock {
  final List<TaskItemData> items;

  const TaskListBlock({required this.items});
}

/// Blockquote block
class QuoteBlock extends ContentBlock {
  final String text;

  const QuoteBlock({required this.text});
}

/// Code block
class CodeBlock extends ContentBlock {
  final String code;
  final String language;
  final String title;
  final bool showLineNumbers;

  const CodeBlock({
    required this.code,
    required this.language,
    this.title = '',
    this.showLineNumbers = false,
  });
}

/// Image block
class ImageBlock extends ContentBlock {
  final String url;
  final String alt;
  final String caption;

  const ImageBlock({required this.url, this.alt = '', this.caption = ''});
}

/// Divider/horizontal rule block
class DividerBlock extends ContentBlock {
  const DividerBlock();
}

/// Hint/callout block (info, warning, success, danger)
class HintBlock extends ContentBlock {
  final String style;
  final String content;

  const HintBlock({required this.style, required this.content});
}

/// Table block
class TableBlock extends ContentBlock {
  final List<String> headers;
  final List<List<String>> rows;

  const TableBlock({required this.headers, required this.rows});
}

/// Cards block (table with data-view="cards")
class CardsBlock extends ContentBlock {
  final List<CardData> cards;

  const CardsBlock({required this.cards});
}

/// Tabs block
class TabsBlock extends ContentBlock {
  final List<TabData> tabs;

  const TabsBlock({required this.tabs});
}

/// Stepper block
class StepperBlock extends ContentBlock {
  final List<StepData> steps;

  const StepperBlock({required this.steps});
}

/// Expandable/details block
class ExpandableBlock extends ContentBlock {
  final String summary;
  final String content;

  const ExpandableBlock({required this.summary, required this.content});
}

/// File download block
class FileBlock extends ContentBlock {
  final String url;
  final String filename;
  final String caption;

  const FileBlock({
    required this.url,
    required this.filename,
    this.caption = '',
  });
}

/// Embed block (YouTube, docs, etc.)
class EmbedBlock extends ContentBlock {
  final String url;
  final String caption;

  const EmbedBlock({required this.url, this.caption = ''});
}

/// Content reference/page link block
class ContentRefBlock extends ContentBlock {
  final String url;
  final String title;

  const ContentRefBlock({required this.url, required this.title});
}

/// Button block
class ButtonBlock extends ContentBlock {
  final String text;
  final String url;
  final String style;

  const ButtonBlock({
    required this.text,
    required this.url,
    this.style = 'primary',
  });
}

/// Math/TeX block
class MathBlock extends ContentBlock {
  final String tex;

  const MathBlock({required this.tex});
}

/// Icon block (for gitbook icons)
class IconBlock extends ContentBlock {
  final String name;

  const IconBlock({required this.name});
}

// ============================================================================
// Supporting Data Classes
// ============================================================================

/// List item data
class ListItemData {
  final String text;
  final int level;

  const ListItemData({required this.text, this.level = 0});
}

/// Task item data
class TaskItemData {
  final String text;
  final bool isChecked;
  final int level;

  const TaskItemData({
    required this.text,
    required this.isChecked,
    this.level = 0,
  });
}

/// Tab data
class TabData {
  final String title;
  final String content;

  const TabData({required this.title, required this.content});
}

/// Step data
class StepData {
  final String title;
  final String content;

  const StepData({required this.title, required this.content});
}

/// Card data
class CardData {
  final String title;
  final String description;
  final String? url;
  final String? imageUrl;

  const CardData({
    required this.title,
    this.description = '',
    this.url,
    this.imageUrl,
  });
}
