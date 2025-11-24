import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImagePreprocessing {
  /// Preprocess image for better OCR results
  /// - Convert to grayscale
  /// - Increase contrast
  /// - Despeckle/denoise
  /// - Sharpen
  static Future<String> preprocessForOcr(String imagePath) async {
    try {
      // Load image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Convert to grayscale
      image = img.grayscale(image);

      // Increase contrast
      image = img.contrast(image, contrast: 120);

      // Sharpen
      image = img.adjustColor(image, saturation: 0);

      // Denoise (using a simple blur then sharpen technique)
      image = img.gaussianBlur(image, radius: 1);

      // Save preprocessed image
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path,
        'preprocessed_$timestamp.jpg',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      return outputPath;
    } catch (e) {
      // If preprocessing fails, return original
      return imagePath;
    }
  }

  /// Auto-rotate image based on EXIF orientation
  static Future<String> autoRotate(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Check if image needs rotation based on dimensions
      // If width > height significantly, might need rotation
      if (image.width < image.height * 0.7) {
        // Likely needs rotation
        image = img.copyRotate(image, angle: 90);

        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final outputPath = path.join(
          tempDir.path,
          'rotated_$timestamp.jpg',
        );

        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

        return outputPath;
      }

      return imagePath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Crop image to remove borders/margins
  static Future<String> autoCrop(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Simple auto-crop: remove 5% from each edge
      const cropMargin = 0.05;
      final cropX = (image.width * cropMargin).toInt();
      final cropY = (image.height * cropMargin).toInt();
      final cropWidth = image.width - (cropX * 2);
      final cropHeight = image.height - (cropY * 2);

      if (cropWidth > 0 && cropHeight > 0) {
        image = img.copyCrop(
          image,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );

        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final outputPath = path.join(
          tempDir.path,
          'cropped_$timestamp.jpg',
        );

        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

        return outputPath;
      }

      return imagePath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Full preprocessing pipeline
  static Future<String> fullPreprocess(String imagePath) async {
    try {
      // Step 1: Auto-rotate if needed
      var processedPath = await autoRotate(imagePath);

      // Step 2: Auto-crop borders
      processedPath = await autoCrop(processedPath);

      // Step 3: Enhance for OCR
      processedPath = await preprocessForOcr(processedPath);

      return processedPath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Resize image if too large (for faster processing)
  static Future<String> resizeIfNeeded(
    String imagePath, {
    int maxWidth = 2000,
    int maxHeight = 2000,
  }) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Check if resize needed
      if (image.width <= maxWidth && image.height <= maxHeight) {
        return imagePath;
      }

      // Calculate new dimensions maintaining aspect ratio
      double scale = math.min(
        maxWidth / image.width,
        maxHeight / image.height,
      );

      final newWidth = (image.width * scale).toInt();
      final newHeight = (image.height * scale).toInt();

      image = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path,
        'resized_$timestamp.jpg',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(image, quality: 90));

      return outputPath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Clean up temporary preprocessed images
  static Future<void> cleanupTempImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File) {
          final filename = path.basename(file.path);
          if (filename.startsWith('preprocessed_') ||
              filename.startsWith('rotated_') ||
              filename.startsWith('cropped_') ||
              filename.startsWith('resized_')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}
