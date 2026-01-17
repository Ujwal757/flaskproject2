import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/gemini_service.dart';
import 'manual_report_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  File? _imageFile;
  Uint8List? _imageBytes; // For web support
  bool _isAnalyzing = false;
  String? _analysisResult;
  Map<String, dynamic>? _damageAnalysis;

  @override
  Widget build(BuildContext context) {
    final geminiService = Provider.of<GeminiService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Road Damage'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview section
            if (_selectedImage != null) ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? _imageBytes != null
                            ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator())
                      : _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : const SizedBox(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pick image button
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Pick Image from Gallery'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Analyze button
            if (_selectedImage != null && _damageAnalysis == null) ...[
              ElevatedButton.icon(
                onPressed: _isAnalyzing
                    ? null
                    : () => _analyzeImage(geminiService),
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(
                  _isAnalyzing ? 'Analyzing Image...' : 'Analyze Image',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              if (_isAnalyzing)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'This may take 10-20 seconds...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],

            // Analysis results
            if (_damageAnalysis != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Analysis Results',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildAnalysisCard(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to manual report screen with AI analysis data (if available)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManualReportScreen(damageAnalysis: _damageAnalysis),
                    ),
                  );
                },
                icon: const Icon(Icons.report_problem),
                label: const Text('Submit Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],

            // Error message
            if (_analysisResult != null && _damageAnalysis == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _analysisResult!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final severity = _damageAnalysis!['severity'] as String;
    final damageType = _damageAnalysis!['damageType'] as String;
    final description = _damageAnalysis!['description'] as String;
    Color severityColor;
    IconData severityIcon;
    switch (severity.toLowerCase()) {
      case 'severe':
        severityColor = Colors.red;
        severityIcon = Icons.warning;
        break;
      case 'moderate':
        severityColor = Colors.orange;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.yellow.shade700;
        severityIcon = Icons.check_circle;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(severityIcon, color: severityColor),
                const SizedBox(width: 8),
                Text(
                  'Severity: $severity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Damage Type: $damageType',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Description:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75, // Reduced from 85 to 75 for faster uploads
        maxWidth: 1920, // Limit max width to reduce file size
        maxHeight: 1920, // Limit max height to reduce file size
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes first
          final bytes = await image.readAsBytes();
          if (mounted) {
            setState(() {
              _selectedImage = image;
              _imageBytes = bytes;
              _imageFile = null;
              _damageAnalysis = null;
              _analysisResult = null;
            });
          }
        } else {
          // For mobile, use File
          if (mounted) {
            setState(() {
              _selectedImage = image;
              _imageFile = File(image.path);
              _imageBytes = null;
              _damageAnalysis = null;
              _analysisResult = null;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _analyzeImage(GeminiService geminiService) async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      print('🔍 Starting optimized image analysis (single API call)...');
      print('📸 Image path: ${_selectedImage!.path}');
      print('🌐 Is Web: $kIsWeb');

      // Use combined method for faster analysis (single API call)
      final damageAnalysis = await geminiService.analyzeRoadImage(
        _selectedImage!,
      );

      if (damageAnalysis == null) {
        print('❌ Image is not a road surface');
        setState(() {
          _isAnalyzing = false;
          _analysisResult =
              'This image does not appear to be a road surface. Please upload an image of a road.';
        });
        return;
      }

      print('✅ Combined analysis complete: $damageAnalysis');

      setState(() {
        _isAnalyzing = false;
        _damageAnalysis = damageAnalysis;
      });
      print('✅ Analysis successful!');
    } catch (e, stackTrace) {
      print('❌ ERROR analyzing image:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isAnalyzing = false;
        _analysisResult = 'Error analyzing image: $e';
      });
    }
  }
}
