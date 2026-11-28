import 'package:material_ui/material_ui.dart';

import 'apex_colors.dart';

/// دوال مشتركة لعرض معلومات الملفات — تستخدم في Mobile و TV
class FileUiUtils {
  FileUiUtils._();

  /// أيقونة الملف حسب الامتداد
  static IconData fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image_rounded;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.movie_rounded;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'm4a':
        return Icons.music_note_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      case 'apk':
        return Icons.android_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  /// لون الملف حسب الامتداد
  static Color fileColor(String name, ApexColors c) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return c.tintRed;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return c.tintBlue;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return c.accent;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'm4a':
        return c.tintPink;
      case 'zip':
      case 'rar':
      case '7z':
        return c.tintOrange;
      case 'apk':
        return c.tintGreen;
      case 'doc':
      case 'docx':
        return c.tintBlue;
      case 'xls':
      case 'xlsx':
        return c.tintGreen;
      default:
        return c.tintGrey;
    }
  }

  /// تنسيق حجم الملف بالوحدة المناسبة
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
