import 'package:flutter/material.dart';

class PaginationBar extends StatelessWidget {
  final int page, totalPages, total, size;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onSizeChanged;
  const PaginationBar(
      {super.key,
      required this.page,
      required this.totalPages,
      required this.total,
      required this.size,
      required this.onPageChanged,
      required this.onSizeChanged});
  @override
  Widget build(BuildContext context) => Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
                'Страница $page из ${totalPages < 1 ? 1 : totalPages} · $total записей'),
            IconButton(
                onPressed: page > 1 ? () => onPageChanged(1) : null,
                icon: const Icon(Icons.first_page)),
            IconButton(
                onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                icon: const Icon(Icons.chevron_left)),
            IconButton(
                onPressed:
                    page < totalPages ? () => onPageChanged(page + 1) : null,
                icon: const Icon(Icons.chevron_right)),
            IconButton(
                onPressed:
                    page < totalPages ? () => onPageChanged(totalPages) : null,
                icon: const Icon(Icons.last_page)),
            DropdownButton<int>(
                value: size,
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 25, child: Text('25')),
                  DropdownMenuItem(value: 50, child: Text('50'))
                ],
                onChanged: (v) {
                  if (v != null) onSizeChanged(v);
                })
          ]);
}
