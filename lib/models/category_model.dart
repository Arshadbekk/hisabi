// lib/models/category_model.dart
import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id:       map['id']       as String,
    name:     map['name']     as String,
    iconName: map['iconName'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id':       id,
    'name':     name,
    'iconName': iconName,
  };

  /// Instance getter you already have
  IconData get iconData {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'power':
        return Icons.power;
      case 'shopping_bag':
        return Icons.shopping_bag;
      default:
        return Icons.category;
    }
  }

  /// Static helper: give me an icon for this category ID
  static IconData iconDataFor(String id) {
    switch (id) {
      case 'food':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.power;
      case 'shopping':
        return Icons.shopping_bag;
      case 'other':
        return Icons.category;
      default:
        return Icons.category;
    }
  }
}
