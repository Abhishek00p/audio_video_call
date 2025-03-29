import 'package:agora_poc/controllers/auth_controller.dart';
import 'package:agora_poc/meeting_main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';
import '../services/meeting_service.dart';

class CreateCallDialog extends StatefulWidget {
  const CreateCallDialog({super.key});

  @override
  State<CreateCallDialog> createState() => _CreateCallDialogState();
}

class _CreateCallDialogState extends State<CreateCallDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();

  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _endTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before start date, update it
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // If start and end dates are the same, ensure end time is after start time
        if (_startDate.year == _endDate.year &&
            _startDate.month == _endDate.month &&
            _startDate.day == _endDate.day &&
            _endTime.hour < _startTime.hour) {
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _createCall() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduledStartTime = _combineDateTime(_startDate, _startTime);
    final scheduledEndTime = _combineDateTime(_endDate, _endTime);

    // Validate time range
    if (scheduledEndTime.isBefore(scheduledStartTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final meetingService = Provider.of<MeetingService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null || !user.isMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only members can create calls')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final call = await meetingService.createCall(
        user,
        _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: scheduledStartTime,
        endTime: scheduledEndTime,
      );

      if (call != null) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close dialog

        // Navigate to call screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => CallScreen(call: call)));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create call')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Create New Meeting'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Title',
                  hintText: 'Enter a title for your meeting',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter meeting details',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Date and time pickers
              Text(
                'Meeting Time',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Start date and time
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      ),
                      onPressed: () => _selectStartDate(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                      ),
                      onPressed: () => _selectStartTime(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Text('to'),
              const SizedBox(height: 8),

              // End date and time
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      ),
                      onPressed: () => _selectEndDate(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                      ),
                      onPressed: () => _selectEndTime(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Duration indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timelapse,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${_getDurationText()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCall,
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Create Meeting'),
        ),
      ],
    );
  }

  String _getDurationText() {
    final start = _combineDateTime(_startDate, _startTime);
    final end = _combineDateTime(_endDate, _endTime);
    final duration = end.difference(start);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}
