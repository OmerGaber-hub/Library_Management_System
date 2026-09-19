class BookModel {
  int? id;
  String title;
  String? isbn;
  int? publishYear;
  int? pages;
  int categoryId;
  int authorId;
  int? publisherId;
  String? description;
  String? pdfPath;
  String? coverImagePath;

  BookModel({
    this.id,
    required this.title,
    this.isbn,
    this.publishYear,
    this.pages,
    required this.categoryId,
    required this.authorId,
    this.publisherId,
    this.description,
    this.pdfPath,
    this.coverImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isbn': isbn,
      'publish_year': publishYear,
      'pages': pages,
      'category_id': categoryId,
      'author_id': authorId,
      'publisher_id': publisherId,
      'description': description,
      'pdf_path': pdfPath,
      'cover_image_path': coverImagePath,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'],
      title: map['title'],
      isbn: map['isbn'],
      publishYear: map['publish_year'],
      pages: map['pages'],
      categoryId: map['category_id'],
      authorId: map['author_id'],
      publisherId: map['publisher_id'],
      description: map['description'],
      pdfPath: map['pdf_path'],
      coverImagePath: map['cover_image_path'],
    );
  }
}
