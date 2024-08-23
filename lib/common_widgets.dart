
import 'package:flutter/material.dart';

const floatPrecision = 4;

class Heading extends StatelessWidget {
  const Heading({
    super.key,
    required this.title,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}