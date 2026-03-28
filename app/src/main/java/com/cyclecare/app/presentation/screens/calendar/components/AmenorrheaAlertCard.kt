package com.cyclecare.app.presentation.screens.calendar.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.cyclecare.app.domain.model.AmenorrheaResult
import com.cyclecare.app.domain.model.AmenorrheaSeverity

@Composable
fun AmenorrheaAlertCard(
    result: AmenorrheaResult,
    onDismiss: () -> Unit,
    onViewDetails: () -> Unit,
    modifier: Modifier = Modifier
) {
    val containerColor = when (result.severity) {
        AmenorrheaSeverity.MILD -> MaterialTheme.colorScheme.secondaryContainer
        AmenorrheaSeverity.MODERATE -> MaterialTheme.colorScheme.tertiaryContainer
        AmenorrheaSeverity.SEVERE -> MaterialTheme.colorScheme.errorContainer
        AmenorrheaSeverity.NONE -> MaterialTheme.colorScheme.surfaceVariant
    }
    
    val iconColor = when (result.severity) {
        AmenorrheaSeverity.MILD -> MaterialTheme.colorScheme.secondary
        AmenorrheaSeverity.MODERATE -> MaterialTheme.colorScheme.tertiary
        AmenorrheaSeverity.SEVERE -> MaterialTheme.colorScheme.error
        AmenorrheaSeverity.NONE -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = containerColor)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = null,
                        tint = iconColor,
                        modifier = Modifier.size(24.dp)
                    )
                    Column {
                        Text(
                            text = result.severity.displayName,
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "${result.daysSinceLastPeriod} days since last period",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                IconButton(onClick = onDismiss) {
                    Icon(Icons.Default.Close, "Dismiss")
                }
            }
            
            Text(
                text = result.severity.description,
                style = MaterialTheme.typography.bodyMedium
            )
            
            if (result.contributingFactors.isNotEmpty()) {
                Text(
                    text = "Possible factors:",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.Bold
                )
                result.contributingFactors.take(2).forEach { factor ->
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.Top
                    ) {
                        Text("•", style = MaterialTheme.typography.bodySmall)
                        Text(factor, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OutlinedButton(
                    onClick = onViewDetails,
                    modifier = Modifier.weight(1f)
                ) {
                    Text("View Details")
                }
            }
            
            // Medical disclaimer
            Surface(
                modifier = Modifier.fillMaxWidth(),
                color = MaterialTheme.colorScheme.surface.copy(alpha = 0.5f),
                shape = MaterialTheme.shapes.small
            ) {
                Row(
                    modifier = Modifier.padding(8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "This is not a medical diagnosis. Please consult a healthcare professional.",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
fun AmenorrheaDetailSheet(
    result: AmenorrheaResult,
    onDismiss: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Period Delay Details",
                style = MaterialTheme.typography.headlineSmall
            )
            IconButton(onClick = onDismiss) {
                Icon(Icons.Default.Close, "Close")
            }
        }
        
        Divider()
        
        // Severity info
        Card(
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = result.severity.displayName,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${result.daysSinceLastPeriod} days since ${result.lastPeriodDate}",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
        
        // Contributing factors
        if (result.contributingFactors.isNotEmpty()) {
            Text(
                text = "Possible Contributing Factors",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            result.contributingFactors.forEach { factor ->
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Text(factor, style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
        
        // Recommendations
        Text(
            text = "Recommended Next Steps",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold
        )
        result.recommendations.forEach { recommendation ->
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    imageVector = Icons.Default.ArrowForward,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = MaterialTheme.colorScheme.secondary
                )
                Text(recommendation, style = MaterialTheme.typography.bodyMedium)
            }
        }
        
        // Medical disclaimer
        Card(
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.errorContainer
            )
        ) {
            Row(
                modifier = Modifier.padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error
                )
                Text(
                    text = "This analysis is not a medical diagnosis. Always consult with a qualified healthcare professional for medical advice.",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
        
        Button(
            onClick = onDismiss,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Got It")
        }
    }
}
