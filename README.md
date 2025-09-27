# 崖柏 Flutter 应用

基于 Flutter 3.35.4 创建的多端应用，按照提供的登陆页面设计稿实现，同时预置规范化的主题、路由与状态管理结构。

## 快速开始

```bash
flutter pub get
flutter run
```

可选命令：

```bash
flutter analyze
flutter test
```

## 主要技术栈

- `go_router`：集中式路由管理（`lib/app.dart`）。
- `provider`：轻量状态管理（`LoginFormProvider` 等）。
- `dio`：网络请求客户端（`lib/core/network/api_client.dart`）。
- `flutter_svg`：矢量图标渲染。
- `intl`：日期格式化（示例数据与状态栏时间）。

## 目录结构

```
lib/
├── app.dart                     # MaterialApp.router + 全局依赖注入
├── main.dart                    # 启动入口
├── core/
│   ├── network/api_client.dart  # Dio 基础配置
│   ├── theme/app_theme.dart     # 品牌主题（品牌绿 #36CAC4 等）
│   └── widgets/                 # AppLogo、PrimaryButton 等通用组件
├── features/
│   ├── auth/
│   │   ├── providers/login_form_provider.dart
│   │   └── presentation/
│   │       ├── pages/login_page.dart
│   │       └── widgets/remember_me_row.dart
│   └── home/
│       ├── data/models/mock_feed.dart
│       └── presentation/
│           ├── pages/home_page.dart
│           └── widgets/feed_card.dart
└──
```

`assets/` 目录下提供登陆页和后续页面所需的 SVG 图标与示例头像。

## 登陆页面要点

- 布局参考设计稿，包含状态栏、品牌标识、表单、记住我开关与登录按钮。
- 统一使用 `AppTheme` 定义的输入框、按钮与颜色体系。
- 提供演示性的登陆提交流程与 `SnackBar` 提示，可按需替换为真实接口。

如需扩展其它页面或业务模块，可继续在 `features/` 下新增子目录并复用 `core/` 中的基础能力。
