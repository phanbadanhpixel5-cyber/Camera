# IP Camera Viewer — Hướng dẫn cài đặt

## Yêu cầu
- Flutter 3.19+
- Android SDK 21+ (Android 5.0+)
- iOS 12+ (cần thêm VLC dependency vào Podfile)

---

## 1. Cài đặt dependencies

```bash
flutter pub get
```

## 2. Generate code (Isar + Riverpod)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Lệnh này tạo ra:
- `lib/models/camera_model.g.dart` — Isar schema
- Các file `.g.dart` cho Riverpod (nếu dùng `@riverpod` annotation)

## 3. Chạy app

```bash
flutter run
```

---

## Cấu trúc RTSP URL được tạo tự động

| Camera     | Main Stream URL |
|------------|-----------------|
| Hikvision  | `rtsp://user:pass@ip:554/Streaming/Channels/01` |
| Dahua      | `rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=0` |
| YoSee      | `rtsp://user:pass@ip:554/live/main` |
| Generic    | `rtsp://user:pass@ip:554/<custom_path>` |

---

## Tính năng

### Xem camera
- Nhấn **XEM** ở danh sách để thêm vào grid (tối đa 4)
- **Double tap** vào camera tile để fullscreen
- **Nhấn** vào màn hình fullscreen để hiện/ẩn controls

### Kết nối thông minh
- Tự động thử kết nối lại sau 5 giây khi mất stream
- Sau 3 lần thất bại với LAN IP → tự chuyển sang WAN IP
- Tối đa 10 lần reconnect trước khi báo lỗi

### Database
- Camera được lưu vào **Isar** (local, offline)
- Dữ liệu tồn tại qua các lần khởi động lại app

---

## Lưu ý Android

Trong `AndroidManifest.xml` đã bật `usesCleartextTraffic="true"` để cho phép kết nối
RTSP qua HTTP trên mạng LAN (các camera IP thường không dùng TLS).

## Lưu ý iOS

Thêm vào `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## Troubleshooting

| Vấn đề | Giải pháp |
|--------|-----------|
| Stream không hiện | Kiểm tra IP, port, username/password |
| Màn hình đen | Camera đang khởi động, chờ 10-15 giây |
| Test kết nối thành công nhưng không có video | Thử đổi Main/Sub stream |
| App crash khi build | Chạy `build_runner` để generate code |
