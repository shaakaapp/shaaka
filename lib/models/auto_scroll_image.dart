class AutoScrollImage {
  final int id;
  final String image;
  final String? title;
  final bool isActive;
  final int order;
  final String placement;

  AutoScrollImage({
    required this.id,
    required this.image,
    this.title,
    required this.isActive,
    required this.order,
    required this.placement,
  });

  factory AutoScrollImage.fromJson(Map<String, dynamic> json) {
    return AutoScrollImage(
      id: json['id'],
      image: json['image'],
      title: json['title'],
      isActive: json['is_active'] ?? true,
      order: json['order'] ?? 0,
      placement: json['placement'] ?? 'Top',
    );
  }
}
