# Foldaway

合上 MacBook 盖子时，屏幕内容像 iPhone Duo 的折叠动画那样，从铰链远端开始逐渐变糊、变暗；打开盖子即恢复。
菜单栏常驻，零延迟，不需要任何系统权限。Mac 本身就是那台"折叠机"。界面中英文，跟随系统语言。

## 要求

- 带开合角传感器的 MacBook：2019 款 16 英寸起的 MacBook Pro、M2 起的 MacBook Air
- macOS 14 或更新；在 macOS 26.6 / M4 MacBook Pro 14 英寸上验证
- 构建需要 Xcode 26；`xcodegen` 可选，仓库已带生成好的 `Foldaway.xcodeproj`

## 安装

1. 从 GitHub Releases 下载 `Foldaway-x.y.z.dmg`，打开后把 Foldaway 拖到 Applications。
2. 首次打开会被 Gatekeeper 拦下（app 没有经过 Apple 公证）：到"系统设置 → 隐私与安全性"最下方点"仍要打开"。
   或者在终端执行 `xattr -d com.apple.quarantine /Applications/Foldaway.app` 后再打开。
3. 菜单栏出现笔记本图标即运行成功。

## 构建

```sh
scripts/build.sh              # 产出 build/Foldaway.app（Universal，ad-hoc 签名）
scripts/build.sh --install    # 再拷到 /Applications 并启动
scripts/make-dmg.sh           # 产出 build/Foldaway-x.y.z.dmg（拖拽安装窗口）
swift test --package-path FoldawayCore   # 曲线、平滑、预览、设置的单元测试
```

也可以直接用 Xcode 打开 `Foldaway.xcodeproj` 运行。`project.yml` 是工程源，改过后用 `xcodegen generate` 重新生成。

GitHub Actions 在每次推送时编译并上传 DMG 产物；推送 `v*` 标签会自动创建 Release 并附上 DMG。

## 使用

菜单栏的笔记本图标：

- **Lid angle**：当前开合角
- **Enabled**：总开关
- **Preview Fold**：不合盖也能看一遍完整效果（1.4 s 合上、停 0.6 s、1.4 s 打开）
- **Start Angle / End Angle**：开始变糊与完全变糊的角度，默认 85° / 15°
- **Blur Strength**：远端最大模糊半径，默认 48 pt
- **Launch at Login**

调试参数：`--motion 0.6` 固定进度、`--preview` 启动即播放、`--log-angle` 每秒打印角度。

## 原理

- 角度：IOKit HID 读 Apple 传感器（VID 0x05AC / PID 0x8104，UsagePage 0x20 / Usage 0x8A）的 Feature Report；
  空闲 20 Hz 轮询，效果进行中按显示刷新率读取，整数度数经指数平滑后插值。
- 画面：一个透明覆盖窗盖住内建显示器，CoreAnimation 的 `CABackdropLayer` + `variableBlur` 滤镜对窗后内容做
  渐变模糊（铰链处清晰、远端最糊），再叠一层渐变压暗。曲线沿用 iphone-duo 参考：
  `radius = R · motion · edge^1.35`，`darken = min(1, 2 · motion · ((edge − 0.2) / 0.8)^1.35)`，`motion = smoothstep(progress)`。
- 这两个 CoreAnimation 类是私有 API，仅通过类名字符串和 KVC 调用，不能上 App Store。
  将来 macOS 大版本升级如果失效，菜单会提示"只剩压暗"。

## 致谢

- [samhenrigold/LidAngleSensor](https://github.com/samhenrigold/LidAngleSensor)（Apache-2.0）：传感器读取方法
- [chuspeeism/iphone-duo](https://github.com/chuspeeism/iphone-duo)（MIT）：折叠模糊与压暗曲线
