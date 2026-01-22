import 'package:flutter/material.dart';

class DayBox extends StatelessWidget {
  final int day;
  final bool isRented;
  final bool isSelected;

  const DayBox({
    super.key,
    required this.day,
    required this.isRented,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color boxColor;

    if (isRented) {
      boxColor = Colors.redAccent;
    } else if (isSelected) {
      boxColor = Colors.green;
    } else {
      boxColor = Colors.grey.shade300;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          "$day",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
