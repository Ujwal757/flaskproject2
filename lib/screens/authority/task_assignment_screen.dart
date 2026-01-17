import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/database_service.dart';

class TaskAssignmentScreen extends StatefulWidget {
  final Report report;

  const TaskAssignmentScreen({super.key, required this.report});

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _selectedWorkerId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Task'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Severity', widget.report.severity.name.toUpperCase()),
                    _buildDetailRow('Damage Type', widget.report.damageType.name.toUpperCase()),
                    _buildDetailRow('Status', widget.report.status.name.toUpperCase()),
                    _buildDetailRow('Location', widget.report.location),
                    const SizedBox(height: 8),
                    Text(
                      'Description:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(widget.report.description),
                    if (widget.report.assignedWorkerId != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Assigned Worker',
                        widget.report.assignedWorkerId ?? 'None',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Worker selection
            Text(
              'Select Worker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _databaseService.streamWorkers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final workers = snapshot.data ?? [];
                if (workers.isEmpty) {
                  return const Text('No workers available');
                }

                return Column(
                  children: workers.map((worker) {
                    final workerId = worker['id'] as String;
                    final workerName = worker['name'] as String? ?? 'Unknown';
                    final isSelected = _selectedWorkerId == workerId;

                    return Card(
                      color: isSelected ? Colors.blue.shade50 : null,
                      child: RadioListTile<String>(
                        title: Text(workerName),
                        subtitle: Text(worker['email'] as String? ?? ''),
                        value: workerId,
                        groupValue: _selectedWorkerId,
                        onChanged: (value) {
                          setState(() {
                            _selectedWorkerId = value;
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Assign button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedWorkerId == null || _isLoading
                    ? null
                    : _assignTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Assign Task'),
              ),
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

  Future<void> _assignTask() async {
    if (_selectedWorkerId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.assignReportToWorker(
        widget.report.id,
        _selectedWorkerId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

