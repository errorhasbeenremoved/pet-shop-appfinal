import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class InactivityWatcher extends StatefulWidget {
  final Widget child;
  const InactivityWatcher({super.key, required this.child});
  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _ticker;
  bool _warning = false;
  bool _handling = false;
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  bool _onKey(KeyEvent e) {
    context.read<AuthNotifier>().recordActivity();
    return false;
  }

  Future<void> _check() async {
    if (!mounted || _handling) return;
    final a = context.read<AuthNotifier>();
    if (!a.isAuthenticated) return;
    final inactivity = a.inactivityRemaining;
    final session = a.sessionRemaining;
    if (session != null && session <= Duration.zero) {
      _handling = true;
      if (_warning && mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      _warning = false;
      await a.logout(
          message: 'Истекла максимальная длительность сессии (8 часов).');
      _handling = false;
      return;
    }
    if (inactivity != null && inactivity <= Duration.zero) {
      _handling = true;
      if (_warning && mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
      }
      _warning = false;
      await a.logout(message: 'Сессия завершена из-за 3 минут бездействия.');
      _warning = false;
      _handling = false;
      return;
    }
    if (inactivity != null &&
        inactivity <= const Duration(seconds: 30) &&
        !_warning) {
      _warning = true;
      if (mounted) {
        showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (d) => AlertDialog(
                    title: const Text('Сессия скоро завершится'),
                    content: const Text(
                        'Из-за бездействия выход произойдёт через 30 секунд. Нажмите «Остаться», чтобы продолжить работу.'),
                    actions: [
                      FilledButton(
                          onPressed: () {
                            context.read<AuthNotifier>().recordActivity();
                            _warning = false;
                            Navigator.of(d).pop();
                          },
                          child: const Text('Остаться'))
                    ])).then((_) {
          _warning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => context.read<AuthNotifier>().recordActivity(),
      onPointerMove: (_) => context.read<AuthNotifier>().recordActivity(),
      onPointerSignal: (_) => context.read<AuthNotifier>().recordActivity(),
      child: widget.child);
}
