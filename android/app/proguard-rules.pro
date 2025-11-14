# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# Stripe Android SDK - Keep all classes to prevent R8 from removing them
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep Stripe push provisioning classes (explicitly keep all inner classes and interfaces)
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivity { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivity$* { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$* { *; }
-keep class com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider { *; }
-keep class com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener { *; }
-keep interface com.stripe.android.pushProvisioning.** { *; }

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.pushprovisioning.** { *; }
-keep class com.reactnativestripesdk.pushprovisioning.PushProvisioningProxy { *; }
-keep class com.reactnativestripesdk.pushprovisioning.PushProvisioningProxy$* { *; }
-keep class com.reactnativestripesdk.pushprovisioning.DefaultPushProvisioningProxy { *; }
-keep class com.reactnativestripesdk.pushprovisioning.EphemeralKeyProvider { *; }
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Google Play Core - Keep all classes for Flutter deferred components (optional feature)
# Use -keepnames to keep class names but allow removal if not used
-keepnames class com.google.android.play.core.** { *; }
-keepnames class com.google.android.play.core.splitcompat.** { *; }
-keepnames class com.google.android.play.core.splitinstall.** { *; }
-keepnames class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep Flutter deferred component classes (optional - only if using deferred components)
-keepnames class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keepnames class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep all Stripe models and data classes
-keepclassmembers class com.stripe.android.** {
    *;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

