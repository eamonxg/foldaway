# Foldaway 设计规格（2026-09-11）

## 目标

一个 macOS 菜单栏小工具：合上 MacBook 盖子时，内建屏幕上的真实内容像 iPhone Duo 折叠动画那样，
从铰链远端开始逐渐变糊、变暗；打开盖子则反向恢复。Mac 本身就是那台"折叠机"。

不进 App Store，只要能本机编译、正常安装运行。核心要求：折叠动画必须优雅（连续、无跳变、无接缝、无延迟）。

## 参考即规格

1. 视频：apple.com/iphone-duo 折叠滑块（微信视频 `9e58edc686de93f05ee7723872f97965_raw.mp4`）。
2. 曲线：chuspeeism/iphone-duo（MIT）`main.js` 的 screenShader：
   - `motion = smoothstep(progress)`
   - `edge` = 距铰链的归一化距离，铰链处 0，远端 1
   - 模糊半径 `radius = R_max · motion · edge^1.35`
   - 压暗 `alpha = min(1, 2 · motion · clamp((edge − 0.2)/0.8)^1.35)`，即"两倍过渡强度，封顶纯黑"
   - 预览动画：1.4 s smoothstep 过渡
3. 传感器读法：samhenrigold/LidAngleSensor（Apache-2.0）。

## 已实测的技术前提（本机 Mac16,1，macOS 26.6.2）

- 开合角：IOKit HID，VID 0x05AC / PID 0x8104，PrimaryUsagePage 0x20 / Usage 0x8A，Feature Report #1，
  角度 = 字节 1–2 小端 uint16，整数度数，合上≈0°，全开≈130°，当前 98°。无权限弹窗。
- 渲染：私有 `CABackdropLayer` + `CAFilter(variableBlur)`（`inputRadius` + `inputMaskImage` alpha 遮罩）
  能对覆盖窗**后面的所有窗口**做渐变模糊；由 WindowServer 合成，零延迟，不需要录屏权限。
  遮罩 CG 坐标 y=0 对应图层底部。
- 备选（已验证但不采用）：`CGSSetWindowBackgroundBlurRadius` 只能整窗统一模糊，半径上限约 60；
  ScreenCaptureKit + 自绘需要录屏权限且多一帧延迟。

## 行为

- 角度 → 进度：`progress = (startAngle − angle) / (startAngle − endAngle)`，`motion = smoothstep(progress)`。
  默认 startAngle 85°，endAngle 15°；两者可调，至少相差 15°。
- 屏幕上的 `edge = y / height`，铰链在底部（edge 0），顶部 edge 1。
- 模糊：variableBlur 的遮罩 alpha 固定为 `edge^1.35`，每帧只改 `inputRadius = R_max · motion`；R_max 默认 48 pt，可调 8–80。
- 压暗：一层 `CAGradientLayer`，33 个色标，黑色 alpha 按上面公式随 motion 重算。
- 平滑：传感器是整数度数，用指数平滑（时间常数 0.12 s）在显示刷新率（CADisplayLink，ProMotion 120 Hz）上插值。
- 休眠功耗：motion 为 0 且平滑收敛后隐藏覆盖窗、暂停 display link；空闲时传感器 20 Hz 轮询。
- 覆盖窗：只盖内建显示器（`CGDisplayIsBuiltin`），无边框、透明、不接收鼠标、层级高于菜单栏、
  跟随所有 Space 与全屏 App，显示器配置变化时重建。
- 预览：菜单"Preview Fold"按参考时序播放：1.4 s 合上 → 停 0.6 s → 1.4 s 打开，走同一条角度→motion 管线；不受 Enabled 总开关影响。
- 传感器缺失：菜单显示"Lid angle sensor not found"，预览仍可用。私有模糊类缺失：只保留压暗并在菜单提示。
- 菜单：角度读数、Enabled、Preview Fold、Start Angle / End Angle / Blur Strength 三个滑块、Launch at Login、Quit。
  设置存 UserDefaults。界面文案通过 String Catalog 提供英文与简体中文，跟随系统语言。
- 分发：`scripts/make-dmg.sh` 打出拖拽安装 DMG；GitHub Actions 在 macOS runner 上测试、编译、打包，`v*` 标签自动发 Release。
- 调试参数：`--motion <0..1>` 固定 motion；`--preview` 启动即播放；`--log-angle` 每秒打印角度。

## 组件

| 单元 | 职责 | 依赖 |
|---|---|---|
| `FoldawayCore`（SwiftPM，纯 Foundation，可单测） | `FoldCurve` 曲线、`AngleSmoother` 平滑、`FoldPreview` 预览时序、`FoldSettings` 设置与持久化 | 无 |
| `LidAngleSensor` | HID 探测、打开、读角度，失败 2 s 后重新探测 | IOKit |
| `FoldOverlayWindow` | 覆盖窗属性 | AppKit |
| `FoldMask` / `FoldLayer` | 遮罩图、backdrop + variableBlur + 压暗渐变，`apply(motion:maxRadius:)` | QuartzCore、FoldawayCore |
| `FoldController` | 轮询、display link、平滑、预览、显示/隐藏窗、显示器变化 | 以上全部 |
| `StatusMenuController` / `SliderMenuItem` | 菜单栏 UI、设置写回、登录启动 | AppKit、ServiceManagement |
| `AppDelegate` | 装配、调试参数 | — |

工程：`foldaway/project.yml`（xcodegen）生成 `Foldaway.xcodeproj`，App target 依赖本地包 `FoldawayCore`；
`scripts/build.sh` 产出 `build/Foldaway.app`，`--install` 拷到 /Applications。
签名：ad-hoc（命令行下 Automatic 找不到带私钥的证书）；不沙盒、不需要任何 TCC 权限。最低 macOS 14。

## 错误处理

- HID 打开/读取失败：返回 nil，连续失败 120 次（约 2 s）后重新探测；角度为 nil 时 motion 为 0。
- 找不到内建显示器（合盖外接模式）：不建窗，等待显示器配置通知。
- 私有类不可用：`FoldLayer.isBlurSupported == false`，只做压暗。
- Launch at Login 失败：控制台记录，菜单状态如实显示。

## 测试

- `FoldawayCore` 用 XCTest 覆盖曲线端点/中点、平滑收敛与吸附、预览时序、设置裁剪与持久化。
- App 层手动验证（截图用 ScreenCaptureKit，`screencapture` 在本机返回黑帧）：`--motion 0.6` 全屏截图看菜单栏是否被盖住、顶部糊底部清；`--preview` 分时截图；
  把 startAngle 临时调到 125° 用真实传感器走一遍；空闲时确认窗已隐藏、进程 CPU 归零。
