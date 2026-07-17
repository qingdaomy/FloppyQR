# FloppyQR

将 Web 应用打包为两张 PNG 图片，扫码即可离线运行。

## 使用方式

```bash
# 启动图形界面
FloppyQR

# 命令行生成
FloppyQR -i ./index.html -n "MyApp" -d "Developer"
FloppyQR -i ./project-dir -n "Game" -v "1.0" -d "Qingdaomy" -c ./icon.png -s
```

## 输出

| 文件 | 说明 |
|------|------|
| `QRboot_名称_版本_开发者_ID.png` | 启动二维码 |
| `Floppy_名称_版本_开发者_ID.png` | 数据盘 |

## 如何工作

1. 扫码 QRboot → 浏览器打开加载页
2. 选择 Floppy PNG → `DecompressionStream` 解压
3. 渲染 `index.html`，完全离线运行

## 构建

```bash
cd FloppyQR
xcodegen generate
open FloppyQR.xcodeproj
# ⌘B
```

## License

MIT
