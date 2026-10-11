class ListQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;
  final String? filter;
  const ListQuery(
      {this.search = '',
      this.sortField = 'name',
      this.sortAscending = true,
      this.page = 1,
      this.size = 10,
      this.includeDeleted = false,
      this.filter});
  static const _unset = Object();
  ListQuery copyWith(
          {String? search,
          String? sortField,
          bool? sortAscending,
          int? page,
          int? size,
          bool? includeDeleted,
          Object? filter = _unset}) =>
      ListQuery(
          search: search ?? this.search,
          sortField: sortField ?? this.sortField,
          sortAscending: sortAscending ?? this.sortAscending,
          page: page ?? 1,
          size: size ?? this.size,
          includeDeleted: includeDeleted ?? this.includeDeleted,
          filter: filter == _unset ? this.filter : filter as String?);
  Uri toUri(String path) => Uri(path: path, queryParameters: {
        if (search.isNotEmpty) 'search': search,
        if (sortField != 'name' || !sortAscending)
          'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
        if (page != 1) 'page': '$page',
        if (size != 10) 'size': '$size',
        if (includeDeleted) 'deleted': '1',
        if (filter != null) 'filter': filter!
      });
  factory ListQuery.fromUri(Uri uri) {
    final s = uri.queryParameters['sort']?.split(',');
    final size = int.tryParse(uri.queryParameters['size'] ?? '') ?? 10;
    final page = int.tryParse(uri.queryParameters['page'] ?? '') ?? 1;
    return ListQuery(
        search: uri.queryParameters['search'] ?? '',
        sortField: s != null && s.isNotEmpty ? s.first : 'name',
        sortAscending: s == null || s.length < 2 || s[1] != 'desc',
        page: page < 1 ? 1 : page,
        size: [10, 25, 50].contains(size) ? size : 10,
        includeDeleted: uri.queryParameters['deleted'] == '1',
        filter: uri.queryParameters['filter']);
  }
}
