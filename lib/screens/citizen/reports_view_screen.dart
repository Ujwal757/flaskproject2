import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../models/report_update.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../auth/role_selection_screen.dart';
import '../citizen/upload_screen.dart';

class ReportsViewScreen extends StatelessWidget {
  const ReportsViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final DatabaseService _databaseService = DatabaseService();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadScreen()),
              );
            },
            tooltip: 'Report New Issue',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (shouldLogout == true && context.mounted) {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen(),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Report>>(
        stream: _databaseService.streamUserReports(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.report_problem,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No reports yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Report New Issue'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _buildReportCard(
                context,
                reports[index],
                _databaseService,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    Report report,
    DatabaseService databaseService,
  ) {
    Color severityColor;
    IconData severityIcon;
    switch (report.severity) {
      case DamageSeverity.severe:
        severityColor = Colors.red;
        severityIcon = Icons.warning;
        break;
      case DamageSeverity.moderate:
        severityColor = Colors.orange;
        severityIcon = Icons.info;
        break;
      default:
        severityColor = Colors.yellow.shade700;
        severityIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CitizenReportDetailScreen(report: report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(severityIcon, color: severityColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${report.severity.name.toUpperCase()} - ${report.damageType.name.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(report.status.name.toUpperCase()),
                    backgroundColor: _getStatusColor(report.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reported: ${_formatDateTime(report.timestamp)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.yellow.shade100;
      case ReportStatus.assigned:
        return Colors.blue.shade100;
      case ReportStatus.inProgress:
        return Colors.orange.shade100;
      case ReportStatus.completed:
        return Colors.green.shade100;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class CitizenReportDetailScreen extends StatelessWidget {
  final Report report;

  const CitizenReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final DatabaseService _databaseService = DatabaseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                    _buildDetailRow(
                      'Severity',
                      report.severity.name.toUpperCase(),
                    ),
                    _buildDetailRow(
                      'Damage Type',
                      report.damageType.name.toUpperCase(),
                    ),
                    _buildDetailRow('Status', report.status.name.toUpperCase()),
                    _buildDetailRow('Location', report.location),
                    const SizedBox(height: 8),
                    Text(
                      'Description:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(report.description),
                    if (report.imageUrl != null &&
                        report.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Before Image:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Update history
            Text(
              'Status Updates',
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
                      child: Text(
                        'No updates yet. Your report is being reviewed.',
                      ),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            if (update.workerName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Updated by: ${update.workerName}',
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
                                  _showAfterImage(
                                    context,
                                    update.afterImageUrl!,
                                  );
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
            Flexible(child: Image.network(imageUrl)),
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
