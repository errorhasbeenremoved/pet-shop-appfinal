import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;
  const TableColumnSpec(
      {required this.label,
      required this.build,
      this.sortField,
      this.numeric = false});
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String)? onSort;
  final List<Widget> Function(T)? actions;
  const EntityTable(
      {super.key,
      required this.columns,
      required this.items,
      required this.idOf,
      this.selected = const {},
      this.onToggleSelect,
      this.sortField,
      this.sortAscending = true,
      this.onSort,
      this.actions});
  @override
  Widget build(BuildContext context) {
    final cols = <DataColumn>[
      if (onToggleSelect != null) const DataColumn(label: Text('')),
      ...columns.map((c) => DataColumn(
          label: Text(c.label),
          numeric: c.numeric,
          onSort: c.sortField != null && onSort != null
              ? (_, __) => onSort!(c.sortField!)
              : null)),
      if (actions != null) const DataColumn(label: Text('Действия'))
    ];
    final rows = items
        .map((e) => DataRow(selected: selected.contains(idOf(e)), cells: [
              if (onToggleSelect != null)
                DataCell(Checkbox(
                    value: selected.contains(idOf(e)),
                    onChanged: (_) => onToggleSelect!(idOf(e)))),
              ...columns.map((c) => DataCell(c.build(e))),
              if (actions != null)
                DataCell(
                    Row(mainAxisSize: MainAxisSize.min, children: actions!(e)))
            ]))
        .toList();
    final idx = columns.indexWhere((c) => c.sortField == sortField);
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
            sortColumnIndex:
                idx < 0 ? null : (onToggleSelect != null ? idx + 1 : idx),
            sortAscending: sortAscending,
            columns: cols,
            rows: rows));
  }
}
