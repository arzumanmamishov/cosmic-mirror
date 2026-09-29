# Project-specific R8 rules for release builds. Most plugins (Firebase,
# RevenueCat/purchases_flutter, google_sign_in, image_picker, …) ship their own
# consumer rules; the entries below cover known gaps.

## flutter_stripe / Stripe Android SDK
# The optional push-provisioning module is referenced but not bundled.
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep class com.reactnativestripesdk.** { *; }

## flutter_local_notifications — scheduled notifications are serialized with
# Gson; R8 stripping generic signatures causes "Missing type parameter" crashes.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

## flutter_secure_storage (Tink) — compile-only annotation references.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

## RevenueCat (belt and braces; the SDK ships consumer rules too)
-keep class com.revenuecat.purchases.** { *; }

## Flutter deferred components reference Play Core classes we don't bundle.
-dontwarn com.google.android.play.core.**
