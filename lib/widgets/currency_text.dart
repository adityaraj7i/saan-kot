import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final bool isNegative;

  const CurrencyText(
    this.amount, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppColors.textDark;
    final prefix = isNegative ? '- ' : '';
    final formatted = CurrencyHelper.format(amount.abs());

    return Text(
      '$prefix$formatted',
      style: TextStyle(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: textColor,
      ),
    );
  }
}
