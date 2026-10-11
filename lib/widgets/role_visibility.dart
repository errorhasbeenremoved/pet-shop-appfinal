import 'package:flutter/widgets.dart';

/// Удобство интерфейса, не замена серверной авторизации.
class RoleVisibility extends StatelessWidget {
  final bool allowed;
  final Widget child;
  const RoleVisibility({super.key, required this.allowed, required this.child});

  @override
  Widget build(BuildContext context) =>
      allowed ? child : const SizedBox.shrink();
}
