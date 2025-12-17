import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

mixin InternetConnectionMixin<T extends StatefulWidget> on State<T> {
  late final StreamSubscription<InternetConnectionStatus>
  _connectionSubscription;
  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker.createInstance();
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();
    _initConnectionChecker();
  }

  Future<void> _initConnectionChecker() async {
    hasInternet = await _connectionChecker.hasConnection;
    if (mounted) setState(() {});
    _connectionSubscription = _connectionChecker.onStatusChange.listen((
      status,
    ) {
      final currentStatus = status == InternetConnectionStatus.connected;
      if (mounted && hasInternet != currentStatus) {
        setState(() {
          hasInternet = currentStatus;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}
