# Foldaway 菜单栏模板图

这套素材由 AppKit `NSBezierPath` 确定性绘制。9 帧的底座、铰链、画布与线宽完全一致；只有屏幕围绕左侧铰链旋转。角度依次为 **100°、87.5°、75°、62.5°、50°、37.5°、25°、12.5°、0°**。最后一帧的屏幕与底座完全重合，成为单条圆头薄板。

| 文件 | 用途 |
| --- | --- |
| `frames-512/frame-01…09.png` | 9 张 512×512 透明 PNG 原图 |
| `frames-512/frame-01…09.svg` | 对应矢量帧，统一 24 px 圆头、圆角描边 |
| `menu-fold-sprite-4608x512.png` | 9 帧水平精灵图，无间隔，透明背景 |
| `menu-fold-sprite-4608x512.svg` | 精灵图的矢量版本 |
| `menu-18pt/frame-01…09.png` | 菜单栏用 18×18 px，固定裁切缩放以改善小尺寸辨识 |
| `menu-18pt/frame-01…09@2x.png` | 菜单栏用 36×36 px，逻辑尺寸 18 pt |
| `FoldawayMenuIcon.swift` | 可复用 AppKit 渲染器，支持任意实时角度 |
| `manifest.json` | 角度、文件名、精灵图切片位置和几何参数 |
| `previews/contact-sheet.png` | 带浅灰背景和角度标注的预览，不能作模板图 |
| `previews/fold-animation.gif` | 合盖／开盖循环预览，不能作模板图 |

所有生产 PNG 的 RGB 都是纯黑 `#000000`，抗锯齿仅体现在 alpha。SVG 中没有背景、文字、阴影或灰色填充。透明像素的 RGB 同样为黑色。预览文件例外，已单独放入 `previews/`。

## 接入

将 `FoldawayMenuIcon.swift` 加入应用 target 后，可以替代当前 `laptopcomputer` 图标：

```swift
statusItem.button?.image = FoldawayMenuIcon.image(lidAngleDegrees: 100)
```

实时联动时，在现有角度更新回调中使用：

```swift
statusItem.button?.image = FoldawayMenuIcon.image(lidAngleDegrees: angle)
```

返回的 `NSImage` 已设置 `isTemplate = true`，由 macOS 决定实际颜色；默认逻辑尺寸为 18×18 pt。角度在 0…100° 之间连续绘制，不局限于 9 帧；超过范围的读数会限幅，`nil`、NaN 和无限值显示 100° 的打开姿态。

若直接载入 PNG，也要设置模板属性和逻辑尺寸：

```swift
image.size = NSSize(width: 18, height: 18)
image.isTemplate = true
```

主素材保留 512×512 的宽松留白。菜单栏导出对所有帧统一使用 `64 64 384 384` 的固定窗口，并将底座基线固定对齐像素，不会随角度移动或缩放底座；18 pt 下的笔画宽度为 1.125 pt。闭合时底座仍留在相同基线上。

## 重新生成

在仓库根目录运行：

```sh
swiftc resources/branding-v1/menu-bar/FoldawayMenuIcon.swift scripts/make-menu-icons.swift -o /tmp/foldaway-make-menu-icons
/tmp/foldaway-make-menu-icons
```

也可以将输出目录作为第二条命令的第一个参数。此生成流程独立于现有 App 图标构建流程；没有修改应用代码、现有图标或 `scripts/build.sh`。
