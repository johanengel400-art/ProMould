import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/jobcard_parser_service.dart';
import 'jobcard_review_screen.dart';

class JobcardCaptureScreen extends StatefulWidget {
  final int level;
  const JobcardCaptureScreen({super.key, required this.level});

  @override
  State<JobcardCaptureScreen> createState() => _JobcardCaptureScreenState();
}

class _JobcardCaptureScreenState extends State<JobcardCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final JobcardParserService _parserService = JobcardParserService();
  bool _isProcessing = false;
  String? _selectedImagePath;

  @override
  void dispose() {
    _parserService.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan jobcards'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        setState(() {
          _selectedImagePath = photo.path;
        });
        await _processImage(photo.path);
      }
    } catch (e) {
      print('Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error opening camera: ${e.toString().substring(0, 50)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // Request storage permission (handle different Android versions)
    PermissionStatus status;
    if (await Permission.photos.isRestricted ||
        await Permission.photos.isPermanentlyDenied) {
      status = await Permission.storage.request();
    } else {
      status = await Permission.photos.request();
    }

    if (!status.isGranted) {
      // Try alternative permission
      status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required')),
          );
        }
        return;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        await _processImage(image.path);
      }
    } catch (e) {
      print('Gallery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error opening gallery: ${e.toString().substring(0, 50)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print('Processing image: $imagePath');

      // Use original image directly - skip preprocessing completely
      final processedPath = imagePath;

      print('Starting OCR...');

      // Try to get raw OCR text first for debugging
      String? rawOcrText;
      try {
        final inputImage = InputImage.fromFilePath(processedPath);
        final textRecognizer = TextRecognizer();
        final recognizedText = await textRecognizer.processImage(inputImage);
        rawOcrText = recognizedText.text;
        textRecognizer.close();
        print('Raw OCR text length: ${rawOcrText.length}');
      } catch (e) {
        print('Failed to get raw OCR: $e');
      }

      // Parse jobcard
      final jobcardData = await _parserService.parseJobcard(processedPath);
      print(
          'OCR completed. Result: ${jobcardData != null ? "Success" : "Failed"}');

      if (jobcardData == null) {
        print('No data extracted from image');
        if (mounted) {
          // Show dialog with raw text if available
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Data Extracted'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Could not extract structured data.\n\nTips:\n• Ensure text is clear and in focus\n• Capture entire document\n• Try again with different angle\n• Ensure good lighting',
                    ),
                    if (rawOcrText != null && rawOcrText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Raw text detected:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rawOcrText.substring(
                              0,
                              rawOcrText.length > 300
                                  ? 300
                                  : rawOcrText.length),
                          style: const TextStyle(
                              fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      print('Data extracted successfully');
      print('Works Order: ${jobcardData.worksOrderNo.value ?? "not found"}');
      print('FG Code: ${jobcardData.fgCode.value ?? "not found"}');
      print('Overall confidence: ${jobcardData.overallConfidence}');

      // Navigate to review screen
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobcardReviewScreen(
              jobcardData: jobcardData,
              imagePath: imagePath,
              level: widget.level,
            ),
          ),
        );

        // If job was created, pop back to previous screen
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error processing image. Please try again.\nDetails: ${e.toString().substring(0, 100)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedImagePath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Jobcard'),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text(
                    'Processing jobcard...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This may take a few seconds',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  if (_selectedImagePath != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.document_scanner,
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Scan Jobcard',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Capture or upload a jobcard image to automatically extract job details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: _captureFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Tips for best results:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Ensure good lighting',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Keep the jobcard flat',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Capture the entire document',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Avoid shadows and glare',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
