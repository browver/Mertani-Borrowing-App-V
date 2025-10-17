// import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int iconCode;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      'id' : id,
      'name' : name,
      'icon' : iconCode,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'], 
      name: map['name'], 
      iconCode: map['icon'],
    );
  }

  // fallback brow
  factory CategoryModel.fromFirestore(
    String docId, Map<String, dynamic> data) {
  return CategoryModel(
    id: docId, 
    name: data['name'] ?? docId, 
    iconCode: data['icon'] ?? Icons.inventory_2_outlined.codePoint,
    );
  }
}