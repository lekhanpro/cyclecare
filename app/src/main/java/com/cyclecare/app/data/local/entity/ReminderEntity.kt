package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "reminders")
data class ReminderEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val type: String,
    val time: String,
    val enabled: Boolean = true,
    val daysBeforePeriod: Int = 3,
    val title: String = "",
    val message: String = ""
)
