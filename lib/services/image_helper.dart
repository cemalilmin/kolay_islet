import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image compression service for optimizing dress photos before upload
/// Strategy: Maintain "zoomable clarity" while reducing storage costs
class ImageHelper {
  static final ImageHelper _instance = ImageHelper._internal();
  factory ImageHelper() => _instance;
  ImageHelper._internal();

  // ============== COMPRESSION SETTINGS ==============
  
  /// Target resolution - Full HD is enough for mobile zoom
  static const int _targetWidth = 1920;
  static const int _targetHeight = 1920;
  
  /// Quality - 88% preserves fabric/lace details, don't go below 85%
  static const int _quality = 88;
  
  /// Output format - JPEG for universal compatibility
  static const CompressFormat _format = CompressFormat.jpeg;

  // ============== MAIN COMPRESSION METHOD ==============

  /// Compress an image file while maintaining visual quality
  /// Returns compressed File or null if compression fails
  /// 
  /// Example usage:
  /// ```dart
  /// final compressed = await ImageHelper().compressImage(originalFile);
  /// if (compressed != null) {
  ///   await supabase.storage.from('products').upload(path, compressed);
  /// }
  /// ```
  Future<File?> compressImage(File file) async {
    try {
      final originalSize = await file.length();
      
      // Get temp directory for output
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      // Compress with optimal settings
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: _targetWidth,
        minHeight: _targetHeight,
        quality: _quality,
        format: _format,
        keepExif: false, // Remove metadata to save space
        autoCorrectionAngle: true, // Auto-correct rotation
      );
      
      if (result == null) {
        print('⚠️ ImageHelper: Compression returned null');
        return file; // Return original if compression fails
      }
      
      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      
      // Log the magic
      final originalMB = (originalSize / 1024 / 1024).toStringAsFixed(2);
      final compressedKB = (compressedSize / 1024).toStringAsFixed(0);
      final savings = ((1 - compressedSize / originalSize) * 100).toStringAsFixed(0);
      
      print('✨ ImageHelper Compression:');
      print('   Original: ${originalMB}MB');
      print('   Compressed: ${compressedKB}KB');
      print('   Savings: $savings%');
      
      return compressedFile;
    } catch (e) {
      print('❌ ImageHelper Error: $e');
      return file; // Return original on error
    }
  }

  /// Compress multiple images in parallel
  Future<List<File>> compressImages(List<File> files) async {
    final results = await Future.wait(
      files.map((f) => compressImage(f)),
    );
    
    return results.whereType<File>().toList();
  }

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }

  /// Check if file needs compression (> 500KB)
  static Future<bool> needsCompression(File file) async {
    final size = await file.length();
    return size > 500 * 1024; // 500KB threshold
  }
}
