# LessDo GitHub Pages 配置

公开隐私政策与支持页供 App Store Connect 使用。

## 正确配置（lessdo 仓库）

在 **GitHub → ruancanghui-hub/lessdo → Settings → Pages**：

| 项 | 值 |
|----|-----|
| Source | Deploy from a branch |
| Branch | `feature/lessdo-ios-1.0`（合并到 main 后改为 `main`） |
| Folder | **`/docs/hosted`**（不是 `/docs`） |
| Enforce HTTPS | 开启 |

保存后等待 1–2 分钟构建完成。

## 对应 URL

站点根目录 = 仓库中的 `docs/hosted/` 文件夹：

| 页面 | App Store 填写的 URL |
|------|----------------------|
| 隐私政策 | `https://ruancanghui-hub.github.io/lessdo/privacy.html` |
| 支持 | `https://ruancanghui-hub.github.io/lessdo/support.html` |
| 首页 | `https://ruancanghui-hub.github.io/lessdo/` → 跳转到支持页 |

**错误示例**（Folder 选成 `/docs` 时才会出现）：

- `https://ruancanghui-hub.github.io/lessdo/hosted/privacy.html` ← 不要填到 App Store

## 推送与验证

1. 将 `docs/hosted/` 下的 HTML 推送到 GitHub
2. 确认 Pages Folder 为 **`/docs/hosted`**
3. 本地验证：

```bash
./tool/prepare_app_store_upload.sh
```

或手动：

```bash
curl -I https://ruancanghui-hub.github.io/lessdo/privacy.html
curl -I https://ruancanghui-hub.github.io/lessdo/support.html
```

两页均应返回 **HTTP 200**，隐私页正文含 **Google AdMob**。

## 源码位置

| 文件 | 说明 |
|------|------|
| `docs/hosted/privacy.html` | 公开隐私政策 |
| `docs/hosted/support.html` | 公开支持页 |
| `docs/hosted/index.html` | 跳转到 support.html |
| `docs/hosted/.nojekyll` | 避免 Jekyll 处理 |

修改邮箱后运行：

```bash
./tool/apply_publisher_contact.sh
git add docs/hosted && git commit && git push
```
