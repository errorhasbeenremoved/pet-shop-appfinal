class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;
  const PageResult(
      {required this.items,
      required this.page,
      required this.size,
      required this.total});
  int get totalPages => total == 0 ? 1 : (total / size).ceil();
}
