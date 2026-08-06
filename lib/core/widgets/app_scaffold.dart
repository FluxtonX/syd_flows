import 'package:flutter/material.dart';
import 'animated_background.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool useAnimatedBackground;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.useAnimatedBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      backgroundColor: useAnimatedBackground ? Colors.transparent : null,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );

    if (useAnimatedBackground) {
      content = AnimatedBackground(child: content);
    }

    return content;
  }
}
