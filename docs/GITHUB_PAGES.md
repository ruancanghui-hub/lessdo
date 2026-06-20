# LessDo GitHub Pages 配置

公开隐私政策与支持页供 App Store Connect 使用。

## GitHub 的限制

GitHub Pages **只能**选这两个目录之一：

- `/`（仓库根目录）
- `/docs`（仓库里的 `docs/` 文件夹）

**没有** `/docs/hosted` 这种子目录选项。因此 HTML 必须放在 **`docs/` 根目录**（与 `privacy.html` 同级），不能放在 `docs/hosted/`。

## 正确配置（lessdo 仓库）

在 **GitHub → ruancanghui-hub/lessdo → Settings → Pages**：

| 项 | 值 |
|----|-----|
| Source | Deploy from a branch |
| Branch | `main`（或你用来发布的分支） |
| Folder | **`/docs`** |
| Enforce HTTPS | 开启 |

## 文件位置

| 文件 | 作用 |
|------|------|
| `docs/privacy.html` | 公开隐私政策 |
| `docs/support.html` | 公开支持页 |
| `docs/index.html` | 跳转到 support.html |
| `docs/.nojekyll` | 禁用 Jekyll，避免 `.md` 被错误处理 |

App Store 填写的 URL：

| 页面 | URL |
|------|-----|
| 隐私政策 | `https://ruancanghui-hub.github.io/lessdo/privacy.html` |
| 支持 | `https://ruancanghui-hub.github.io/lessdo/support.html` |

## 推送与验证

```bash
./tool/apply_publisher_contact.sh   # 更新邮箱后
git add docs/privacy.html docs/support.html docs/index.html docs/.nojekyll
git commit && git push
./tool/prepare_app_store_upload.sh
```

两页均应 **HTTP 200**，隐私页正文含 **Google AdMob**。
