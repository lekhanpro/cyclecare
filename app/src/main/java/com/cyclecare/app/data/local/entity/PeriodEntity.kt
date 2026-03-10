package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

@Entity(tableName = "periods")
data class PeriodEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val flow: String,
    val symptoms: List<String>,
    val notes: String,
    val source: String = "MANUAL"
)
