import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoConference extends StatefulWidget {
  final String channelName;
  final String token;
  final String appId;

  const VideoConference({
    Key? key,
    required this.channelName,
    required this.token,
    required this.appId,
  }) : super(key: key);

  @override
  State<VideoConference> createState() => _VideoConferenceState();
}

class _VideoConferenceState extends State<VideoConference> {
  late RtcEngine _engine;
  int? _remoteUid; // Stores the UID of the remote user
  bool _localUserJoined = false; // Flag to track if local user joined
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void dispose() {
    _disposeAgora();
    super.dispose();
  }

  Future<void> _initAgora() async {
    // Request permissions
    await _handlePermissions();

    // Create RtcEngine instance
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: widget.appId,
      // You can add more configurations here, e.g., channelProfile, clientRole
    ));

    // Enable video
    await _engine.enableVideo();

    // Set up event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user $remoteUid left channel, reason: $reason");
          setState(() {
            _remoteUid = null; // Clear remote user
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("Local user left channel");
          setState(() {
            _localUserJoined = false;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          // Handle token expiration, e.g., generate a new token and call renewToken
          debugPrint('Token expiring soon: $token');
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Error: $err, Message: $msg");
          // Handle specific errors, e.g., show a toast message
        },
      ),
    );

    // Join the channel
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0, // Use 0 for dynamic UID assignment by Agora
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _handlePermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  Future<void> _disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  // --- UI Control Methods ---
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _engine.muteLocalVideoStream(_isVideoOff);
  }

  void _switchCamera() {
    _engine.switchCamera();
  }

  void _endCall() {
    Navigator.pop(context); // Go back to the previous screen
  }

  // --- Render Video Widgets ---
  Widget _localVideo() {
    if (_localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0), // Local user UID is 0
        ),
      );
    } else {
      return const Center(child: Text('Joining Channel...'));
    }
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: VideoCanvas(
              uid:
                  _remoteUid!), // Remote user UID. Use ! because we've checked _remoteUid != null
        ),
      );
    } else {
      return const Center(child: Text('Waiting for remote user...'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Conference'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main display for remote user or local if no remote
          Center(
            child: _remoteVideo(),
          ),
          // Small display for local user (picture-in-picture style)
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: _localVideo(),
              ),
            ),
          ),
          // Control Buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'muteBtn',
                    onPressed: _toggleMute,
                    child: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  ),
                  FloatingActionButton(
                    heroTag: 'videoBtn',
                    onPressed: _toggleVideo,
                    child:
                        Icon(_isVideoOff ? Icons.videocam_off : Icons.videocam),
                  ),
                  FloatingActionButton(
                    heroTag: 'switchCameraBtn',
                    onPressed: _switchCamera,
                    child: const Icon(Icons.switch_camera),
                  ),
                  FloatingActionButton(
                    heroTag: 'endCallBtn',
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
