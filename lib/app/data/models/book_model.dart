class BookModel {
  final String id; // <--- UBAH JADI STRING (UUID)
  final String userId;
  final String title;
  final String? author;
  final String status;
  final int? totalPages;
  final int currentPage;
  final int? rating;
  final String? notes;
  final String? coverUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookModel({
    required this.id,
    required this.userId,
    required this.title,
    this.author,
    required this.status,
    this.totalPages,
    this.currentPage = 0,
    this.rating,
    this.notes,
    this.coverUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      // PENTING: Pakai .toString() agar UUID terbaca benar sebagai String
      id: map['id'].toString(), 
      userId: map['user_id']?.toString() ?? '',
      title: map['title'] ?? 'Tanpa Judul',
      author: map['author'],
      status: map['status'] ?? 'to_read',
      totalPages: map['total_pages'],
      currentPage: map['current_page'] ?? 0,
      rating: map['rating'],
      notes: map['notes'],
      coverUrl: map['cover_url'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // id tidak dikirim saat insert biasanya, tapi kalau update butuh
      'user_id': userId,
      'title': title,
      'author': author,
      'status': status,
      'total_pages': totalPages,
      'current_page': currentPage,
      'rating': rating,
      'notes': notes,
      'cover_url': coverUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
