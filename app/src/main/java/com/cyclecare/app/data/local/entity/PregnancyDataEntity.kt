package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "pregnancy_data")
data class PregnancyDataEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val conceptionDate: String? = null,
    val dueDate: String? = null,
    val pregnancyTestDate: String? = null,
    val pregnancyTestResult: Boolean? = null,
    val currentWeek: Int = 0,
    val symptoms: String = "",
    val notes: String = ""
)
