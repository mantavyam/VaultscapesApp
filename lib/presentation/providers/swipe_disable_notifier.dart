import 'package:flutter/widgets.dart';

/// Provider to communicate swipe disable state from child screens to parent navigation
/// Used by SYNERGY form screens to disable swipe while filling forms
class SwipeDisableNotifier extends InheritedNotifier<ValueNotifier<bool>> {
  const SwipeDisableNotifier({
    super.key,
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Get the notifier from context
  static ValueNotifier<bool>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SwipeDisableNotifier>()
        ?.notifier;
  }

  /// Check if swipe should be disabled
  static bool shouldDisableSwipe(BuildContext context) {
    final notifier = of(context);
    return notifier?.value ?? false;
  }

  /// Set swipe disable state
  static void setSwipeDisabled(BuildContext context, bool disabled) {
    final notifier = of(context);
    if (notifier != null && notifier.value != disabled) {
      notifier.value = disabled;
    }
  }
}
