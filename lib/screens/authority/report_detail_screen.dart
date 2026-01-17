import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../models/report_update.dart';
import '../../services/database_service.dart';
import 'task_assignment_screen.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _databaseService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (report.status == ReportStatus.pending || report.status == ReportStatus.assigned)
            IconButton(
              icon: const Icon(Icons.assignment),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskAssignmentScreen(report: report),
                  ),
                );
              },
              tooltip: 'Assign Task',
            ),
        ],
      ),
      body: SingleChildScrollView(
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
                    Text(
                      'Report Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Severity', report.severity.name.toUpperCase()),
                    _buildDetailRow('Damage Type', report.damageType.name.toUpperCase()),
                    _buildDetailRow('Status', report.status.name.toUpperCase()),
                    _buildDetailRow('Location', report.location),
                    if (report.assignedWorkerId != null) ...[
                      const SizedBox(height: 8),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _databaseService.getUser(report.assignedWorkerId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return _buildDetailRow(
                              'Assigned Worker',
                              snapshot.data!['name'] as String? ?? 'Unknown',
                            );
                          }
                          return _buildDetailRow('Assigned Worker', 'Loading...');
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Description:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(report.description),
                    const SizedBox(height: 16),
                    Text(
                      'Before Image:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (report.imageUrl != null && report.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          report.imageUrl!,
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
                            Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No image provided',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (report.afterImageUrl != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'After Image:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          report.afterImageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Reported: ${_formatDateTime(report.timestamp)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (report.completedAt != null)
                      Text(
                        'Completed: ${_formatDateTime(report.completedAt!)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              stream: _databaseService.streamReportUpdates(report.id),
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(update.message),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(update.timestamp),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (update.workerName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'By: ${update.workerName}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                        trailing: update.afterImageUrl != null
                            ? IconButton(
                                icon: const Icon(Icons.image),
                                onPressed: () {
                                  _showAfterImage(context, update.afterImageUrl!);
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
            width: 120,
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

  void _showAfterImage(BuildContext context, String imageUrl) {
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
            Flexible(
              child: Image.network(imageUrl),
            ),
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
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

