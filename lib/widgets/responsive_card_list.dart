import 'package:flutter/material.dart';

class ResponsiveCardList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(T) itemBuilder;
  const ResponsiveCardList(
      {super.key, required this.items, required this.itemBuilder});
  @override
  Widget build(BuildContext context) => ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => itemBuilder(items[i]));
}
