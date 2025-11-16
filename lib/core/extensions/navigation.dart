import 'package:flutter/material.dart';

extension NavigatorExtension on BuildContext {
  void push(Widget screen) {
    Navigator.of(this).push(MaterialPageRoute(builder: (context) => screen));
  }

  void pushReplacement(Widget screen) {
    Navigator.of(
      this,
    ).pushReplacement(MaterialPageRoute(builder: (context) => screen));
  }

  void pushAndRemoveAll(Widget screen) {
    Navigator.of(this).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  void pushNamed(String routeName) {
    Navigator.of(this).pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    Navigator.of(this).pushReplacementNamed(routeName);
  }

  void pushNamedAndRemoveAll(String routeName) {
    Navigator.of(this).pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  void pop() {
    Navigator.of(this).pop();
  }

  void popUntil(String routeName) {
    Navigator.of(this).popUntil(ModalRoute.withName(routeName));
  }

  void popAndPushNamed(String routeName) {
    Navigator.of(this).popAndPushNamed(routeName);
  }
}
