package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import java.time.LocalDate

@Entity(
    tableName = "daily_logs",
    indices = [Index(value = ["date"], unique = true)]
)
data class DailyLogEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val date: LocalDate,
    val flow: String?,
    val mood: String?,
    val symptoms: List<String>,
    val discharge: String?,
    val weightKg: Float?,
    val temperature: Float?,
    val ovulationTest: String,
    val pregnancyTest: String,
    val intimacy: String,
    val waterMl: Int,
    val cervicalMucus: String?,
    val sexualActivity: Boolean,
    val sleepHours: Float?,
    val exerciseMinutes: Int,
    val notes: String
)
