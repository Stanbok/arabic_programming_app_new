class SlideUploadModel {
  final String title;
  final String content;
  final String? imageUrl;
  final String? codeExample;
  final int order;

  SlideUploadModel({
    required this.title,
    required this.content,
    this.imageUrl,
    this.codeExample,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'codeExample': codeExample,
      'order': order,
    };
  }

  factory SlideUploadModel.fromMap(Map<String, dynamic> map) {
    return SlideUploadModel(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      codeExample: map['codeExample'],
      order: map['order'] ?? 0,
    );
  }

  factory SlideUploadModel.fromSlideModel(dynamic slide) {
    return SlideUploadModel(
      title: slide.title,
      content: slide.content,
      imageUrl: slide.imageUrl,
      codeExample: slide.codeExample,
      order: slide.order,
    );
  }
}
