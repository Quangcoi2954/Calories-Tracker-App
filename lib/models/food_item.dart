class FoodItem {
  final String id;
  final String name;
  final double caloriesPer100g;
  final double? proteinPer100g; // Thêm Protein (nullable)
  final double? carbsPer100g; // Thêm Carb (nullable)
  final double? fatPer100g; // Thêm Fat (nullable)
  final String? brand;
  final String? servingSize;

  FoodItem({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    this.proteinPer100g, // Thêm vào constructor
    this.carbsPer100g, // Thêm vào constructor
    this.fatPer100g, // Thêm vào constructor
    this.brand,
    this.servingSize,
  });

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, cal: $caloriesPer100g, p: $proteinPer100g, c: $carbsPer100g, f: $fatPer100g)';
  }
}
