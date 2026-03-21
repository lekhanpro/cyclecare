package com.cyclecare.app.presentation.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat
import com.google.accompanist.systemuicontroller.rememberSystemUiController

// ── MyCalendar iOS-inspired Light Theme ──────────────────────────────
private val LightColorScheme = lightColorScheme(
    primary = PrimaryLight,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFFD9E4),    // Soft pink container
    onPrimaryContainer = Color(0xFF3E0021),

    secondary = SecondaryLight,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFF2DAFF),
    onSecondaryContainer = Color(0xFF2E004E),

    tertiary = AccentTeal,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFCCF2EC),
    onTertiaryContainer = Color(0xFF002B25),

    error = Color(0xFFE8637A),
    onError = Color.White,
    errorContainer = Color(0xFFFFE0E4),
    onErrorContainer = Color(0xFF410008),

    background = BackgroundLight,
    onBackground = TextPrimaryLight,

    surface = SurfaceLight,
    onSurface = TextPrimaryLight,
    surfaceVariant = Gray100,
    onSurfaceVariant = TextSecondaryLight,

    outline = Gray400,
    outlineVariant = Gray200,

    scrim = Color(0xFF000000),
    inverseSurface = Gray900,
    inverseOnSurface = Gray50,
    inversePrimary = Color(0xFFFFB1CA)
)

// ── Dark Theme ───────────────────────────────────────────────────────
private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFFFFB1CA),
    onPrimary = Color(0xFF650036),
    primaryContainer = Color(0xFF8E004F),
    onPrimaryContainer = Color(0xFFFFD9E4),

    secondary = Color(0xFFE1B9FF),
    onSecondary = Color(0xFF4A0072),
    secondaryContainer = Color(0xFF66009A),
    onSecondaryContainer = Color(0xFFF2DAFF),

    tertiary = Color(0xFF9AD8CE),
    onTertiary = Color(0xFF003730),
    tertiaryContainer = Color(0xFF005045),
    onTertiaryContainer = Color(0xFFCCF2EC),

    error = Color(0xFFFFB3B8),
    onError = Color(0xFF690010),
    errorContainer = Color(0xFF93001A),
    onErrorContainer = Color(0xFFFFE0E4),

    background = BackgroundDark,
    onBackground = TextPrimaryDark,

    surface = SurfaceDark,
    onSurface = TextPrimaryDark,
    surfaceVariant = Gray800,
    onSurfaceVariant = TextSecondaryDark,

    outline = Gray600,
    outlineVariant = Gray700,

    scrim = Color(0xFF000000),
    inverseSurface = Gray100,
    inverseOnSurface = Gray900,
    inversePrimary = PrimaryLight
)

// ── iOS-inspired rounded shapes ──────────────────────────────────────
val CycleCareShapes = Shapes(
    extraSmall = RoundedCornerShape(8.dp),
    small = RoundedCornerShape(12.dp),
    medium = RoundedCornerShape(16.dp),
    large = RoundedCornerShape(20.dp),
    extraLarge = RoundedCornerShape(28.dp)
)

@Composable
fun CycleCareTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    val systemUiController = rememberSystemUiController()

    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT

            WindowCompat.setDecorFitsSystemWindows(window, false)

            systemUiController.setSystemBarsColor(
                color = androidx.compose.ui.graphics.Color.Transparent,
                darkIcons = !darkTheme
            )
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = CycleCareShapes,
        content = content
    )
}
