package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "health_data")
data class HealthDataEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val date: String,
    val weight: Float? = null,
    val bmi: Float? = null,
    val bloodPressureSystolic: Int? = null,
    val bloodPressureDiastolic: Int? = null,
    val heartRate: Int? = null,
    val medications: String = "",
    val supplements: String = ""
)
