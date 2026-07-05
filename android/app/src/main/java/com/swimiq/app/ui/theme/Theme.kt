package com.swimiq.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColorScheme = lightColorScheme(
    primary = SwimBlue,
    onPrimary = Color.White,
    primaryContainer = SwimBlueLight,
    onPrimaryContainer = SwimNavy,
    secondary = SwimBlueDark,
    onSecondary = Color.White,
    background = Color(0xFFF8FCFF),
    onBackground = SwimNavy,
    surface = Color.White,
    onSurface = SwimNavy,
)

@Composable
fun SwimIQTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        typography = Typography,
        content = content,
    )
}
