import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/report.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../auth/role_selection_screen.dart';
import 'worker_task_detail.dart';

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({super.key});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedFilter = 'all'; // 'all', 'assigned', 'inProgress', 'completed'

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
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

              if (shouldLogout == true && mounted) {
                await authService.signOut();
                if (mounted) {
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
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Filter: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All Tasks'),
                        const SizedBox(width: 8),
                        _buildFilterChip('assigned', 'Assigned'),
                        const SizedBox(width: 8),
                        _buildFilterChip('inProgress', 'In Progress'),
                        const SizedBox(width: 8),
                        _buildFilterChip('completed', 'Completed'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reports list
          Expanded(
            child: _buildReportsList(user.id),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.orange.shade100,
      checkmarkColor: Colors.orange,
    );
  }

  Widget _buildReportsList(String workerId) {
    return StreamBuilder<List<Report>>(
      stream: _databaseService.streamWorkerReports(workerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final allReports = snapshot.data ?? [];
        
        // Filter reports based on selected filter
        final filteredReports = allReports.where((report) {
          switch (_selectedFilter) {
            case 'assigned':
              return report.status == ReportStatus.assigned;
            case 'inProgress':
              return report.status == ReportStatus.inProgress;
            case 'completed':
              return report.status == ReportStatus.completed;
            default:
              return true; // 'all'
          }
        }).toList();

        if (filteredReports.isEmpty) {
          return Center(
            child: Text(
              _selectedFilter == 'all' 
                ? 'No tasks assigned yet' 
                : 'No ${_selectedFilter} tasks',
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredReports.length,
          itemBuilder: (context, index) {
            return _buildReportCard(filteredReports[index]);
          },
        );
      },
    );
  }

  Widget _buildReportCard(Report report) {
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
              builder: (context) => WorkerTaskDetailScreen(report: report),
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
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
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
}

