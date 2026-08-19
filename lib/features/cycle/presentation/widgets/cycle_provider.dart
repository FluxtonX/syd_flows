import 'package:flutter/material.dart';
import 'package:syd_flow/features/cycle/presentation/viewmodels/cycle_state_notifier.dart';

/// InheritedWidget that provides [CycleStateNotifier] to the entire widget tree.
///
/// Access it anywhere with:
/// ```dart
/// final cycleNotifier = CycleProvider.of(context);
/// ```
///
/// Or use [CycleProvider.ofNullable] when the widget may be outside the tree.
class CycleProvider extends InheritedNotifier<CycleStateNotifier> {
  const CycleProvider({
    super.key,
    required CycleStateNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Returns the [CycleStateNotifier] from the widget tree.
  ///
  /// Throws a [FlutterError] if not found — use [ofNullable] in uncertain contexts.
  static CycleStateNotifier of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<CycleProvider>();
    if (provider == null) {
      throw FlutterError(
        'CycleProvider.of() called with a context that does not contain a CycleProvider.\n'
        'Make sure CycleProvider is an ancestor of the widget calling this method.',
      );
    }
    return provider.notifier!;
  }

  /// Returns the [CycleStateNotifier] from the widget tree, or null if not found.
  static CycleStateNotifier? ofNullable(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CycleProvider>()
        ?.notifier;
  }
}

/// Root widget that initialises and owns the [CycleStateNotifier].
///
/// Wrap [SydFlowApp] with this to provide cycle state app-wide:
/// ```dart
/// runApp(const CycleProviderRoot(child: SydFlowApp()));
/// ```
class CycleProviderRoot extends StatefulWidget {
  final Widget child;

  const CycleProviderRoot({super.key, required this.child});

  @override
  State<CycleProviderRoot> createState() => _CycleProviderRootState();
}

class _CycleProviderRootState extends State<CycleProviderRoot> {
  late final CycleStateNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = CycleStateNotifier();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CycleProvider(notifier: _notifier, child: widget.child);
  }
}
