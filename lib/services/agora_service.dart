import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  // Agora SDK credentials
  static const String appId = '<YOUR_AGORA_APP_ID>'; // Replace with your app ID
  static const int maxParticipants = 45;

  // RTC engine instance
  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  // Call state
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isInCall = false;
  bool get isInCall => _isInCall;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // User state
  int? _localUid;
  int? get localUid => _localUid;

  final Set<int> _remoteUids = {};
  Set<int> get remoteUids => _remoteUids;

  final Map<int, bool> _userMuteState = {};
  Map<int, bool> get userMuteState => _userMuteState;

  // Event controllers
  final _onJoinController = StreamController<int>.broadcast();
  Stream<int> get onJoin => _onJoinController.stream;

  final _onLeaveController = StreamController<void>.broadcast();
  Stream<void> get onLeave => _onLeaveController.stream;

  final _onUserJoinedController = StreamController<int>.broadcast();
  Stream<int> get onUserJoined => _onUserJoinedController.stream;

  final _onUserLeftController = StreamController<int>.broadcast();
  Stream<int> get onUserLeft => _onUserLeftController.stream;

  final _onErrorController = StreamController<String>.broadcast();
  Stream<String> get onError => _onErrorController.stream;

  // Initialize the Agora engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Create the engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Local user ${connection.localUid} joined the channel');
            _isInCall = true;
            _localUid = connection.localUid;
            // Always use 0 as a safe value if null
            _onJoinController.add(0);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('Local user left the channel');
            _isInCall = false;
            _localUid = null;
            _remoteUids.clear();
            _userMuteState.clear();
            _onLeaveController.add(null);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user $remoteUid joined the channel');
            _remoteUids.add(remoteUid);
            _userMuteState[remoteUid] = false; // Default to unmuted
            _onUserJoinedController.add(remoteUid);
          },
          onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
          ) {
            debugPrint('Remote user $remoteUid left the channel');
            _remoteUids.remove(remoteUid);
            _userMuteState.remove(remoteUid);
            _onUserLeftController.add(remoteUid);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('Error: $err - $msg');
            _onErrorController.add('Error: $msg');
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('Token will expire soon');
            // In a real app, implement token refresh here
          },
          onUserMuteAudio: (
            RtcConnection connection,
            int remoteUid,
            bool muted,
          ) {
            debugPrint(
              'Remote user $remoteUid ${muted ? 'muted' : 'unmuted'} audio',
            );
            _userMuteState[remoteUid] = muted;
          },
        ),
      );

      _isInitialized = true;
      debugPrint('Agora engine initialized');
    } catch (e) {
      debugPrint('Error initializing Agora engine: $e');
      _onErrorController.add('Failed to initialize: $e');
      throw Exception('Failed to initialize Agora engine: $e');
    }
  }

  // Join a call channel
  Future<void> joinCall(String channelId, String token) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInCall) {
      await leaveCall();
    }

    try {
      // Set client role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Enable audio
      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // Set audio parameters for optimal voice call
      await _engine!.setParameters('{"che.audio.custom_bitrate": 48000}');

      // Join the channel
      await _engine!.joinChannel(
        token: token.isEmpty ? '' : token,
        channelId: channelId,
        uid: 0, // 0 means let the SDK assign a uid
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );

      debugPrint('Joined channel: $channelId');
    } catch (e) {
      debugPrint('Error joining channel: $e');
      _onErrorController.add('Failed to join call: $e');
      throw Exception('Failed to join call: $e');
    }
  }

  // Leave the call channel
  Future<void> leaveCall() async {
    if (!_isInCall || _engine == null) return;

    try {
      // Stop recording if active
      if (_isRecording) {
        await stopRecording();
      }

      // Leave the channel
      await _engine!.leaveChannel();

      debugPrint('Left the channel');
    } catch (e) {
      debugPrint('Error leaving channel: $e');
      _onErrorController.add('Failed to leave call: $e');
    }
  }

  // Mute/unmute local audio
  Future<void> toggleMute() async {
    if (!_isInCall || _engine == null) return;

    try {
      await _engine!.enableLocalAudio(false);
      debugPrint('Local audio toggled');
    } catch (e) {
      debugPrint('Error toggling mute: $e');
      _onErrorController.add('Failed to toggle mute: $e');
      throw Exception('Failed to toggle mute: $e');
    }
  }

  // Mute a specific remote user (host only)
  Future<void> muteRemoteUser(int uid, bool mute) async {
    if (!_isInCall || _engine == null) return;

    try {
      // In Agora, a host cannot directly mute others
      // Instead, we would send a custom message to the remote user to mute themselves
      // For this POC, we'll just update the UI state locally
      _userMuteState[uid] = mute;

      // In a real app, you would send a signal to the remote user
      // await _engine!.sendStreamMessage(...)

      debugPrint('Remote user $uid ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      debugPrint('Error muting remote user: $e');
      _onErrorController.add('Failed to mute remote user: $e');
    }
  }

  // Start call recording (host only)
  Future<void> startRecording(String channelId, String uid) async {
    if (!_isInCall || _engine == null) return;

    // In a real app, this would involve your server to start cloud recording
    // For this POC, we'll just simulate recording state
    try {
      // Simulate API call to start recording
      await Future.delayed(const Duration(seconds: 1));

      _isRecording = true;
      debugPrint('Started recording call');
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _onErrorController.add('Failed to start recording: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  // Stop call recording
  Future<void> stopRecording() async {
    if (!_isRecording || _engine == null) return;

    // In a real app, this would involve your server to stop cloud recording
    // For this POC, we'll just simulate recording state
    try {
      // Simulate API call to stop recording
      await Future.delayed(const Duration(seconds: 1));

      _isRecording = false;
      debugPrint('Stopped recording call');
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _onErrorController.add('Failed to stop recording: $e');
      throw Exception('Failed to stop recording: $e');
    }
  }

  // Create a private 1-1 room (host only)
  Future<String?> createPrivateRoom(int remoteUid) async {
    if (!_isInCall || _engine == null) return null;

    // In a real app, this would create a new channel and invite the user
    // For this POC, we'll just generate a channel ID
    try {
      final privateChannelId =
          'private_${DateTime.now().millisecondsSinceEpoch}_$remoteUid';

      // In a real app, you would invite the remote user to this channel
      // and handle joining/leaving logic

      debugPrint('Created private room: $privateChannelId');
      return privateChannelId;
    } catch (e) {
      debugPrint('Error creating private room: $e');
      _onErrorController.add('Failed to create private room: $e');
      return null;
    }
  }

  // Extend call duration (host only)
  Future<bool> extendCallDuration() async {
    // This would involve updating the call end time on your server
    // For this POC, we'll just return success
    return true;
  }

  // Request permissions for microphone
  Future<void> _requestPermissions() async {
    if (kIsWeb) return; // Web doesn't need explicit permissions

    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }
    }
  }

  // Dispose
  void dispose() async {
    if (_isInCall) {
      await leaveCall();
    }

    if (_engine != null) {
      await _engine!.release();
      _engine = null;
    }

    _isInitialized = false;

    _onJoinController.close();
    _onLeaveController.close();
    _onUserJoinedController.close();
    _onUserLeftController.close();
    _onErrorController.close();
  }
}
