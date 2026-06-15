import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

class RichContent extends StatelessWidget {
  final String? html;
  final TextStyle? baseTextStyle;

  const RichContent({super.key, required this.html, this.baseTextStyle});

  static final RegExp _htmlTagPattern = RegExp(
    r'<\s*\/?\s*[a-z][^>]*>',
    caseSensitive: false,
  );

  static bool looksLikeHtml(String content) =>
      _htmlTagPattern.hasMatch(content);

  @override
  Widget build(BuildContext context) {
    final content = html;
    if (content == null || content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final style = baseTextStyle ?? Theme.of(context).textTheme.bodyMedium;

    // Legacy plain-text pages (saved before admin stored HTML) — keep line breaks.
    if (!looksLikeHtml(content)) {
      return Text(content, style: style);
    }

    return HtmlWidget(
      content,
      textStyle: style,
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri == null) return false;
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }
        return false;
      },
      customStylesBuilder: (element) {
        final cls = element.className;
        final styles = <String, String>{};

        if (cls.contains('ql-align-center')) styles['text-align'] = 'center';
        if (cls.contains('ql-align-right')) styles['text-align'] = 'right';
        if (cls.contains('ql-align-justify')) styles['text-align'] = 'justify';
        if (cls.contains('ql-size-small')) styles['font-size'] = '0.75em';
        if (cls.contains('ql-size-large')) styles['font-size'] = '1.5em';
        if (cls.contains('ql-size-huge')) styles['font-size'] = '2.5em';
        if (cls.contains('ql-font-monospace')) {
          styles['font-family'] = 'monospace';
        }
        if (cls.contains('ql-font-serif')) styles['font-family'] = 'serif';

        final indentMatch = RegExp(r'ql-indent-(\d+)').firstMatch(cls);
        if (indentMatch != null) {
          final level = int.parse(indentMatch.group(1)!);
          styles['padding-left'] = '${level * 24}px';
        }

        return styles.isEmpty ? null : styles;
      },
    );
  }
}
