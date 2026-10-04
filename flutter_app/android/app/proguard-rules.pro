# Project-specific R8 rules for release builds. Most plugins
# (RevenueCat/purchases_flutter, image_picker, …) ship their own consumer
# rules; the entries below cover known gaps.

-keepattributes Signature
-keepattributes *Annotation*

## flutter_secure_storage (Tink) — compile-only annotation references.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

## RevenueCat (belt and braces; the SDK ships consumer rules too)
-keep class com.revenuecat.purchases.** { *; }

## Flutter deferred components reference Play Core classes we don't bundle.
-dontwarn com.google.android.play.core.**
