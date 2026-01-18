import 'package:markdown/markdown.dart' as md;

/// Parser that converts raw markdown text into structured content blocks
/// for rendering with shadcn_flutter widgets
class MarkdownParser {
  /// Parse markdown text into a list of content blocks
  List<ContentBlock> parse(String markdown) {
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    
    final lines = markdown.split('\n');
    final nodes = document.parseLines(lines);
    
    final blocks = <ContentBlock>[];
    _parseNodes(nodes, blocks);
    
    return blocks;
  }
  
  void _parseNodes(List<md.Node> nodes, List<ContentBlock> blocks) {
    for (final node in nodes) {
      if (node is md.Element) {
        _parseElement(node, blocks);
      } else if (node is md.Text) {
        final text = node.textContent.trim();
        if (text.isNotEmpty) {
          blocks.add(ParagraphBlock(text: text));
        }
      }
    }
  }
  
  void _parseElement(md.Element element, List<ContentBlock> blocks) {
    switch (element.tag) {
      case 'h1':
        blocks.add(HeadingBlock(
          level: 1,
          text: _extractText(element),
        ));
        break;
        
      case 'h2':
        blocks.add(HeadingBlock(
          level: 2,
          text: _extractText(element),
        ));
        break;
        
      case 'h3':
        blocks.add(HeadingBlock(
          level: 3,
          text: _extractText(element),
        ));
        break;
        
      case 'h4':
      case 'h5':
      case 'h6':
        blocks.add(HeadingBlock(
          level: 4,
          text: _extractText(element),
        ));
        break;
        
      case 'p':
        final text = _extractText(element);
        if (text.isNotEmpty) {
          // Check if it's a special Gitbook hint block
          if (_isHintStart(text)) {
            // Parse hint block
            blocks.add(_parseHint(text, element));
          } else {
            blocks.add(ParagraphBlock(text: text));
          }
        }
        break;
        
      case 'ul':
        blocks.add(UnorderedListBlock(
          items: _extractListItems(element),
        ));
        break;
        
      case 'ol':
        blocks.add(OrderedListBlock(
          items: _extractListItems(element),
        ));
        break;
        
      case 'blockquote':
        blocks.add(QuoteBlock(
          text: _extractText(element),
        ));
        break;
        
      case 'pre':
        final codeElement = element.children?.firstWhere(
          (e) => e is md.Element && e.tag == 'code',
          orElse: () => element,
        );
        
        String? language;
        if (codeElement is md.Element) {
          final className = codeElement.attributes['class'];
          if (className != null && className.startsWith('language-')) {
            language = className.substring('language-'.length);
          }
        }
        
        blocks.add(CodeBlock(
          code: _extractText(element),
          language: language,
        ));
        break;
        
      case 'code':
        // Inline code - wrap in paragraph
        blocks.add(InlineCodeBlock(code: _extractText(element)));
        break;
        
      case 'hr':
        blocks.add(DividerBlock());
        break;
        
      case 'img':
        final src = element.attributes['src'] ?? '';
        final alt = element.attributes['alt'];
        blocks.add(ImageBlock(
          url: src,
          alt: alt,
        ));
        break;
        
      case 'a':
        final href = element.attributes['href'] ?? '';
        final text = _extractText(element);
        blocks.add(LinkBlock(
          url: href,
          text: text,
        ));
        break;
        
      case 'table':
        final table = _parseTable(element);
        if (table != null) blocks.add(table);
        break;
        
      case 'input':
        // Task list checkbox
        final isChecked = element.attributes['checked'] != null;
        blocks.add(TaskItemBlock(
          text: '',
          isChecked: isChecked,
        ));
        break;
        
      default:
        // For unknown elements, try to extract text content
        if (element.children != null) {
          _parseNodes(element.children!, blocks);
        }
    }
  }
  
  String _extractText(md.Element element) {
    final buffer = StringBuffer();
    _extractTextRecursive(element, buffer);
    return buffer.toString().trim();
  }
  
  void _extractTextRecursive(md.Node node, StringBuffer buffer) {
    if (node is md.Text) {
      buffer.write(node.textContent);
    } else if (node is md.Element) {
      // Handle inline formatting
      if (node.tag == 'strong' || node.tag == 'b') {
        buffer.write('**');
      } else if (node.tag == 'em' || node.tag == 'i') {
        buffer.write('*');
      } else if (node.tag == 'code') {
        buffer.write('`');
      }
      
      if (node.children != null) {
        for (final child in node.children!) {
          _extractTextRecursive(child, buffer);
        }
      }
      
      if (node.tag == 'strong' || node.tag == 'b') {
        buffer.write('**');
      } else if (node.tag == 'em' || node.tag == 'i') {
        buffer.write('*');
      } else if (node.tag == 'code') {
        buffer.write('`');
      }
      
      if (node.tag == 'br') {
        buffer.write('\n');
      }
    }
  }
  
  List<ListItemData> _extractListItems(md.Element element) {
    final items = <ListItemData>[];
    
    if (element.children != null) {
      for (final child in element.children!) {
        if (child is md.Element && child.tag == 'li') {
          final text = _extractText(child);
          final isTaskItem = child.children?.any(
            (c) => c is md.Element && c.tag == 'input',
          ) ?? false;
          
          bool? isChecked;
          if (isTaskItem) {
            final inputEl = child.children?.whereType<md.Element>().firstWhere(
              (e) => e.tag == 'input',
              orElse: () => md.Element.empty('input'),
            );
            isChecked = inputEl?.attributes['checked'] != null;
          }
          
          // Check for nested lists
          final nestedList = child.children?.whereType<md.Element>().where(
            (e) => e.tag == 'ul' || e.tag == 'ol',
          ).firstOrNull;
          
          List<ListItemData>? nested;
          if (nestedList != null) {
            nested = _extractListItems(nestedList);
          }
          
          items.add(ListItemData(
            text: text,
            isChecked: isChecked,
            nestedItems: nested,
          ));
        }
      }
    }
    
    return items;
  }
  
