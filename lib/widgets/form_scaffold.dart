import 'package:flutter/material.dart';

class DirtyFormScaffold extends StatefulWidget {
  final String title;
  final Widget child;
  final bool isDirty;
  final bool saving;
  const DirtyFormScaffold(
      {super.key,
      required this.title,
      required this.child,
      required this.isDirty,
      this.saving = false});
  @override
  State<DirtyFormScaffold> createState() => _DirtyFormScaffoldState();
}

class _DirtyFormScaffoldState extends State<DirtyFormScaffold> {
  Future<bool> _ask() async =>
      await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
                  title: const Text('Несохранённые изменения'),
                  content: const Text(
                      'На форме есть несохранённые изменения. Уйти без сохранения?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Остаться')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Уйти'))
                  ])) ??
      false;
  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !widget.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !widget.isDirty) return;
        final navigator = Navigator.of(context);
        final ok = await _ask();
        if (ok && mounted) navigator.pop();
      },
      child: Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: widget.child)))));
}
