import 'topic.dart';

/// Rooted topics in catalog order. Orphans and cycles cannot be selected.
class TopicHierarchy {
  final byId = <int, Topic>{};
  final roots = <int>[];
  final subjectOf = <int, int>{};
  final _members = <int, List<int>>{};

  final _siblings = <(int?, String, String), int>{};

  String _name(Topic topic, String locale) {
    final names = [
      if (locale == 'hu') topic.nameHu,
      topic.nameEn,
      topic.nameHu,
      topic.slug
    ];
    return names
        .map((name) => name.trim())
        .firstWhere((name) => name.isNotEmpty, orElse: () => '');
  }

  TopicHierarchy(Iterable<Map<String, dynamic>> rows) {
    final children = <int?, List<int>>{};
    for (final row in rows) {
      final node = Topic.fromJson(row);
      byId[node.id] = node;
      for (final locale in ['en', 'hu']) {
        final key = (node.parentId, locale, _name(node, locale).toLowerCase());
        _siblings.update(key, (count) => count + 1, ifAbsent: () => 1);
      }
      (children[node.parentId] ??= []).add(node.id);
    }
    for (final root in children[null] ?? const <int>[]) {
      roots.add(root);
      final members = _members[root] = [];
      final pending = [root];
      while (pending.isNotEmpty) {
        final id = pending.removeLast();
        if (subjectOf.containsKey(id)) continue;
        subjectOf[id] = root;
        members.add(id);
        pending.addAll((children[id] ?? const <int>[]).reversed);
      }
    }
  }

  Iterable<int> members(int? root) => _members[root] ?? const [];
  bool containsSection(int? root, int? id) =>
      root != null && id != null && id != root && subjectOf[id] == root;

  List<int> branch(int id) {
    final root = subjectOf[id];
    final path = <int>[];
    for (int? at = id; root != null && at != null; at = byId[at]?.parentId) {
      path.add(at);
      if (at == root) break;
    }
    return path;
  }

  String label(int id, String locale, String fallback,
      {bool includeRoot = false}) {
    final parts = <String>[];
    final root = subjectOf[id];
    for (final current in branch(id)) {
      if (current == root && current != id && !includeRoot) break;
      final node = byId[current]!;
      final language = locale == 'hu' ? 'hu' : 'en';
      final name = _name(node, language);
      final label = name.isEmpty ? fallback : name;
      final count =
          _siblings[(node.parentId, language, name.toLowerCase())] ?? 0;
      parts.add(count > 1 ? '$label [#$current]' : label);
      if (current == root) break;
    }
    return parts.reversed.join(' › ');
  }
}
