package com.cyclecare.app.presentation.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.google.accompanist.systemuicontroller.rememberSystemUiController

private val LightColorScheme = lightColorScheme(
    primary = PrimaryLight,
    onPrimary = SurfaceLight,
    primaryContainer = Color(0xFFFFD7E8),
    onPrimaryContainer = Color(0xFF3E001D),
    
    secondary = SecondaryLight,
    onSecondary = SurfaceLight,
    secondaryContainer = Color(0xFFF2DAFF),
    onSecondaryContainer = Color(0xFF2E004E),
    
    tertiary = AccentTeal,
    onTertiary = SurfaceLight,
    tertiaryContainer = Color(0xFFB2DFDB),
    onTertiaryContainer = Color(0xFF00251A),
    
    error = PeriodRed,
    onError = SurfaceLight,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
    
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
    inversePrimary = Color(0xFFFFB0D1)
)

private val DarkColorScheme = darkColorScheme(
    primary = Color(0xFFFFB0D1),
    onPrimary = Color(0xFF650033),
    primaryContainer = Color(0xFF8E004A),
    onPrimaryContainer = Color(0xFFFFD7E8),
    
    secondary = Color(0xFFE1B9FF),
    onSecondary = Color(0xFF4A0072),
    secondaryContainer = Color(0xFF66009A),
    onSecondaryContainer = Color(0xFFF2DAFF),
    
    tertiary = Color(0xFF80CBC4),
    onTertiary = Color(0xFF00382D),
    tertiaryContainer = Color(0xFF005143),
    onTertiaryContainer = Color(0xFFB2DFDB),
    
    error = Color(0xFFFFB4AB),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),
    
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
        content = content
    )
}
