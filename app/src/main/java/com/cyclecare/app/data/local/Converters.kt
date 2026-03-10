package com.cyclecare.app.data.local

import androidx.room.TypeConverter
import java.time.LocalDate

class Converters {
    @TypeConverter
    fun fromLocalDate(date: LocalDate?): String? = date?.toString()

    @TypeConverter
    fun toLocalDate(dateString: String?): LocalDate? = 
        dateString?.let { LocalDate.parse(it) }

    @TypeConverter
    fun fromStringList(list: List<String>?): String =
        list.orEmpty().joinToString(",")

    @TypeConverter
    fun toStringList(string: String?): List<String> =
        string?.takeIf { it.isNotBlank() }?.split(",") ?: emptyList()
}
