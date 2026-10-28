# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native channel classes and methods
-keep class com.restaurantpos.flutter_restaurant_pos.** { *; }

# Keep models for reflection/serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Preserve line numbers and source attributes for crashlytics/debugging
-keepattributes SourceFile,LineNumberTable
-dontwarn io.flutter.embedding.**
