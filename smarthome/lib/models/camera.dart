class Camera {
  final String id;
  final String name;
  final String streamUrl;
  bool isOnline;

  Camera({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.isOnline = true,
  });

  factory Camera.fromJson(Map<String, dynamic> json) => Camera(
        id: json['id'] as String,
        name: json['name'] as String,
        streamUrl: json['streamUrl'] as String,
        isOnline: json['isOnline'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streamUrl': streamUrl,
        'isOnline': isOnline,
      };
}
