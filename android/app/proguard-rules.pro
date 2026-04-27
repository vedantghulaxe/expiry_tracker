# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# Keep Tesseract OCR classes
-keep class com.googlecode.tesseract.** { *; }

# Keep SQLite classes
-keep class org.sqlite.** { *; }

# Keep camera and image processing
-keep class androidx.camera.** { *; }

# Optimize for size - remove debug logs
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom views
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
    *** get*();
}

# Keep Google AI and Gemini classes
-keep class com.google.ai.** { *; }
-keep class com.google.generativeai.** { *; }

# Keep HTTP and network classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.squareup.okhttp.** { *; }

# Keep JSON classes
-keep class com.google.gson.** { *; }
-keep class org.json.** { *; }

# Keep biometric authentication
-keep class androidx.biometric.** { *; }

# Keep work manager
-keep class androidx.work.** { *; }

# Keep local auth
-keep class androidx.security.** { *; }

# Keep image picker and camera
-keep class com.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep file provider
-keep class androidx.core.content.FileProvider { *; }

# Keep path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Keep shared preferences
-keep class android.content.SharedPreferences { *; }

# Keep database classes
-keep class androidx.room.** { *; }
-keep class drift.** { *; }

# Keep barcode scanning
-keep class com.google.mlkit.vision.barcode.** { *; }

# Preserve all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# KeepParcelable classes
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Play Store split compatibility classes
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep ML Kit text recognizer options for all languages
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Keep all ML Kit implementation classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.barcode.** { *; }

# Keep Flutter embedding classes
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }