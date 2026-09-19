import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../utils/app_colors.dart';
import '../../models/book_model.dart';

class BookReaderScreen extends StatelessWidget {
  final BookModel book;

  const BookReaderScreen({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (book.pdfPath == null || book.pdfPath!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(book.title)),
        body: const Center(child: Text('ملف الكتاب غير متوفر')),
      );
    }

    final File pdfFile = File(book.pdfPath!);
    if (!pdfFile.existsSync()) {
      return Scaffold(
        appBar: AppBar(title: Text(book.title)),
        body: const Center(child: Text('عذراً، لم يتم العثور على ملف الكتاب في المسار المحدد')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        backgroundColor: AppColors.primaryNavy,
      ),
      body: SfPdfViewer.file(
        pdfFile,
        canShowScrollHead: false,
        canShowScrollStatus: false,
      ),
    );
  }
}
