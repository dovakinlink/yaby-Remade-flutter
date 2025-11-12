# 项目分享链接 API 文档

## 功能概述

项目分享链接功能允许用户为临床试验项目生成一个可公开访问的分享链接。接收方无需登录即可通过浏览器查看项目详情，支持微信等社交平台的卡片预览。

## 核心特性

- ✅ **一键分享**：快速生成项目分享链接
- ✅ **无需登录**：接收方可直接访问，无需注册账号
- ✅ **自动过期**：链接自动过期（默认7天），保护数据安全
- ✅ **微信预览**：支持微信等社交平台显示卡片预览
- ✅ **静态页面**：直出 HTML，无需前端 JS 渲染
- ✅ **响应式设计**：完美支持移动端和桌面端访问

---

## API 接口

### 1. 生成项目分享链接

为指定的项目生成一个公开的分享链接。

**接口地址**
```
POST /api/v1/projects/{id}/share
```

**功能说明**

生成分享链接时，系统会：
1. 验证项目是否存在且当前用户有访问权限
2. 生成唯一的分享码（12位字符串）
3. 设置过期时间（根据系统配置，默认7天）
4. 渲染静态 HTML 页面并保存到服务器
5. 返回完整的分享链接 URL

**权限要求**
- 需要 JWT 认证
- 只能为当前组织的项目生成分享链接

**路径参数**

| 参数名 | 类型 | 必填 | 说明     |
|--------|------|------|----------|
| id     | Long | 是   | 项目ID   |

**请求头**

```http
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**请求示例**

```bash
# cURL 示例
curl -X POST "https://api.example.com/api/v1/projects/12/share" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json"
```

```javascript
// JavaScript (Fetch API) 示例
const response = await fetch('https://api.example.com/api/v1/projects/12/share', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

const result = await response.json();
console.log(result.data.shareUrl);
```

```kotlin
// Kotlin (Android) 示例
val client = OkHttpClient()
val request = Request.Builder()
    .url("https://api.example.com/api/v1/projects/12/share")
    .post(RequestBody.create(null, ""))
    .addHeader("Authorization", "Bearer $token")
    .addHeader("Content-Type", "application/json")
    .build()

val response = client.newCall(request).execute()
val result = response.body?.string()
```

```swift
// Swift (iOS) 示例
let url = URL(string: "https://api.example.com/api/v1/projects/12/share")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    if let data = data {
        let result = try? JSONDecoder().decode(ApiResponse<ShareLinkVO>.self, from: data)
        print(result?.data.shareUrl ?? "")
    }
}
task.resume()
```

**响应格式**

成功响应（200 OK）：

```json
{
  "success": true,
  "code": "SUCCESS",
  "message": "OK",
  "data": {
    "code": "abc123def456",
    "shareUrl": "https://yourdomain.com/s/abc123def456",
    "expireAt": "2024-11-19T10:30:00"
  }
}
```

**响应字段说明**

| 字段名     | 类型     | 说明                                           |
|-----------|----------|------------------------------------------------|
| success   | Boolean  | 请求是否成功                                    |
| code      | String   | 业务状态码                                      |
| message   | String   | 响应消息                                        |
| data      | Object   | 分享链接数据对象                                |
| └─ code   | String   | 分享码（12位唯一标识）                          |
| └─ shareUrl | String | 完整的分享链接 URL（可直接分享给他人）          |
| └─ expireAt | String | 过期时间（ISO 8601 格式）                       |

**错误响应**

项目不存在或无权访问（404）：
```json
{
  "success": false,
  "code": "PROJECT_NOT_FOUND",
  "message": "项目不存在或无权访问",
  "data": null
}
```

未登录（401）：
```json
{
  "success": false,
  "code": "UNAUTHORIZED",
  "message": "用户未登录",
  "data": null
}
```

文件生成失败（500）：
```json
{
  "success": false,
  "code": "SHARE_FILE_WRITE_ERROR",
  "message": "生成分享文件失败",
  "data": null
}
```

---

## 分享链接访问

### 2. 访问项目分享页面

通过分享码访问项目详情页面（公开接口，无需认证）。

**接口地址**
```
GET /s/{code}
```

**功能说明**

用户点击分享链接后，浏览器会访问该接口获取项目详情页面。
- 无需登录即可访问
- 返回完整的 HTML 页面
- 包含 Open Graph 标签，支持微信卡片预览
- 链接过期或被撤销后无法访问

**路径参数**

| 参数名 | 类型   | 必填 | 说明                     |
|--------|--------|------|--------------------------|
| code   | String | 是   | 分享码（12位字符串）     |

**请求示例**

```bash
# 浏览器直接访问
https://yourdomain.com/s/abc123def456

