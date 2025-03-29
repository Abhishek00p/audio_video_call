import 'package:agora_poc/controllers/auth_controller.dart';
import 'package:agora_poc/meeting_main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/join_request_model.dart';
import '../services/meeting_service.dart';

class JoinCallDialog extends StatefulWidget {
  const JoinCallDialog({super.key});

  @override
  State<JoinCallDialog> createState() => _JoinCallDialogState();
}

class _JoinCallDialogState extends State<JoinCallDialog> {
  final _formKey = GlobalKey<FormState>();
  final _callIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _callIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _joinCall() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final callId = _callIdController.text.trim().toUpperCase();
    final password = _passwordController.text.trim();

    final authService = Provider.of<AuthService>(context, listen: false);
    final meetingService = Provider.of<MeetingService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to join a call')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Check if call exists and password is correct
      final isValid = meetingService.validateCallCredentials(callId, password);
      if (!isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid call ID or password')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // If user is a member and is the host, they can directly join
      final call = meetingService.getCallById(callId);
      if (call != null && user.isMember && call.hostId == user.id) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close dialog

        // Navigate to call screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => CallScreen(call: call)));
        return;
      }

      // Otherwise, create a join request
      final request = await meetingService.requestToJoinCall(
        callId,
        password,
        user,
      );

      if (request != null) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close dialog

        // Show pending request dialog
        _showPendingRequestDialog(request);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join call. It may be full or inactive.'),
          ),
        );
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

  void _showPendingRequestDialog(JoinRequest request) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.hourglass_top, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Request Pending'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your request to join the meeting has been sent to the host.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please wait for the host to approve your request.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // In a real app, we would poll for request status changes
                // For this demo, add a note about the simulated approval
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Demo App Note',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For this demo, your request will be automatically approved in 5 seconds.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel Request'),
              ),
            ],
          ),
    );

    // In a real app, we would listen for request status updates
    // For this demo, auto-approve after a delay
    Future.delayed(const Duration(seconds: 5), () {
      // Close the pending dialog
      Navigator.of(context).pop();

      // Get the call
      final meetingService = Provider.of<MeetingService>(
        context,
        listen: false,
      );
      final call = meetingService.getCallById(request.callId);

      // Add the user to participants (simulating approval)
      if (call != null) {
        // Navigate to call screen
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => CallScreen(call: call)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.login, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Join Meeting'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Call ID field
            TextFormField(
              controller: _callIdController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Meeting ID',
                hintText: 'Enter the 6-character meeting ID',
                prefixIcon: Icon(
                  Icons.meeting_room_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the meeting ID';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Meeting Password',
                hintText: 'Enter the meeting password',
                prefixIcon: Icon(
                  Icons.password_outlined,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the meeting password';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Helper text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Meeting ID and password should be provided by the meeting host.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Demo hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Demo App',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For testing, use ID: ABC123 and Password: demo123',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _joinCall,
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
                  : const Text('Join'),
        ),
      ],
    );
  }
}
