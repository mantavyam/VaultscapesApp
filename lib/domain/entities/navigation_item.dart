/// Navigation item entity for domain layer
class NavigationItem {
  final String id;
  final String title;
  final String? subtitle;
  final NavigationType type;
  final String? route;
  final String? url;
  final List<NavigationItem> children;

  const NavigationItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.route,
    this.url,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;
}

enum NavigationType {
  semester,
  subject,
  module,
  resource,
  externalLink,
}
