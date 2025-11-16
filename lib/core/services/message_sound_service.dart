import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 消息音效服务
class MessageSoundService {
  static final MessageSoundService _instance = MessageSoundService._internal();
  factory MessageSoundService() => _instance;
  
  MessageSoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true;

  /// 启用/禁用音效
  bool get isEnabled => _isEnabled;
  
  set isEnabled(bool value) {
    _isEnabled = value;
  }

  /// 播放新消息音效
  Future<void> playNewMessageSound() async {
    if (!_isEnabled) {
      return;
    }

    try {
      // 停止当前播放（如果有）
      await _audioPlayer.stop();
      
      // 播放新消息音效
      await _audioPlayer.play(AssetSource('sounds/mixkit-long-pop-2358.wav'));
    } catch (e) {
      debugPrint('播放新消息音效失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _audioPlayer.dispose();
  }
}

