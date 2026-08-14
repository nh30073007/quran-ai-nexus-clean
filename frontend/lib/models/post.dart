class Post {
  final int? id;
  final String text;
  final String? image;
  final String? video;
  final bool isOfficial;
  final String addedBy;
  final String addedAt;
  final String? imageRatio;  // <-- Instagram aspect ratio: 'square' or 'portrait'

  Post({
    this.id,
    required this.text,
    this.image,
    this.video,
    required this.isOfficial,
    required this.addedBy,
    required this.addedAt,
    this.imageRatio,  // <-- ADD THIS
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      text: json['text'] ?? '',
      image: json['image'] != null ? _formatImageData(json['image']) : null,
      video: json['video'],
      isOfficial: json['is_official'] ?? false,
      addedBy: json['added_by'] ?? 'anonymous',
      addedAt: json['added_at'] ?? '',
      imageRatio: json['image_ratio'],  // <-- ADD THIS
    );
  }

  static String? _formatImageData(dynamic imageData) {
    if (imageData == null) return null;
    
    String imageStr = imageData.toString();
    
    // If it's already a data URL, return as is
    if (imageStr.startsWith('data:image')) {
      return imageStr;
    }
    
    // If it's base64 without prefix, add the prefix
    try {
      return 'data:image/jpeg;base64,$imageStr';
    } catch (e) {
      return imageStr;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'image': image,
      'video': video,
      'is_official': isOfficial,
      'added_by': addedBy,
      'added_at': addedAt,
      'image_ratio': imageRatio,  // <-- ADD THIS
    };
  }
}