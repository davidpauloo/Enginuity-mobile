import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chat_app/key.dart';
import 'package:http/http.dart' as http;

class AgoraVideoCallScreen extends StatefulWidget {
  // NOTE: callId is now technically redundant but kept for now.
  final String callId; 
  final String currentUserId;
  final String currentUserName;
  final String targetUserId;
  final String targetUserName;

  const AgoraVideoCallScreen({
    Key? key,
    required this.callId,
    required this.currentUserId,
    required this.currentUserName,
    required this.targetUserId,
    required this.targetUserName,
  }) : super(key: key);

  @override
  State<AgoraVideoCallScreen> createState() => _AgoraVideoCallScreenState();
}

class _AgoraVideoCallScreenState extends State<AgoraVideoCallScreen> {
  static const String appId = AGORA_APP_ID;

  late RtcEngine _engine;
  bool _isJoined = false;
  bool _isLoading = true;
  String? _error;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  final int _uid = 1001;
  
  // ⭐️ NEW: Function to generate the consistent channel ID
  String _getCanonicalChannelId() {
    // 1. Get first 8 chars of both IDs (matching backend logic)
    final id1 = widget.currentUserId.substring(0, 8);
    final id2 = widget.targetUserId.substring(0, 8);
    // 2. Sort them to ensure A_B is the same as B_A
    final sortedIds = [id1, id2]..sort();
    // 3. Create the final channel name
    return 'call_${sortedIds.join('_')}';
  }


  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      await _requestPermissions();

      final String channelId = _getCanonicalChannelId(); // ⭐️ USE CORRECT CHANNEL ID

      _engine = createAgoraRtcEngine();
      await _engine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (!mounted) return;
            debugPrint('MOBILE onJoinChannelSuccess channel=${connection.channelId} uid=${connection.localUid}');
            setState(() {
              _isJoined = true;
              _localUserJoined = true;
              _isLoading = false;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (!mounted) return;
            debugPrint('MOBILE onUserJoined remoteUid=$remoteUid');
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (!mounted) return;
            debugPrint('MOBILE onUserOffline remoteUid=$remoteUid reason=$reason');
            setState(() => _remoteUid = null);
          },
          onError: (ErrorCodeType err, String msg) {
            if (!mounted) return;
            debugPrint('MOBILE onError $err $msg');
            setState(() {
              _error = 'Error: $msg';
              _isLoading = false;
            });
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) async {
            try {
              // ⭐️ USE CORRECT CHANNEL ID
              final newToken = await _fetchRtcToken(channelId, _uid); 
              await _engine.renewToken(newToken);
              debugPrint('MOBILE token renewed');
            } catch (e) {
              debugPrint('MOBILE token renew failed: $e');
            }
          },
        ),
      );

      await _engine.enableVideo();
      await _engine.startPreview();

      // ⭐️ USE CORRECT CHANNEL ID for token fetch and channel join
      final token = await _fetchRtcToken(channelId, _uid);
      debugPrint('MOBILE joining channel=$channelId uid=$_uid');

      await _engine.joinChannel(
        token: token,
        channelId: channelId, // ⭐️ CORRECTED
        uid: _uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('MOBILE init error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String> _fetchRtcToken(String channelId, int uid) async {
    final url = Uri.parse('$BACKEND_URL/api/video/agora/token');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'channel': channelId,
        'uid': uid,
        'role': 'publisher',
        'expireSeconds': 3600,
      }),
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch RTC token (${resp.statusCode})');
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Empty token from backend');
    }
    return token;
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  void _onToggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _onToggleVideo() {
    setState(() => _isVideoEnabled = !_isVideoEnabled);
    _engine.enableLocalVideo(_isVideoEnabled);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  Future<void> _onCallEnd() async {
    await _engine.leaveChannel();
    await _engine.release();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    try { await _engine.leaveChannel(); } catch (_) {}
    try { await _engine.release(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text('Connecting to call...', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              const Text('Connection Error', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _localVideo(),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Call with ${widget.targetUserName}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Connected', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(icon: _isMuted ? Icons.mic_off : Icons.mic, backgroundColor: _isMuted ? Colors.red : Colors.white24, onPressed: _onToggleMute),
                const SizedBox(width: 20),
                _buildControlButton(icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off, backgroundColor: _isVideoEnabled ? Colors.white24 : Colors.red, onPressed: _onToggleVideo),
                const SizedBox(width: 20),
                _buildControlButton(icon: Icons.cameraswitch, backgroundColor: Colors.white24, onPressed: _onSwitchCamera),
                const SizedBox(width: 20),
                _buildControlButton(icon: Icons.call_end, backgroundColor: Colors.red, onPressed: _onCallEnd, isLarge: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({ required IconData icon, required Color backgroundColor, required VoidCallback onPressed, bool isLarge = false }) {
    final size = isLarge ? 65.0 : 55.0;
    final iconSize = isLarge ? 32.0 : 28.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: iconSize), onPressed: onPressed),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _getCanonicalChannelId()), // ⭐️ CORRECTED
        ),
      );
    } else {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text('Waiting for user to join...', style: TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      );
    }
  }

  Widget _localVideo() {
    if (_isJoined && _isVideoEnabled) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.videocam_off, color: Colors.white54, size: 40)),
      );
    }
  }
}