import 'package:flutter/material.dart';

class RatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final bool showText;
  final bool showValue;
  final bool compact;

  const RatingDisplay({
    Key? key,
    required this.rating,
    this.size = 24.0,
    this.showText = true,
    this.showValue = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure rating is a valid number between 0 and 5
    final safeRating = rating.isNaN || rating < 0 ? 0.0 : (rating > 5 ? 5.0 : rating);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(5, (index) {
              // Calculate if this star should be full, half, or empty
              final starValue = index + 1;
              IconData iconData;
              
              if (safeRating >= starValue) {
                iconData = Icons.star; // Full star
              } else if (safeRating > index && safeRating < starValue) {
                iconData = Icons.star_half; // Half star
              } else {
                iconData = Icons.star_border; // Empty star
              }
              
              return Icon(
                iconData,
                color: Colors.amber,
                size: size,
              );
            }),
            if (showValue) ...[
              SizedBox(width: 8),
              Text(
                "${safeRating.toStringAsFixed(1)}",
                style: TextStyle(
                  fontSize: size * 0.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        if (showText) ...[
          SizedBox(height: 4),
          Text(
            _getRatingText(safeRating),
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return "Excellent";
    if (rating >= 4.0) return "Very Good";
    if (rating >= 3.0) return "Good";
    if (rating >= 2.0) return "Fair";
    if (rating > 0) return "Poor";
    return "Not Rated";
  }
}
