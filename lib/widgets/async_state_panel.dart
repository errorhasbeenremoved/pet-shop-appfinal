import 'package:flutter/material.dart';

class AsyncStatePanel extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool empty;
  final String emptyMessage;
  final VoidCallback onRetry;
  final Widget child;

  const AsyncStatePanel({
    super.key,
    required this.loading,
    required this.error,
    required this.empty,
    required this.onRetry,
    required this.child,
    this.emptyMessage = 'Нет данных',
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Semantics(
          label: 'Загрузка данных',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (empty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48),
              const SizedBox(height: 12),
              Text(emptyMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return child;
  }
}
