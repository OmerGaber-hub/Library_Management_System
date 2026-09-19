import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/book_model.dart';
import '../../repositories/book_repository.dart';
import '../../repositories/auth_repository.dart';
import 'book_details_screen.dart';
import 'add_edit_book_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  _BooksScreenState createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final BookRepository _bookRepo = BookRepository();
  List<BookModel> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final data = await _bookRepo.getAll();
    setState(() {
      _books = data;
      _isLoading = false;
    });
  }

  // Generate a color based on the book's title hash for a consistent look
  Color _getCoverColor(String title) {
    final colors = [
      Colors.teal,
      Colors.indigo,
      Colors.deepPurple,
      Colors.blueGrey,
      Colors.brown,
      Colors.red[800]!,
      Colors.green[800]!,
    ];
    return colors[title.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isStaff = AuthRepository.currentUser?.isStaff ?? false;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 20),
                      const Text('لا توجد كتب حالياً. ابدأ بإضافة كتاب جديد!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    final coverColor = _getCoverColor(book.title);
                    final hasCustomCover = book.coverImagePath != null && book.coverImagePath!.isNotEmpty;

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BookDetailsScreen(book: book)),
                        );
                        _loadBooks(); // Reload just in case it was modified or deleted inside
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Book Cover section
                            Expanded(
                              flex: 7,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: hasCustomCover
                                    ? Image.file(
                                        File(book.coverImagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildFallbackCover(book.title, coverColor),
                                      )
                                    : _buildFallbackCover(book.title, coverColor),
                              ),
                            ),
                            // Book Details Section
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      book.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (book.pdfPath != null)
                                      Row(
                                        children: [
                                          Icon(Icons.picture_as_pdf, color: Colors.red[400], size: 14),
                                          const SizedBox(width: 4),
                                          const Text('نسخة إلكترونية', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accentGold,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditBookScreen()),
                );
                if (result == true) {
                  _loadBooks();
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('إضافة كتاب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildFallbackCover(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title.length > 20 ? '${title.substring(0, 20)}...' : title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1))],
            ),
          ),
        ),
      ),
    );
  }
}
