# Patches Android Gradle files in-place (no git pull required)
$ErrorActionPreference = "Stop"
$androidDir = Join-Path $PSScriptRoot "..\android" | Resolve-Path

Write-Host "Fixing Android Gradle in: $androidDir" -ForegroundColor Cyan

$settingsGradle = Join-Path $androidDir "settings.gradle"
$settingsContent = @'
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.7.3" apply false
    id "org.jetbrains.kotlin.android" version "2.1.0" apply false
}

include ":app"
'@
Set-Content -Path $settingsGradle -Value $settingsContent -Encoding UTF8
Write-Host "OK  settings.gradle -> AGP 8.7.3" -ForegroundColor Green

$wrapperProps = Join-Path $androidDir "gradle\wrapper\gradle-wrapper.properties"
$wrapperContent = @'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip
'@
Set-Content -Path $wrapperProps -Value $wrapperContent -Encoding UTF8
Write-Host "OK  gradle-wrapper.properties -> Gradle 8.14" -ForegroundColor Green

$gradleProps = Join-Path $androidDir "gradle.properties"
$lines = @()
if (Test-Path $gradleProps) {
    $lines = Get-Content $gradleProps | Where-Object { $_ -notmatch '^\s*android\.newDsl\s*=' }
}
$base = @(
    'org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError'
    'android.useAndroidX=true'
    'android.enableJetifier=true'
    'android.newDsl=false'
)
$merged = $base + ($lines | Where-Object {
    $_ -notmatch '^\s*org\.gradle\.jvmargs\s*=' -and
    $_ -notmatch '^\s*android\.useAndroidX\s*=' -and
    $_ -notmatch '^\s*android\.enableJetifier\s*='
})
Set-Content -Path $gradleProps -Value $merged -Encoding UTF8
Write-Host "OK  gradle.properties -> android.newDsl=false" -ForegroundColor Green

$settingsKts = Join-Path $androidDir "settings.gradle.kts"
if (Test-Path $settingsKts) {
    Remove-Item $settingsKts -Force
    Write-Host "OK  removed settings.gradle.kts (conflicted with settings.gradle)" -ForegroundColor Yellow
}

$appKts = Join-Path $androidDir "app\build.gradle.kts"
if (Test-Path $appKts) {
    Remove-Item $appKts -Force
    Write-Host "OK  removed app/build.gradle.kts" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Gradle fix complete. Run build-android-release.ps1 next." -ForegroundColor Green
