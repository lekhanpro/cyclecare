package com.cyclecare.app.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "birth_control")
data class BirthControlEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val type: String,
    val startDate: String,
    val endDate: String? = null,
    val pillTime: String? = null,
    val reminderEnabled: Boolean = true,
    val notes: String = ""
)
