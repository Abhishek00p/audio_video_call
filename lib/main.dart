// import 'package:agora_poc/controllers/app_video_controller.dart';
// import 'package:agora_poc/views/app_video_call_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:get/get.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   Get.put(VideoCallController());
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: VideoCallScreen(),
//     );
//   }
// }
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

String appId = dotenv.env['AGORA_APPID'] ?? '';
String token = dotenv.env['TOKEN'] ?? '';
const channel = "first_channel";

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late RtcEngine _engine;
  int? _remoteUid;
  bool _isSpeaking = false;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    await _requestPermissions();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
    _setupEventHandlers();
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone].request();
  }

  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (
          RtcConnection connection,
          int remoteUid,
          UserOfflineReasonType reason,
        ) {
          setState(() => _remoteUid = null);
        },
        onAudioVolumeIndication: (
          rtcConnection,
          List<AudioVolumeInfo> speakers,
          int totalVolume,
          _,
        ) {
          bool isSpeaking = speakers.any(
            (info) => info.uid == 0 && info.volume! > 0,
          );
          setState(() => _isSpeaking = isSpeaking);
        },
      ),
    );
  }

  Future<void> _joinChannel() async {
    await _engine.joinChannel(
      token: token,
      channelId: channel,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
    await _engine.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );
  }

  Future<void> _leaveChannel() async {
    await _engine.leaveChannel();
    setState(() {
      _isJoined = false;
      _remoteUid = null;
      _isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora Voice Call')),
      body: Center(
        child:
            _isJoined
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _remoteUid != null
                          ? "Remote user $_remoteUid joined"
                          : "Waiting for remote user...",
                    ),
                    const SizedBox(height: 20),
                    Text(_isSpeaking ? "You are speaking" : "You are silent"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _leaveChannel,
                      child: const Text("Leave Call"),
                    ),
                  ],
                )
                : ElevatedButton(
                  onPressed: _joinChannel,
                  child: const Text("Join Call"),
                ),
      ),
    );
  }
}
