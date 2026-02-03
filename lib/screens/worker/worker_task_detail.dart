import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/report.dart';
import '../../models/report_update.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/report_image.dart';
import '../../models/notification_model.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerTaskDetailScreen extends StatefulWidget {
  final Report report;

  const WorkerTaskDetailScreen({super.key, required this.report});

  @override
  State<WorkerTaskDetailScreen> createState() => _WorkerTaskDetailScreenState();
}

class _WorkerTaskDetailScreenState extends State<WorkerTaskDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _updateMessageController =
      TextEditingController();

  XFile? _selectedAfterImage;
  File? _afterImageFile;
  Uint8List? _afterImageBytes;
  bool _isUploading = false;
  ReportStatus _selectedStatus = ReportStatus.assigned;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
  }

  @override
  void dispose() {
    _updateMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<Report?>(
        stream: _databaseService.streamReport(widget.report.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final report = snapshot.data ?? widget.report;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Report Details',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  report.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(report.status),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(report.status),
                                    size: 16,
                                    color: _getStatusColor(report.status),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    report.status.name.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(report.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Severity',
                          report.severity.name.toUpperCase(),
                        ),
                        _buildDetailRow(
                          'Damage Type',
                          report.damageType.name.toUpperCase(),
                        ),
                        _buildDetailRow('Location', report.location),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _openMap(report.location),
                          icon: const Icon(Icons.map),
                          label: const Text('Open in Google Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Description:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(report.description),
                        const SizedBox(height: 16),
                        // Before image
                        Text(
                          'Before Image:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (report.imageUrl != null &&
                            report.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ReportImage(
                              imageUrl: report.imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No image provided',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // After image if exists
                        if (report.afterImageUrl != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'After Image:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ReportImage(
                              imageUrl: report.afterImageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status update section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ReportStatus>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            // Always include the current status to avoid Flutter's assertion failure
                            if (report.status == ReportStatus.assigned)
                              const DropdownMenuItem(
                                value: ReportStatus.assigned,
                                child: Text('Assigned'),
                              ),
                            if (report.status == ReportStatus.inProgress)
                              const DropdownMenuItem(
                                value: ReportStatus.inProgress,
                                child: Text('In Progress'),
                              ),
                            if (report.status == ReportStatus.completed)
                              const DropdownMenuItem(
                                value: ReportStatus.completed,
                                child: Text('Completed'),
                              ),

                            // Add available transitions
                            if (report.status == ReportStatus.assigned)
                              const DropdownMenuItem(
                                value: ReportStatus.inProgress,
                                child: Text('In Progress'),
                              ),
                            if (report.status == ReportStatus.inProgress)
                              const DropdownMenuItem(
                                value: ReportStatus.completed,
                                child: Text('Completed'),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _updateMessageController,
                          decoration: const InputDecoration(
                            labelText: 'Update Message',
                            hintText: 'Describe the progress or completion...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),
                        // After image upload
                        if (_selectedStatus == ReportStatus.completed) ...[
                          Text(
                            'After Image (Optional)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_selectedAfterImage != null) ...[
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? (_afterImageBytes != null
                                          ? Image.memory(
                                              _afterImageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ))
                                    : (_afterImageFile != null
                                          ? Image.file(
                                              _afterImageFile!,
                                              fit: BoxFit.cover,
                                            )
                                          : const SizedBox()),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: _pickAfterImage,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              _selectedAfterImage != null
                                  ? 'Change Image'
                                  : 'Upload After Image',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _submitUpdate,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit Update'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Update history
                Text(
                  'Update History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<ReportUpdate>>(
                  stream: _databaseService.streamReportUpdates(
                    widget.report.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    final updates = snapshot.data ?? [];
                    if (updates.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No updates yet'),
                        ),
                      );
                    }

                    return Column(
                      children: updates.map((update) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(update.status),
                              child: Icon(
                                _getStatusIcon(update.status),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              update.status.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(update.message),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(update.timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (update.workerName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'By: ${update.workerName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: update.afterImageUrl != null
                                ? IconButton(
                                    icon: const Icon(Icons.image),
                                    onPressed: () {
                                      _showAfterImage(update.afterImageUrl!);
                                    },
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _pickAfterImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 25,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (mounted) {
            setState(() {
              _selectedAfterImage = image;
              _afterImageBytes = bytes;
              _afterImageFile = null;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _selectedAfterImage = image;
              _afterImageFile = File(image.path);
              _afterImageBytes = null;
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

  Future<void> _submitUpdate() async {
    if (_updateMessageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an update message'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }

    // Make after image mandatory for completion
    if (_selectedStatus == ReportStatus.completed &&
        _selectedAfterImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload an after image to mark the task as completed',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? afterImageUrl;

      // Upload after image if provided
      if (_selectedAfterImage != null) {
        const uuid = Uuid();
        final imageId = uuid.v4();
        afterImageUrl = kIsWeb
            ? await _databaseService.uploadImageBytes(
                _afterImageBytes!,
                imageId,
              )
            : await _databaseService.uploadImage(_afterImageFile!, imageId);
      }

      // Get worker name
      final workerData = await _databaseService.getUser(user.id);
      final workerName = workerData?['name'] as String?;

      // Create update
      const uuid = Uuid();
      final update = ReportUpdate(
        id: uuid.v4(),
        reportId: widget.report.id,
        workerId: user.id,
        workerName: workerName,
        status: _selectedStatus,
        message: _updateMessageController.text.trim(),
        timestamp: DateTime.now(),
        afterImageUrl: afterImageUrl,
      );

      // Save update
      await _databaseService.addReportUpdate(update);

      // Trigger notifications
      if (mounted) {
        final notificationService = Provider.of<NotificationService>(
          context,
          listen: false,
        );

        if (_selectedStatus == ReportStatus.inProgress) {
          // Notify Citizen
          await notificationService.showStatusUpdateToCitizen(
            widget.report.id,
            'In Progress',
          );
          // Notify Admin
          await notificationService.showWorkerStartedWork(widget.report.id);
        } else if (_selectedStatus == ReportStatus.completed) {
          // Notify Citizen
          await notificationService.showStatusUpdateToCitizen(
            widget.report.id,
            'Completed',
          );
          // Notify Admin
          await notificationService.showTaskCompletedAlert(widget.report.id);
        }

        // Persistent Notifications for Admins
        final adminIds = await _databaseService.getAuthorityUserIds();
        for (final adminId in adminIds) {
          await _databaseService.createNotification(
            AppNotification(
              id: const Uuid().v4(),
              userId: adminId,
              title: 'Task Status Update',
              message:
                  'Worker ${workerName ?? "Unknown"} updated report status to ${_selectedStatus.name.toUpperCase()} for ${widget.report.damageType.name}.',
              type: _selectedStatus == ReportStatus.completed
                  ? NotificationType.success
                  : NotificationType.info,
              timestamp: DateTime.now(),
              relatedId: widget.report.id,
            ),
          );
        }

        // Persistent Notification for Citizen
        await _databaseService.createNotification(
          AppNotification(
            id: const Uuid().v4(),
            userId: widget.report.userId,
            title: 'Report Status Update',
            message:
                'Your report for ${widget.report.damageType.name} is now ${_selectedStatus.name.toUpperCase()}.',
            type: _selectedStatus == ReportStatus.completed
                ? NotificationType.success
                : NotificationType.info,
            timestamp: DateTime.now(),
            relatedId: widget.report.id,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _updateMessageController.clear();
          _selectedAfterImage = null;
          _afterImageFile = null;
          _afterImageBytes = null;
          // Set selected status back to the updated report status (from stream)
          _selectedStatus = update.status;
        });

        // If completed, go back
        if (_selectedStatus == ReportStatus.completed) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting update: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _showAfterImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('After Image'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(child: ReportImage(imageUrl: imageUrl)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.yellow;
      case ReportStatus.assigned:
        return Colors.blue;
      case ReportStatus.inProgress:
        return Colors.orange;
      case ReportStatus.completed:
        return Colors.green;
      case ReportStatus.verified:
        return Colors.teal;
      case ReportStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.pending;
      case ReportStatus.assigned:
        return Icons.assignment;
      case ReportStatus.inProgress:
        return Icons.work;
      case ReportStatus.completed:
        return Icons.check_circle;
      case ReportStatus.verified:
        return Icons.verified;
      case ReportStatus.closed:
        return Icons.archive;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openMap(String location) async {
    // Check if location is coordinates (lat, lng)
    final coords = location.split(',');
    Uri url;
    if (coords.length == 2) {
      final lat = coords[0].trim();
      final lng = coords[1].trim();
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    } else {
      // Otherwise search as address
      url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
      );
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }
}
