import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Advanced image preprocessing for optimal OCR results
class AdvancedPreprocessing {
  /// Full preprocessing pipeline with all enhancements
  static Future<PreprocessResult> fullPipeline(String imagePath) async {
    try {
      final steps = <String>[];
      var currentPath = imagePath;

      // Step 1: Resize if too large
      currentPath = await _resizeIfNeeded(currentPath);
      steps.add('Resized');

      // Step 2: Perspective correction
      final perspectiveResult = await _perspectiveCorrection(currentPath);
      if (perspectiveResult != null) {
        currentPath = perspectiveResult;
        steps.add('Perspective corrected');
      }

      // Step 3: Adaptive thresholding
      currentPath = await _adaptiveThreshold(currentPath);
      steps.add('Adaptive threshold');

      // Step 4: Denoise
      currentPath = await _advancedDenoise(currentPath);
      steps.add('Denoised');

      // Step 5: Enhance contrast
      currentPath = await _enhanceContrast(currentPath);
      steps.add('Enhanced contrast');

      // Step 6: Sharpen
      currentPath = await _sharpen(currentPath);
      steps.add('Sharpened');

      return PreprocessResult(
        processedPath: currentPath,
        steps: steps,
        quality: await _assessQuality(currentPath),
      );
    } catch (e) {
      return PreprocessResult(
        processedPath: imagePath,
        steps: ['Error: $e'],
        quality: 0.5,
      );
    }
  }

  /// Detect and correct perspective distortion
  static Future<String?> _perspectiveCorrection(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return null;

      // Convert to grayscale for edge detection
      final gray = img.grayscale(image);

      // Find document edges using contour detection
      final edges = _detectDocumentEdges(gray);

      if (edges.length == 4) {
        // Apply perspective transform
        image = _applyPerspectiveTransform(image, edges);

        // Save corrected image
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final outputPath = path.join(
          tempDir.path,
          'perspective_$timestamp.jpg',
        );

        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

        return outputPath;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Detect document edges (simplified implementation)
  static List<Point> _detectDocumentEdges(img.Image image) {
    // Simplified edge detection - in production use OpenCV's findContours
    final width = image.width;
    final height = image.height;

    // Scan edges for document boundaries
    final topLeft = _findCorner(image, 0, 0, 1, 1);
    final topRight = _findCorner(image, width - 1, 0, -1, 1);
    final bottomLeft = _findCorner(image, 0, height - 1, 1, -1);
    final bottomRight = _findCorner(image, width - 1, height - 1, -1, -1);

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  static Point _findCorner(
    img.Image image,
    int startX,
    int startY,
    int dirX,
    int dirY,
  ) {
    // Simplified corner detection
    int x = startX;
    int y = startY;

    // Scan for edge transition
    for (int i = 0; i < 100; i++) {
      final pixel = image.getPixel(x, y);
      final luminance = img.getLuminance(pixel);

      if (luminance < 128) {
        // Found edge
        return Point(x, y);
      }

      x += dirX * 2;
      y += dirY * 2;

      // Bounds check
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
        break;
      }
    }

    return Point(startX, startY);
  }

  /// Apply perspective transform to correct skew
  static img.Image _applyPerspectiveTransform(
    img.Image image,
    List<Point> corners,
  ) {
    // Calculate target dimensions
    final width = _distance(corners[0], corners[1]).toInt();
    final height = _distance(corners[0], corners[3]).toInt();

    // Create output image
    final output = img.Image(width: width, height: height);

    // Simple perspective mapping (bilinear interpolation)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final u = x / width;
        final v = y / height;

        // Bilinear interpolation of corner positions
        final srcX = _interpolate(
          corners[0].x,
          corners[1].x,
          corners[3].x,
          corners[2].x,
          u,
          v,
        );
        final srcY = _interpolate(
          corners[0].y,
          corners[1].y,
          corners[3].y,
          corners[2].y,
          u,
          v,
        );

        if (srcX >= 0 &&
            srcX < image.width &&
            srcY >= 0 &&
            srcY < image.height) {
          final pixel = image.getPixel(srcX.toInt(), srcY.toInt());
          output.setPixel(x, y, pixel);
        }
      }
    }

    return output;
  }

