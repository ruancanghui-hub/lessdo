# LessDo 1.0 — App Store Connect 上传指南

本页把提交所需资料集中在一处。文案源文件见 `docs/app_store_connect/`。

## 1. 提交前自检

```bash
./tool/prepare_app_store_upload.sh
```

通过后再进行 Archive / Upload。

## 2. App Store Connect 创建应用

| 字段 | 值 |
|------|-----|
| 平台 | iOS |
| 名称 | LessDo |
| 主要语言 | English (U.S.) |
| Bundle ID | `com.ruancanghui.lessdo` |
| SKU | `lessdo-ios-1.0` |
| 用户访问权限 | 完全访问权限 |

## 3. 版本与构建

| 字段 | 当前值 |
|------|--------|
| 营销版本 | `1.0.0`（`pubspec.yaml`） |
| 构建号 | `1`（每次上传 App Store 前在 `pubspec.yaml` 递增 `+N`） |
| 最低系统 | iOS 16.0 |
| 设备 | iPhone + iPad |

上传构建（需 Apple Developer 签名）：

```bash
open ios/Runner.xcworkspace
```

1. Scheme: **Runner**，Destination: **Any iOS Device**
2. **Product → Archive**
3. **Distribute App → App Store Connect → Upload**
4. 加密合规：选 **None of the algorithms mentioned**（无自定义加密）

或使用 Transporter 上传 `.ipa`。

## 4. 元数据（复制粘贴）

| 语言 | 文件 |
|------|------|
| English (U.S.) | `docs/app_store_connect/en-US.txt` |
| 简体中文 | `docs/app_store_connect/zh-Hans.txt` |
| 审核备注 | `docs/app_store_connect/review-notes.txt` |

完整说明与截图计划见 `docs/APP_STORE_METADATA.md`。

### 必填 URL

- 隐私政策：`https://ruancanghui-hub.github.io/lessdo/privacy.html`
- 支持：`https://ruancanghui-hub.github.io/lessdo/support.html`
- 支持邮箱：`lessdo.support@nightelf.dev`

## 5. App 隐私

- **是否从此 App 收集数据？** → **否**
- **是否用于跟踪？** → **否**
- 隐私政策 URL：同上

## 6. 年龄分级

 violence / sexual / profanity / drugs / gambling / horror / medical /
 unrestricted web / messaging / UGC / ads / age assurance → 全部 **无 / 否**。

预期 **4+**（以 Connect 计算结果为准）。

## 7. 截图清单

每种语言各 1–10 张，使用 **最终 TestFlight 构建** 的真机/模拟器 UI：

| # | 设备尺寸 | 内容 |
|---|----------|------|
| 1 | iPhone 6.9" | Today + 快速添加 |
| 2 | iPhone 6.9" | 清单 / 购物清单 |
| 3 | iPhone 6.9" | 任务详情 + 本地提醒 |
| 4 | iPhone 6.9" | 专注计时 |
| 5 | iPhone 6.9" | 设置（隐私与外观） |
| 6 | iPad 13" | 侧栏自适应布局 |

截图目录（上传前放入）：`docs/app_store_connect/screenshots/`

```bash
mkdir -p docs/app_store_connect/screenshots/{iphone-6.9,ipad-13}/{en,zh}
```

在模拟器中用 **⌘S** 保存，或 Xcode **File → Save Screen Shot**。

## 8. 真机验证（上传后、提交审核前）

在 TestFlight 安装后逐项确认：

- [ ] 全新安装 → 引导页 → 空 Inbox
- [ ] 创建 / 编辑 / 完成 / 删除任务与清单
- [ ] 通知允许与拒绝；提醒在锁屏/杀进程后仍触发
- [ ] Face ID / Touch ID 开启、取消、失败
- [ ] 专注模式后台与重启
- [ ] 中英文、大号文字、横竖屏
- [ ] 深链接 `lessdo://x-callback-url/...`

记录设备型号与 iOS 版本到 `docs/APP_STORE_RELEASE.md` § Final Evidence。

## 9. 提交审核

1. 在版本中选中已处理的构建
2. 填写「此版本的新增内容」：**Initial release of LessDo 1.0**
3. 粘贴审核备注（`review-notes.txt`）
4. 确认截图、隐私、年龄分级与构建一致
5. **提交以供审核**

## 10. 相关文档

- 发布总清单：`docs/APP_STORE_RELEASE.md`
- 元数据详表：`docs/APP_STORE_METADATA.md`
- 发布方配置：`docs/publisher_contact.yaml` → `./tool/apply_publisher_contact.sh`
