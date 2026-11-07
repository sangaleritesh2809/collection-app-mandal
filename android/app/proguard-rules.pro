# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Mobile Ads / AdMob ProGuard Rules
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
-keep class io.flutter.plugins.googlemobileads.** { *; }
-dontwarn io.flutter.plugins.googlemobileads.**

# Google Play Services & User Messaging Platform (UMP)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.ump.**

