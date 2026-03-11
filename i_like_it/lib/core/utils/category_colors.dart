import 'package:flutter/material.dart';

class CategoryColors {
  // Consistent Color Map
  static final Map<String, Color> _categoryColors = {
    'coding': Colors.blue,
    'web_development': Colors.lightBlue,
    'mobile_apps': Colors.indigo,
    'ai_ml': Colors.deepPurple,
    'data_science': Colors.purple,
    
    'gaming': const Color(0xFFF97316), // Orange
    'movies': Colors.red,
    'series': Colors.redAccent,
    'anime': Colors.pink,
    'music': Colors.pinkAccent,
    
    'finance': Colors.green,
    'investing': Colors.teal,
    'crypto': Colors.amber,
    'banking': Colors.lime,
    
    'health': Colors.cyan,
    'fitness': Colors.lightBlueAccent,
    'recipes': Colors.orangeAccent,
    
    'project': const Color(0xFF06B6D4), // Cyan
    'work': Colors.brown,
    'business': Colors.blueGrey,
    
    'personal': const Color(0xFF10B981), // Emerald
    'travel': Colors.yellow,
    'fashion': Colors.deepOrange,
    
    'news': Colors.grey,
    'other': Colors.white24,
  };

  static Color getColor(String category) {
    final key = category.toLowerCase().trim();
    if (_categoryColors.containsKey(key)) {
      return _categoryColors[key]!;
    }
    // Deterministic fallback based on hash
    return Colors.primaries[category.hashCode.abs() % Colors.primaries.length];
  }
}
