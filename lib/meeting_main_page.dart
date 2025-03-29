import 'dart:async';
import 'package:agora_poc/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_model.dart';
import '../models/join_request_model.dart';
import '../models/user_model.dart';
import '../services/agora_service.dart';
import '../services/meeting_service.dart';

class CallScreen extends StatefulWidget {
  final Call call;

  const CallScreen({super.key, required this.call});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late AgoraService _agoraService;
  bool _isInitializing = true;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isRecording = false;
  bool _isHost = false;
  final Set<int> _participants = {};
  final Map<int, String> _participantNames = {};
  final Map<int, bool> _participantMuteStatus = {};
  bool _showJoinRequests = false;
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _agoraService = AgoraService();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      _showErrorAndExit('User not authenticated');
      return;
    }

    // Check if user is host
    _isHost = widget.call.hostId == user.id;

    try {
      // Initialize Agora service
      await _agoraService.initialize();

      // Start the meeting if this is the host and the meeting is scheduled
      if (_isHost && widget.call.isScheduled) {
        final meetingService = Provider.of<MeetingService>(
          context,
          listen: false,
        );
        await meetingService.startCall(widget.call.id, user.id);
      }

      // Join the call channel
      // In a real app, you would get a token from your server
      await _agoraService.joinCall(widget.call.id, "");

      // Start duration timer
      _startDurationTimer();

      // Listen for participant events
      _setupListeners();

      setState(() {
        _isInitializing = false;
        _isJoined = true;
      });
    } catch (e) {
      _showErrorAndExit('Failed to join call: $e');
    }
  }

  void _setupListeners() {
    // User joined listener
    _agoraService.onUserJoined.listen((uid) {
      setState(() {
        _participants.add(uid);
        // In a real app, get user info from your backend
        _participantNames[uid] = 'User $uid';
        _participantMuteStatus[uid] = false;
      });
    });

    // User left listener
    _agoraService.onUserLeft.listen((uid) {
      setState(() {
        _participants.remove(uid);
        _participantNames.remove(uid);
        _participantMuteStatus.remove(uid);
      });
    });

    // Error listener
    _agoraService.onError.listen((error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error')));
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentDuration = Duration(seconds: _currentDuration.inSeconds + 1);
      });
    });
  }

  void _showErrorAndExit(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  Future<void> _toggleMute() async {
    try {
      await _agoraService.toggleMute();
      setState(() {
        _isMuted = !_isMuted;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to toggle mute: $e')));
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isHost) return;

    try {
      if (_isRecording) {
        await _agoraService.stopRecording();
      } else {
        await _agoraService.startRecording(
          widget.call.id,
          _agoraService.localUid.toString(),
        );
      }
      setState(() {
        _isRecording = !_isRecording;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to toggle recording: $e')));
    }
  }

  Future<void> _muteParticipant(int uid) async {
    if (!_isHost) return;

    try {
      await _agoraService.muteRemoteUser(uid, !_participantMuteStatus[uid]!);
      setState(() {
        _participantMuteStatus[uid] = !_participantMuteStatus[uid]!;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mute participant: $e')));
    }
  }

  Future<void> _createPrivateRoom(int uid) async {
    if (!_isHost) return;

    try {
      final privateRoomId = await _agoraService.createPrivateRoom(uid);
      if (privateRoomId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Private room created: $privateRoomId')),
        );
        // In a real app, invite the participant to this room
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create private room: $e')),
      );
    }
  }

  Future<void> _extendMeeting() async {
    if (!_isHost) return;

    try {
      final success = await _agoraService.extendCallDuration();
      if (success) {
        final meetingService = Provider.of<MeetingService>(
          context,
          listen: false,
        );
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;

        if (user != null) {
          await meetingService.extendCallDuration(
            widget.call.id,
            user.id,
            const Duration(minutes: 30),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meeting extended by 30 minutes')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to extend meeting: $e')));
    }
  }

  Future<void> _endCall() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    try {
      await _agoraService.leaveCall();

      // If host, end the meeting
      if (_isHost && user != null) {
        final meetingService = Provider.of<MeetingService>(
          context,
          listen: false,
        );
        await meetingService.endCall(widget.call.id, user.id);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error leaving call: $e')));
    }
  }

  void _toggleJoinRequests() {
    setState(() {
      _showJoinRequests = !_showJoinRequests;
    });
  }

  Future<void> _handleJoinRequest(JoinRequest request, bool approve) async {
    if (!_isHost) return;

    try {
      final meetingService = Provider.of<MeetingService>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user == null) return;

      if (approve) {
        await meetingService.approveJoinRequest(request.id, user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approved ${request.userDisplayName}.')),
        );
      } else {
        await meetingService.rejectJoinRequest(request.id, user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejected ${request.userDisplayName}.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error handling request: $e')));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _agoraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meetingService = Provider.of<MeetingService>(context);

    // Get pending join requests if host
    final List<JoinRequest> pendingRequests =
        _isHost ? meetingService.getPendingJoinRequests(widget.call.id) : [];

    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.call.title),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            if (_isHost && pendingRequests.isNotEmpty)
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: _toggleJoinRequests,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        pendingRequests.length.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        body:
            _isInitializing
                ? const Center(child: CircularProgressIndicator())
                : _showJoinRequests
                ? _buildJoinRequestsList(pendingRequests, theme)
                : _buildCallUI(theme),
        bottomNavigationBar: _isInitializing ? null : _buildCallControls(theme),
      ),
    );
  }

  Widget _buildCallUI(ThemeData theme) {
    return Column(
      children: [
        // Call info bar
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: theme.colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_currentDuration),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              if (_isRecording)
                Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recording',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Call ID & Password info
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onTertiaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meeting ID: ${widget.call.id}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    Text(
                      'Password: ${widget.call.password}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                color: theme.colorScheme.onTertiaryContainer,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meeting info copied to clipboard'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Main call area
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speaker section
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.mic, color: Colors.white, size: 50),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'You are ${_isMuted ? 'muted' : 'speaking'}',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _isHost ? 'Meeting Host' : 'Participant',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),

              // Participants section
              Text(
                'Participants (${_participants.length + 1})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Participants list
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Current user (you)
                    _buildParticipantItem(
                      'You',
                      _isMuted,
                      isLocalUser: true,
                      isHost: _isHost,
                    ),
                    // Other participants
                    ..._participants.map(
                      (uid) => _buildParticipantItem(
                        _participantNames[uid] ?? 'User $uid',
                        _participantMuteStatus[uid] ?? false,
                        uid: uid,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantItem(
    String name,
    bool isMuted, {
    int? uid,
    bool isLocalUser = false,
    bool isHost = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color:
                      isHost
                          ? theme.colorScheme.primary.withOpacity(0.2)
                          : theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isHost
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          isHost
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              // Mute indicator
              if (isMuted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mic_off, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          // Host label
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Host',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute/Unmute
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Unmute' : 'Mute',
                  onPressed: _toggleMute,
                  color: _isMuted ? Colors.red : theme.colorScheme.primary,
                ),
                // End Call
                _buildControlButton(
                  icon: Icons.call_end,
                  label: 'End',
                  onPressed: _endCall,
                  color: Colors.red,
                  isCallEnd: true,
                ),
                // Speaker
                _buildControlButton(
                  icon: Icons.volume_up,
                  label: 'Speaker',
                  onPressed: () {},
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            // Host controls
            if (_isHost) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Recording
                  _buildControlButton(
                    icon:
                        _isRecording
                            ? Icons.stop_circle
                            : Icons.fiber_manual_record,
                    label: _isRecording ? 'Stop Rec' : 'Record',
                    onPressed: _toggleRecording,
                    color:
                        _isRecording ? Colors.red : theme.colorScheme.primary,
                    mini: true,
                  ),
                  // Private Room
                  _buildControlButton(
                    icon: Icons.meeting_room,
                    label: 'Private',
                    onPressed: () {
                      if (_participants.isNotEmpty) {
                        _createPrivateRoom(_participants.first);
                      }
                    },
                    color: theme.colorScheme.primary,
                    mini: true,
                  ),
                  // Extend Time
                  _buildControlButton(
                    icon: Icons.update,
                    label: 'Extend',
                    onPressed: _extendMeeting,
                    color: theme.colorScheme.primary,
                    mini: true,
                  ),
                  // More Options
                  _buildControlButton(
                    icon: Icons.more_horiz,
                    label: 'More',
                    onPressed: () {},
                    color: theme.colorScheme.primary,
                    mini: true,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isCallEnd = false,
    bool mini = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: mini ? 40 : 50,
          height: mini ? 40 : 50,
          decoration: BoxDecoration(
            color: isCallEnd ? Colors.red : color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon),
            color: isCallEnd ? Colors.white : color,
            iconSize: mini ? 20 : 24,
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: mini ? 10 : 12)),
      ],
    );
  }

  Widget _buildJoinRequestsList(List<JoinRequest> requests, ThemeData theme) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_disabled,
              size: 64,
              color: theme.colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending join requests',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _toggleJoinRequests,
              child: const Text('Back to Call'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Join Requests',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withOpacity(0.1),
                            child: Text(
                              request.userDisplayName[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.userDisplayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Requested to join at ${request.requestTime.hour}:${request.requestTime.minute}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  () => _handleJoinRequest(request, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  () => _handleJoinRequest(request, true),
                              child: const Text('Admit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _toggleJoinRequests,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
