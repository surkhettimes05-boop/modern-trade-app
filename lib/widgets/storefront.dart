import 'package:flutter/material.dart';
import '../models/models.dart';

class ShopDepartment {
  const ShopDepartment(this.id, this.name, this.icon);
  final String id;
  final String name;
  final IconData icon;
}

String inferredDepartment(Product product) {
  final name = product.name.toLowerCase();
  if (RegExp('rice|dal|flour|grain').hasMatch(name)) return 'Pantry staples';
  if (RegExp('oil|ghee|spice|masala').hasMatch(name)) {
    return 'Cooking essentials';
  }
  if (RegExp('noodle|snack|biscuit|chocolate|bhujiya').hasMatch(name)) {
    return 'Snacks & noodles';
  }
  if (RegExp('water|drink|juice|coffee|tea').hasMatch(name)) return 'Drinks';
  if (RegExp('laundry|detergent|clean|dishwash').hasMatch(name)) {
    return 'Home care';
  }
  if (RegExp('shampoo|hygiene|tooth|care').hasMatch(name)) {
    return 'Personal care';
  }
  return product.category;
}

IconData departmentIcon(String name) {
  final value = name.toLowerCase();
  if (RegExp('pantry|rice|dal|grain').hasMatch(value)) {
    return Icons.grass_outlined;
  }
  if (RegExp('cook|oil|ghee').hasMatch(value)) {
    return Icons.soup_kitchen_outlined;
  }
  if (RegExp('snack|noodle|chocolate').hasMatch(value)) {
    return Icons.ramen_dining_outlined;
  }
  if (RegExp('drink|water|tea').hasMatch(value)) {
    return Icons.local_drink_outlined;
  }
  if (RegExp('home|clean|laundry').hasMatch(value)) {
    return Icons.cleaning_services_outlined;
  }
  if (RegExp('personal|care|hygiene').hasMatch(value)) {
    return Icons.spa_outlined;
  }
  return Icons.shopping_basket_outlined;
}

List<ShopDepartment> shopDepartments(
    List<ProductCategory> categories, List<Product> products) {
  if (categories.isNotEmpty) {
    return categories
        .map((c) => ShopDepartment(c.id, c.name, departmentIcon(c.name)))
        .toList();
  }
  final names = products.map(inferredDepartment).toSet();
  return names
      .map((name) =>
          ShopDepartment('department:$name', name, departmentIcon(name)))
      .toList();
}

bool matchesDepartment(Product product, String? id) =>
    id == null ||
    (id.startsWith('department:')
        ? inferredDepartment(product) == id.substring(11)
        : product.categoryId == id ||
            product.category.toLowerCase() == id.toLowerCase());
