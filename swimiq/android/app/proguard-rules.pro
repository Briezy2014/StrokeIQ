# Flutter's Gradle plugin applies the engine's default keep rules automatically.
# The rules below suppress warnings for optional classes that Flutter references
# but this app does not bundle, so R8 (minify + resource shrinking) can run
# cleanly on release builds.

# Flutter deferred components / Play Feature Delivery split install. This app is
# a single, non-dynamic module and does not use deferred components.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
