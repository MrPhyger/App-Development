import 'package:flutter/material.dart';

String money(num value) {
  final negative = value < 0;
  final digits = value.abs().round().toString();

  if (digits.length <= 3) {
    return '${negative ? '-₹' : '₹'}$digits';
  }

  final lastThree = digits.substring(digits.length - 3);
  final leading = digits.substring(0, digits.length - 3);

  final grouped = leading.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
    (match) => '${match.group(1)},',
  );

  return '${negative ? '-₹' : '₹'}$grouped$lastThree';
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.value, {
    super.key,
    this.style,
  });

  final num value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      money(value),
      style: style,
    );
  }
}
