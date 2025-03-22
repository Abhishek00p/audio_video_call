import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallController extends GetxController {
  final String appId = "YOUR_AGORA_APP_ID";
  final String token = "YOUR_AGORA_TOKEN";
  final String channelName = "test_channel";

  late RtcEngine agoraEngine;
  var isJoined = false.obs;
  var remoteUid = Rx<int?>(null);
  var isMuted = false.obs;
  var isCameraOff = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeAgora();
  }

  Future<void> initializeAgora() async {
    await [Permission.microphone, Permission.camera].request();
    
    agoraEngine = createAgoraRtcEngine();
    await agoraEngine.initialize(RtcEngineContext(appId: appId));

    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          isJoined.value = true;
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          remoteUid.value = uid;
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          remoteUid.value = null;
        },
      ),
    );

    await agoraEngine.enableVideo();
  }

  Future<void> joinCall() async {
    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void leaveCall() async {
    await agoraEngine.leaveChannel();
    isJoined.value = false;
    remoteUid.value = null;
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    agoraEngine.muteLocalAudioStream(isMuted.value);
  }

  void toggleCamera() {
    isCameraOff.value = !isCameraOff.value;
    agoraEngine.muteLocalVideoStream(isCameraOff.value);
  }

  @override
  void onClose() {
    agoraEngine.release();
    super.onClose();
  }
}