  static double _distance(Point a, Point b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _interpolate(
    double tl,
    double tr,
    double bl,
    double br,
    double u,
    double v,
  ) {
    final top = tl + (tr - tl) * u;
    final bottom = bl + (br - bl) * u;
    return top + (bottom - top) * v;
  }

  /// Adaptive thresholding for better text extraction
  static Future<String> _adaptiveThreshold(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Convert to grayscale
      image = img.grayscale(image);

      // Apply adaptive thresholding
      final threshold = _calculateOtsuThreshold(image);
      image = _applyThreshold(image, threshold);

      // Save
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path,
        'threshold_$timestamp.jpg',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      return outputPath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Calculate optimal threshold using Otsu's method
  static int _calculateOtsuThreshold(img.Image image) {
    // Build histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        histogram[luminance.toInt()]++;
      }
    }

    // Calculate total pixels
    final total = image.width * image.height;

    // Find optimal threshold
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;
    double maxVariance = 0;
    int threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];

      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i;
      }
    }

    return threshold;
  }

  /// Apply threshold to image
  static img.Image _applyThreshold(img.Image image, int threshold) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        final newValue = luminance > threshold ? 255 : 0;
        image.setPixel(x, y, img.ColorRgb8(newValue, newValue, newValue));
      }
    }
    return image;
  }

  /// Advanced denoising with bilateral filter
  static Future<String> _advancedDenoise(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Apply bilateral filter (edge-preserving smoothing)
      image = _bilateralFilter(image, 5, 50, 50);

      // Save
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path,
        'denoised_$timestamp.jpg',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      return outputPath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Bilateral filter implementation
  static img.Image _bilateralFilter(
    img.Image image,
    int diameter,
    double sigmaColor,
    double sigmaSpace,
  ) {
    final output = image.clone();
    final radius = diameter ~/ 2;

    for (int y = radius; y < image.height - radius; y++) {
      for (int x = radius; x < image.width - radius; x++) {
        double sumR = 0, sumG = 0, sumB = 0, sumWeight = 0;
        final centerPixel = image.getPixel(x, y);

        for (int ky = -radius; ky <= radius; ky++) {
          for (int kx = -radius; kx <= radius; kx++) {
            final neighborPixel = image.getPixel(x + kx, y + ky);

            // Spatial weight
            final spatialDist = math.sqrt(kx * kx + ky * ky);
            final spatialWeight =
                math.exp(-(spatialDist * spatialDist) / (2 * sigmaSpace * sigmaSpace));

            // Color weight
            final colorDist = _colorDistance(centerPixel, neighborPixel);
            final colorWeight =
                math.exp(-(colorDist * colorDist) / (2 * sigmaColor * sigmaColor));

            final weight = spatialWeight * colorWeight;

            sumR += neighborPixel.r * weight;
            sumG += neighborPixel.g * weight;
            sumB += neighborPixel.b * weight;
            sumWeight += weight;
          }
        }

        if (sumWeight > 0) {
          output.setPixel(
            x,
            y,
            img.ColorRgb8(
              (sumR / sumWeight).toInt(),
              (sumG / sumWeight).toInt(),
              (sumB / sumWeight).toInt(),
            ),
          );
        }
      }
    }

    return output;
  }

  static double _colorDistance(img.Pixel a, img.Pixel b) {
    final dr = a.r - b.r;
    final dg = a.g - b.g;
    final db = a.b - b.b;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  /// Enhance contrast
  static Future<String> _enhanceContrast(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
      image = img.contrast(image, contrast: 130);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path,
        'contrast_$timestamp.jpg',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      return outputPath;
    } catch (e) {
      return imagePath;
    }
  }

  /// Sharpen image
  static Future<String> _sharpen(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Apply unsharp mask
      final blurred = img.gaussianBlur(image, radius: 2);
      image = _unsharpMask(image, blurred, 1.5);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path,
        'sharpened_$timestamp.jpg',
      );

      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      return outputPath;
    } catch (e) {
      return imagePath;
    }
  }

  static img.Image _unsharpMask(
    img.Image original,
    img.Image blurred,
    double amount,
  ) {
    final output = original.clone();

    for (int y = 0; y < original.height; y++) {
      for (int x = 0; x < original.width; x++) {
        final origPixel = original.getPixel(x, y);
        final blurPixel = blurred.getPixel(x, y);

        final r = (origPixel.r + amount * (origPixel.r - blurPixel.r)).clamp(0, 255).toInt();
        final g = (origPixel.g + amount * (origPixel.g - blurPixel.g)).clamp(0, 255).toInt();
        final b = (origPixel.b + amount * (origPixel.b - blurPixel.b)).clamp(0, 255).toInt();

        output.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return output;
  }

  /// Resize if image is too large
  static Future<String> _resizeIfNeeded(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      const maxDimension = 2000;
      if (image.width <= maxDimension && image.height <= maxDimension) {
        return imagePath;
      }

      final scale = maxDimension / math.max(image.width, image.height);
      image = img.copyResize(
        image,
        width: (image.width * scale).toInt(),
        height: (image.height * scale).toInt(),
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

  /// Assess image quality
  static Future<double> _assessQuality(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return 0.5;

      // Calculate sharpness (Laplacian variance)
      final sharpness = _calculateSharpness(image);

      // Calculate contrast
      final contrast = _calculateContrast(image);

      // Combine metrics
      final quality = (sharpness * 0.6 + contrast * 0.4).clamp(0.0, 1.0);

      return quality;
    } catch (e) {
      return 0.5;
    }
  }

  static double _calculateSharpness(img.Image image) {
    // Simplified Laplacian variance
    double sum = 0;
    int count = 0;

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final center = img.getLuminance(image.getPixel(x, y));
        final top = img.getLuminance(image.getPixel(x, y - 1));
        final bottom = img.getLuminance(image.getPixel(x, y + 1));
        final left = img.getLuminance(image.getPixel(x - 1, y));
        final right = img.getLuminance(image.getPixel(x + 1, y));

        final laplacian = (4 * center - top - bottom - left - right).abs();
        sum += laplacian;
        count++;
      }
    }

    return (sum / count / 255).clamp(0.0, 1.0);
  }

  static double _calculateContrast(img.Image image) {
    // Calculate standard deviation of luminance
    double sum = 0;
    double sumSq = 0;
    int count = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final lum = img.getLuminance(image.getPixel(x, y));
        sum += lum;
        sumSq += lum * lum;
        count++;
      }
    }

    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    final stdDev = math.sqrt(variance);

    return (stdDev / 128).clamp(0.0, 1.0);
  }

  /// Clean up temporary files
  static Future<void> cleanup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File) {
          final filename = path.basename(file.path);
          if (filename.startsWith('perspective_') ||
              filename.startsWith('threshold_') ||
              filename.startsWith('denoised_') ||
              filename.startsWith('contrast_') ||
              filename.startsWith('sharpened_') ||
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

class Point {
  final double x;
  final double y;

  Point(this.x, this.y);
}

class PreprocessResult {
  final String processedPath;
  final List<String> steps;
  final double quality;

  PreprocessResult({
    required this.processedPath,
    required this.steps,
    required this.quality,
  });
}
