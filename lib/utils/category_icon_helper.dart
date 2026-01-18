import 'package:flutter/material.dart';

class CategoryIconHelper {
  static IconData getIcon(String category) {
    switch (category) {
      // Income
      case 'เงินเดือน':
        return Icons.account_balance_wallet;
      case 'ธุรกิจ':
        return Icons.store;
      case 'การลงทุน':
        return Icons.trending_up;
      case 'ของขวัญ':
        return Icons.card_giftcard;
      
      // Expenses
      case 'อาหาร':
        return Icons.restaurant;
      case 'การเดินทาง':
        return Icons.directions_car;
      case 'ช้อปปิ้ง':
        return Icons.shopping_bag;
      case 'ค่าบิล':
        return Icons.receipt_long;
      case 'ความบันเทิง':
        return Icons.movie;
      case 'สุขภาพ':
        return Icons.medical_services;
      case 'การศึกษา':
        return Icons.school;
        
      // Common / Others
      case 'อื่นๆ':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      // Income specific colors (shades of green/blue/gold)
      case 'เงินเดือน':
        return Colors.green;
      case 'ธุรกิจ':
        return Colors.blue;
      case 'การลงทุน':
        return Colors.purple;
      case 'ของขวัญ':
        return Colors.amber;

      // Expenses specific colors
      case 'อาหาร':
        return Colors.orange;
      case 'การเดินทาง':
        return Colors.blueAccent;
      case 'ช้อปปิ้ง':
        return Colors.pink;
      case 'ค่าบิล':
        return Colors.redAccent;
      case 'ความบันเทิง':
        return Colors.indigo;
      case 'สุขภาพ':
        return Colors.teal;
      case 'การศึกษา':
        return Colors.brown;

      // Default
      case 'อื่นๆ':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
}
