创建 Flutter 应用

目标（Goal）：
创建一个名为 崖柏 的 Flutter 应用，并根据我提供的 Figma 截图实现 登陆 页面。要求使用规范的项目结构、主题化管理、组件化开发，界面布局与截图保持一致。

需求（Requirements）：
1.	开发环境
	•	Flutter：稳定版 ≥ 3.22
	•	Dart ≥ 3.4
	•	支持 iOS 和 Android
2.	依赖包
	•	go_router —— 路由管理
	•	provider —— 状态管理
	•	dio —— 网络请求
	•	flutter_svg —— 图标支持
	•	intl —— 日期处理
3.	项目结构
    ```
    lib/
    app.dart
    main.dart
    core/theme/app_theme.dart
    core/widgets/ （通用组件）
    features/home/
        presentation/pages/home_page.dart
        presentation/widgets/ （首页各个组件）
        data/models/mock_feed.dart
    assets/
    icons/ （tab_home.svg, tab_grid.svg, tab_search.svg, tab_bell.svg, tab_user.svg）
    images/ （avatar_1.png）
    ```
4.	设计规范（Design Tokens）
	•   品牌绿：#36CAC4
5.  交付成果
	•	完整可运行的 Flutter 工程
	•	README：包含运行命令（flutter pub get && flutter run）和主要文件说明