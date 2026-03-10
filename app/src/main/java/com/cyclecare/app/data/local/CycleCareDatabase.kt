package com.cyclecare.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.cyclecare.app.data.local.dao.*
import com.cyclecare.app.data.local.entity.*

@Database(
    entities = [
        PeriodEntity::class,
        DailyLogEntity::class,
        ReminderEntity::class,
        SettingsEntity::class,
        HealthDataEntity::class,
        PregnancyDataEntity::class,
        BirthControlEntity::class
    ],
    version = 3,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class CycleCareDatabase : RoomDatabase() {
    abstract fun periodDao(): PeriodDao
    abstract fun dailyLogDao(): DailyLogDao
    abstract fun reminderDao(): ReminderDao
    abstract fun settingsDao(): SettingsDao
    abstract fun healthDataDao(): HealthDataDao
    abstract fun pregnancyDataDao(): PregnancyDataDao
    abstract fun birthControlDao(): BirthControlDao
    
    companion object {
        const val DATABASE_NAME = "cyclecare_database"
    }
}
