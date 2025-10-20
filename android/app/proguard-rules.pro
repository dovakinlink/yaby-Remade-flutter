# Flutter 相关
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Google Play Core（Flutter Play Store 功能依赖）
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Dio 网络库
-keep class com.squareup.okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# 保留所有数据模型类（根据您的包名调整）
-keep class com.yabai.ctrial.** { *; }

# 保留所有注解
-keepattributes *Annotation*

# 保留行号信息（便于调试崩溃）
-keepattributes SourceFile,LineNumberTable

# 如果崩溃了，重命名的源文件名会被还原
-renamesourcefileattribute SourceFile

# 保留枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留序列化相关
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

