import 'package:flutter/material.dart';
import '../core/models/user_model.dart';

class ConnectionCard extends StatelessWidget {
  final UserModel user;

  const ConnectionCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
