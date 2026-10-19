# NroHan iOS

Xcode project exported from Unity 2021.3.45f2. Build scheme: `Unity-iPhone`.

## Build IPA unsigned bằng Codemagic

1. Kết nối repository `AnhhPhuong06/NroHan` vào Codemagic dưới dạng iOS app.
2. Chọn nhánh chứa `codemagic.yaml`, nhấn **Check for configuration file**.
3. Chọn workflow **NroHan - Unsigned IPA** (`ios-unsigned`) rồi **Start new build**.
4. Khi build thành công, tải `NroHan-unsigned.ipa` trong **Artifacts**.

Workflow dùng Mac mini M2, Xcode 16.4, cấu hình Release cho thiết bị arm64;
tắt code signing và bitcode. Không cần certificate hoặc provisioning profile.
Thư viện `.a` được lưu bằng Git LFS và tải về trước khi build.

IPA được đóng gói từ app trong Xcode archive theo cấu trúc `Payload/*.app`.
File unsigned cần được ký trước khi cài lên iPhone thông thường.
Log build nằm tại `build/ios/logs/xcodebuild.log` và được lưu làm artifact.

## Build trên macOS

```sh
git lfs pull
bash scripts/build_unsigned_ipa.sh
```

Kết quả: `build/ios/ipa/NroHan-unsigned.ipa`.

Tài liệu: [Codemagic YAML](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
và [máy build Xcode 16.4](https://docs.codemagic.io/specs-macos/xcode-16-4/).
