class CategoryOption {
  final String id;
  final String label;
  final String output;
  final bool customInput;

  CategoryOption({
    required this.id,
    required this.label,
    required this.output,
    this.customInput = false,
  });

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      output: json['output'] ?? '',
      customInput: json['customInput'] ?? false,
    );
  }
}

class Category {
  final String name;
  final bool optional;
  final List<CategoryOption> options;

  Category({
    required this.name,
    this.optional = false,
    required this.options,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] ?? '',
      optional: json['optional'] ?? false,
      options: (json['options'] as List?)
          ?.map((o) => CategoryOption.fromJson(o))
          .toList() ?? [],
    );
  }
}
