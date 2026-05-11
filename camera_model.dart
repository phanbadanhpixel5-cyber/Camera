import 'package:isar/isar.dart';

part 'camera_model.g.dart';

enum CameraType { yosee, hikvision, dahua, generic }

enum StreamQuality { main, sub }

@collection
class CameraModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  late String lanIp;
  String? wanIp;
  String? domain;

  late int rtspPort; // default: 554
  late int onvifPort; // default: 8000
  late String username;
  late String password;

  @Enumerated(EnumType.name)
  late CameraType type;

  @Enumerated(EnumType.name)
  late StreamQuality quality;

  String? customRtspPath; // nếu dùng generic

  bool isActive = true;
  DateTime createdAt = DateTime.now();

  // Tạo RTSP URL theo loại camera
  String buildRtspUrl({bool useLan = true}) {
    final host = useLan ? lanIp : (wanIp ?? domain ?? lanIp);
    final auth = '$username:$password';
    final port = rtspPort;

    switch (type) {
      case CameraType.hikvision:
        final ch = quality == StreamQuality.main ? '01' : '02';
        return 'rtsp://$auth@$host:$port/Streaming/Channels/$ch';

      case CameraType.dahua:
        final sub = quality == StreamQuality.main ? 0 : 1;
        return 'rtsp://$auth@$host:$port/cam/realmonitor?channel=1&subtype=$sub';

      case CameraType.yosee:
        return 'rtsp://$auth@$host:$port/live/main';

      case CameraType.generic:
        final path = customRtspPath ?? '/live/main';
        return 'rtsp://$auth@$host:$port$path';
    }
  }
}