# cURL 示例
curl "https://yourdomain.com/s/abc123def456"
```

**响应格式**

成功响应（200 OK）：
```
Content-Type: text/html; charset=UTF-8

<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="非小细胞肺癌一线治疗研究">
  <meta property="og:description" content="项目详情描述...">
  ...
</head>
<body>
  <!-- 项目详情页面 HTML -->
</body>
</html>
```

链接失效响应（404）：
```html
<!-- 友好的错误提示页面 -->
<html>
<head><title>链接已失效</title></head>
<body>
  <div>分享链接不存在或已失效</div>
</body>
</html>
```

---

## APP 端集成指南

### 1. 生成分享链接流程

**步骤 1: 调用分享接口**

```kotlin
// Android 示例
suspend fun generateShareLink(projectId: Long): ShareLinkVO? {
    return withContext(Dispatchers.IO) {
        try {
            val response = apiService.generateProjectShareLink(projectId)
            if (response.success) {
                response.data
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e("ShareLink", "生成分享链接失败", e)
            null
        }
    }
}
```

**步骤 2: 展示分享选项**

```kotlin
// Android 分享功能示例
fun shareProject(shareUrl: String) {
    val shareIntent = Intent().apply {
        action = Intent.ACTION_SEND
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, shareUrl)
    }
    startActivity(Intent.createChooser(shareIntent, "分享项目"))
}
```

```swift
// iOS 分享功能示例
func shareProject(shareUrl: String) {
    let activityVC = UIActivityViewController(
        activityItems: [shareUrl],
        applicationActivities: nil
    )
    present(activityVC, animated: true)
}
```

### 2. 用户交互建议

**UI 设计建议**

1. **分享按钮位置**
   - 项目详情页右上角添加"分享"图标
   - 可使用系统分享图标（iOS Share icon / Android Share icon）

2. **加载状态**
   - 生成链接时显示加载提示："正在生成分享链接..."
   - 生成失败时显示错误提示

3. **成功提示**
   - 显示"分享链接已生成"提示
   - 直接打开系统分享面板
   - 或提供"复制链接"选项

**示例代码（Android）**

```kotlin
// 项目详情页面添加分享按钮
class ProjectDetailActivity : AppCompatActivity() {
    
    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.project_detail_menu, menu)
        return true
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_share -> {
                handleShare()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
    
    private fun handleShare() {
        // 显示加载提示
        showLoading("正在生成分享链接...")
        
        lifecycleScope.launch {
            val shareLink = generateShareLink(projectId)
            hideLoading()
            
            if (shareLink != null) {
                // 打开分享面板
                shareProject(shareLink.shareUrl)
                
                // 显示过期提示（可选）
                Toast.makeText(
                    this@ProjectDetailActivity,
                    "链接有效期至 ${formatDate(shareLink.expireAt)}",
                    Toast.LENGTH_LONG
                ).show()
            } else {
                // 显示错误提示
                Toast.makeText(
                    this@ProjectDetailActivity,
                    "生成分享链接失败，请稍后重试",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
    }
}
```

**示例代码（iOS）**

```swift
// 项目详情页面添加分享按钮
class ProjectDetailViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 添加分享按钮到导航栏
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(handleShare)
        )
        navigationItem.rightBarButtonItem = shareButton
    }
    
    @objc private func handleShare() {
        // 显示加载提示
        showLoading(message: "正在生成分享链接...")
        
        Task {
            if let shareLink = await generateShareLink(projectId: projectId) {
                hideLoading()
                
                // 打开分享面板
                shareProject(shareUrl: shareLink.shareUrl)
                
                // 显示过期提示（可选）
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy年MM月dd日"
                let expireDate = formatter.string(from: shareLink.expireAt)
                
                showToast(message: "链接有效期至 \(expireDate)")
            } else {
                hideLoading()
                showAlert(message: "生成分享链接失败，请稍后重试")
            }
        }
    }
    
    private func shareProject(shareUrl: String) {
        let activityVC = UIActivityViewController(
            activityItems: [shareUrl],
            applicationActivities: nil
        )
        
        // iPad 需要设置 popover
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
}
```

### 3. 链接管理建议

虽然当前 API 只提供生成功能，但建议 APP 端实现：

1. **缓存最近的分享链接**
   - 避免重复生成
   - 检查是否过期，过期则重新生成

2. **提供链接预览**
   - 显示链接过期时间
   - 提供"复制链接"快捷操作

3. **错误处理**
   - 网络错误：提示用户检查网络
   - 权限错误：提示用户联系管理员
   - 服务器错误：提示稍后重试

---

## 数据模型

### ShareLinkVO

分享链接数据对象

```typescript
interface ShareLinkVO {
  code: string;        // 分享码（12位唯一标识）
  shareUrl: string;    // 完整的分享链接 URL
  expireAt: string;    // 过期时间（ISO 8601 格式）
}
```

```kotlin
// Kotlin 数据类
data class ShareLinkVO(
    val code: String,
    val shareUrl: String,
    val expireAt: String  // 可以用 @SerializedName("expireAt") val expireAt: LocalDateTime
)
```

```swift
// Swift 结构体
struct ShareLinkVO: Codable {
    let code: String
    let shareUrl: String
    let expireAt: String  // 可以用 Date 类型
}
```

---

## 分享页面展示内容

生成的静态 HTML 页面包含以下信息：

### 1. 基本信息
- 项目名称
- 项目简称（如有）
- 申办方
- 项目进度
- 签约例数

### 2. 项目标签
- 自定义标签列表（标签形式展示）

### 3. 项目属性
- 动态属性（如：瘤种、分期、治疗线数等）
- 根据项目配置的属性模板自动展示

### 4. 入排标准
- 入组标准列表
- 排除标准列表
- 清晰的视觉区分

### 5. 项目人员
- 人员姓名
- 角色（PI、CRC 等）
- 备注信息

### 6. 项目备注
- 项目的详细说明或补充信息

### 页面特性
- ✅ 响应式设计，支持手机和电脑
- ✅ 美观的渐变色头部
- ✅ 卡片式布局
- ✅ 支持微信卡片预览
- ✅ **不包含患者隐私信息**

---

## 常见问题

### Q1: 分享链接的有效期是多久？
**A**: 默认有效期为 7 天，可在服务端配置文件中调整。过期后链接将自动失效。

### Q2: 同一个项目可以生成多个分享链接吗？
**A**: 可以。每次调用接口都会生成一个新的分享链接，所有有效的链接都可以访问。

### Q3: 分享链接可以撤销吗？
**A**: 目前 API 未提供撤销功能，但链接会在过期时间后自动失效。如需立即撤销，请联系后端开发人员。

### Q4: 分享页面可以被搜索引擎收录吗？
**A**: 不会。页面包含 `<meta name="robots" content="noindex,nofollow">` 标签，禁止搜索引擎收录。

### Q5: 用户访问失效的链接会看到什么？
**A**: 会看到一个友好的错误提示页面，说明链接已过期或不存在，并建议联系分享人获取新链接。

### Q6: 分享链接包含患者信息吗？
**A**: 不包含。分享页面只展示项目的基本信息、标签、属性、入排标准和项目人员，不涉及任何患者隐私数据。

### Q7: 微信分享时会显示什么？
**A**: 微信会显示项目名称、项目描述和默认图片的卡片预览。具体内容由 Open Graph 标签控制。

### Q8: 链接可以在微信小程序中打开吗？
**A**: 可以在小程序的 web-view 组件中打开，但需要配置业务域名。

---

## 技术细节

### 安全性
- 分享码使用 UUID 生成，确保唯一性和随机性
- 支持过期时间控制，降低数据泄露风险
- 页面不包含敏感信息
- 分享链接访问无需认证，但仅展示公开信息

### 性能优化
- HTML 文件静态生成，访问速度快
- 使用原子文件写入，确保文件完整性
- 响应式设计，减少额外请求

### SEO 控制
- 添加 `noindex,nofollow` 标签
- 防止搜索引擎收录临时分享页面

---

## 更新记录

| 版本  | 日期       | 说明                   |
|-------|------------|------------------------|
| 1.0.0 | 2024-11-12 | 初始版本，支持生成和访问 |

---

## 联系我们

如有问题或建议，请联系后端开发团队。

