class HtmlUtils {
  /// Strip HTML tags from string (e.g., <em class="keyword">text</em> → text)
  static String stripHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
