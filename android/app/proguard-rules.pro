# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# Keep your app's classes
-keep class com.example.helpdesk_app.** { *; }
# Dart/Flutter
-dontwarn io.flutter.embedding.**
-ignorewarnings