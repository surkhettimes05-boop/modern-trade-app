import 'dart:async';

import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/app_shell.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  unawaited(state.initialize());
  runApp(PasalhoApp(state: state));
}

class PasalhoApp extends StatelessWidget {
  const PasalhoApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        notifier: state,
        child: MaterialApp(
          title: 'PASALHO',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          builder: (context, child) => ColoredBox(
              color: AppColors.cream,
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: child!))),
          home: const AppShell(),
        ),
      );
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found');
    return scope!.notifier!;
  }
}
