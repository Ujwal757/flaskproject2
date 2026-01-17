import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/report.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_service.dart';

class ManualReportScreen extends StatefulWidget {
  final Map<String, dynamic>? damageAnalysis; // Optional: AI analysis results
  final String? suggestedLocation; // Optional: GPS location

  const ManualReportScreen({
    super.key,
    this.damageAnalysis,
    this.suggestedLocation,
  });

  @override
  State<ManualReportScreen> createState() => _ManualReportScreenState();
}

class _ManualReportScreenState extends State<ManualReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _useGPS = false;
  DamageSeverity _selectedSeverity = DamageSeverity.moderate;
  DamageType _selectedDamageType = DamageType.pothole;

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Pre-fill location if GPS is suggested
    if (widget.suggestedLocation != null) {
      _locationController.text = widget.suggestedLocation!;
    }
    // Pre-fill description if AI analysis is available
    if (widget.damageAnalysis != null) {
      _descriptionController.text = widget.damageAnalysis!['description'] as String;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getGPSLocation() async {
    setState(() {
      _useGPS = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      ).timeout(const Duration(seconds: 5));
      
      final location = '${position.latitude}, ${position.longitude}';
      setState(() {
        _locationController.text = location;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS location captured successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get GPS location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _useGPS = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a report')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get location from user input
      final location = _locationController.text.trim();
      
      // Generate report ID
      const uuid = Uuid();
      final reportId = uuid.v4();

      // Determine severity and damage type
      // Use AI analysis if available, otherwise use manual selection
      final severity = widget.damageAnalysis != null
          ? GeminiService.parseSeverity(widget.damageAnalysis!['severity'] as String)
          : _selectedSeverity;
      
      final damageType = widget.damageAnalysis != null
          ? GeminiService.parseDamageType(widget.damageAnalysis!['damageType'] as String)
          : _selectedDamageType;

      // Get description
      final description = _descriptionController.text.trim();

      // Create report (without image)
      final report = Report(
        id: reportId,
        imageUrl: null, // No image for manual reports
        location: location,
        status: ReportStatus.pending,
        severity: severity,
        damageType: damageType,
        description: description,
        userId: user.id,
        timestamp: DateTime.now(),
      );

      // Save to database
      await _databaseService.createReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to reports view
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Pothole'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Report the pothole manually. GPS location is optional.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  hintText: 'Enter street address or location details',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: IconButton(
                    icon: _useGPS
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    onPressed: _useGPS ? null : _getGPSLocation,
                    tooltip: 'Get GPS Location',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe the pothole and road damage',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // AI Analysis info (if available)
              if (widget.damageAnalysis != null) ...[
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Analysis Detected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Severity',
                          (widget.damageAnalysis!['severity'] as String).toUpperCase(),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Damage Type',
                          (widget.damageAnalysis!['damageType'] as String).toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Severity selection (if no AI analysis)
              if (widget.damageAnalysis == null) ...[
                DropdownButtonFormField<DamageSeverity>(
                  value: _selectedSeverity,
                  decoration: InputDecoration(
                    labelText: 'Severity *',
                    prefixIcon: const Icon(Icons.warning),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: DamageSeverity.values.map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text(severity.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSeverity = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Damage type selection
                DropdownButtonFormField<DamageType>(
                  value: _selectedDamageType,
                  decoration: InputDecoration(
                    labelText: 'Damage Type *',
                    prefixIcon: const Icon(Icons.construction),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: DamageType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDamageType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Submit button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.report_problem),
                label: Text(
                  _isSubmitting ? 'Submitting Report...' : 'Submit Report',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Saving report to database...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.green.shade700,
          ),
        ),
      ],
    );
  }
}

