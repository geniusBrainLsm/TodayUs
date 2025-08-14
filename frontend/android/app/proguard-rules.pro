# TodayUs ProGuard configuration

# Keep all Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep Google Sign-In classes
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.play.core.** { *; }

# Keep Kakao SDK classes
-keep class com.kakao.** { *; }
-keep class com.kakao.sdk.** { *; }

# Keep HTTP client classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep model classes (used for JSON parsing)
-keepattributes Signature
-keepattributes *Annotation*

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Suppress warnings for missing platform classes
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlin.jvm.internal.**
-dontwarn com.google.android.play.core.**