  bool _isHintStart(String text) {
    return text.contains('{% hint') || 
           text.contains('{%hint');
  }
  
  ContentBlock _parseHint(String text, md.Element element) {
    // Parse Gitbook hint style
    // {% hint style="info" %} content {% endhint %}
    String style = 'info';
    String content = text;
    
    final styleMatch = RegExp(r'style="(\w+)"').firstMatch(text);
    if (styleMatch != null) {
      style = styleMatch.group(1) ?? 'info';
    }
    
    // Remove hint markers
    content = content
        .replaceAll(RegExp(r'\{%\s*hint[^%]*%\}'), '')
        .replaceAll(RegExp(r'\{%\s*endhint\s*%\}'), '')
        .trim();
    
    return HintBlock(
      style: HintStyle.values.firstWhere(
        (s) => s.name == style,
        orElse: () => HintStyle.info,
      ),
      content: content,
    );
  }
  
  TableBlock? _parseTable(md.Element element) {
    final headers = <String>[];
    final rows = <List<String>>[];
    
    if (element.children == null) return null;
    
    for (final child in element.children!) {
      if (child is md.Element) {
        if (child.tag == 'thead') {
          // Parse header row
          final headerRow = child.children?.whereType<md.Element>().firstOrNull;
          if (headerRow != null) {
            for (final th in headerRow.children?.whereType<md.Element>() ?? <md.Element>[]) {
              if (th.tag == 'th') {
                headers.add(_extractText(th));
              }
            }
          }
        } else if (child.tag == 'tbody') {
          // Parse body rows
          for (final tr in child.children?.whereType<md.Element>() ?? <md.Element>[]) {
            if (tr.tag == 'tr') {
              final row = <String>[];
              for (final td in tr.children?.whereType<md.Element>() ?? <md.Element>[]) {
                if (td.tag == 'td') {
                  row.add(_extractText(td));
                }
              }
              if (row.isNotEmpty) rows.add(row);
            }
          }
        }
      }
    }
    
    if (headers.isEmpty && rows.isEmpty) return null;
    
    return TableBlock(
      headers: headers,
      rows: rows,
    );
  }
}

// Content Block Types
abstract class ContentBlock {
  const ContentBlock();
}

class HeadingBlock extends ContentBlock {
  final int level;
  final String text;
  
  const HeadingBlock({required this.level, required this.text});
}

class ParagraphBlock extends ContentBlock {
  final String text;
  
  const ParagraphBlock({required this.text});
}

class UnorderedListBlock extends ContentBlock {
  final List<ListItemData> items;
  
  const UnorderedListBlock({required this.items});
}

class OrderedListBlock extends ContentBlock {
  final List<ListItemData> items;
  
  const OrderedListBlock({required this.items});
}

class ListItemData {
  final String text;
  final bool? isChecked;
  final List<ListItemData>? nestedItems;
  
  const ListItemData({
    required this.text,
    this.isChecked,
    this.nestedItems,
  });
}

class TaskItemBlock extends ContentBlock {
  final String text;
  final bool isChecked;
  
  const TaskItemBlock({required this.text, required this.isChecked});
}

class QuoteBlock extends ContentBlock {
  final String text;
  
  const QuoteBlock({required this.text});
}

class CodeBlock extends ContentBlock {
  final String code;
  final String? language;
  final String? title;
  
  const CodeBlock({required this.code, this.language, this.title});
}

class InlineCodeBlock extends ContentBlock {
  final String code;
  
  const InlineCodeBlock({required this.code});
}

class ImageBlock extends ContentBlock {
  final String url;
  final String? alt;
  final String? caption;
  
  const ImageBlock({required this.url, this.alt, this.caption});
}

class LinkBlock extends ContentBlock {
  final String url;
  final String text;
  
  const LinkBlock({required this.url, required this.text});
}

class DividerBlock extends ContentBlock {
  const DividerBlock();
}

enum HintStyle { info, success, warning, danger }

class HintBlock extends ContentBlock {
  final HintStyle style;
  final String content;
  final String? title;
  
  const HintBlock({required this.style, required this.content, this.title});
}

class TableBlock extends ContentBlock {
  final List<String> headers;
  final List<List<String>> rows;
  
  const TableBlock({required this.headers, required this.rows});
}

class TabsBlock extends ContentBlock {
  final List<TabData> tabs;
  
  const TabsBlock({required this.tabs});
}

class TabData {
  final String title;
  final List<ContentBlock> content;
  
  const TabData({required this.title, required this.content});
}

class CollapsibleBlock extends ContentBlock {
  final String title;
  final List<ContentBlock> content;
  
  const CollapsibleBlock({required this.title, required this.content});
}

class FileDownloadBlock extends ContentBlock {
  final String url;
  final String? filename;
  final String? caption;
  
  const FileDownloadBlock({required this.url, this.filename, this.caption});
}

class EmbedBlock extends ContentBlock {
  final String url;
  
  const EmbedBlock({required this.url});
}
