import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../utils/app_colors.dart';
import '../repositories/auth_repository.dart';
import '../database/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = AuthRepository.currentUser;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    if (user == null) return;

    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.image,
    );

    if (result != null && result.path != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        File sourceFile = File(result.path!);
        
        // Get app document directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${user!.id}_profile_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourceFile.path)}';
        final savedFile = await sourceFile.copy('${directory.path}/$fileName');

        // Update database
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'users',
          {'profile_image_path': savedFile.path},
          where: 'id = ?',
          whereArgs: [user!.id],
        );

        // Update in-memory user
        setState(() {
          user!.profileImagePath = savedFile.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ أثناء تحديث الصورة'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text('غير مصرح'));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.primaryNavy,
                backgroundImage: (user!.profileImagePath != null && user!.profileImagePath!.isNotEmpty)
                    ? FileImage(File(user!.profileImagePath!))
                    : null,
                child: (user!.profileImagePath == null || user!.profileImagePath!.isEmpty)
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  backgroundColor: AppColors.accentGold,
                  radius: 20,
                  child: IconButton(
                    icon: _isUploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    onPressed: _pickImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user!.fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 10),
          Text(
            user!.email,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            'الدور: ${user!.role}',
            style: const TextStyle(fontSize: 16, color: AppColors.accentGold, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
