package com.cyclecare.app.di

import android.content.Context
import androidx.room.Room
import com.cyclecare.app.data.local.CycleCareDatabase
import com.cyclecare.app.data.local.dao.*
import com.cyclecare.app.data.repository.*
import com.cyclecare.app.domain.engine.CyclePredictionEngine
import com.cyclecare.app.domain.repository.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): CycleCareDatabase =
        Room.databaseBuilder(
            context,
            CycleCareDatabase::class.java,
            CycleCareDatabase.DATABASE_NAME
        )
        .fallbackToDestructiveMigration()
        .build()

    @Provides
    @Singleton
    fun providePeriodDao(database: CycleCareDatabase): PeriodDao =
        database.periodDao()

    @Provides
    @Singleton
    fun provideDailyLogDao(database: CycleCareDatabase): DailyLogDao =
        database.dailyLogDao()

    @Provides
    @Singleton
    fun provideReminderDao(database: CycleCareDatabase): ReminderDao =
        database.reminderDao()

    @Provides
    @Singleton
    fun provideSettingsDao(database: CycleCareDatabase): SettingsDao =
        database.settingsDao()

    @Provides
    @Singleton
    fun provideHealthDataDao(database: CycleCareDatabase): HealthDataDao =
        database.healthDataDao()

    @Provides
    @Singleton
    fun providePregnancyDataDao(database: CycleCareDatabase): PregnancyDataDao =
        database.pregnancyDataDao()

    @Provides
    @Singleton
    fun provideBirthControlDao(database: CycleCareDatabase): BirthControlDao =
        database.birthControlDao()

    @Provides
    @Singleton
    fun providePeriodRepository(
        periodDao: PeriodDao,
        cyclePredictionEngine: CyclePredictionEngine
    ): PeriodRepository =
        PeriodRepositoryImpl(periodDao, cyclePredictionEngine)

    @Provides
    @Singleton
    fun provideDailyLogRepository(dailyLogDao: DailyLogDao): DailyLogRepository =
        DailyLogRepositoryImpl(dailyLogDao)

    @Provides
    @Singleton
    fun provideReminderRepository(reminderDao: ReminderDao): ReminderRepository =
        ReminderRepositoryImpl(reminderDao)

    @Provides
    @Singleton
    fun provideSettingsRepository(settingsDao: SettingsDao): SettingsRepository =
        SettingsRepositoryImpl(settingsDao)

    @Provides
    @Singleton
    fun provideHealthDataRepository(healthDataDao: HealthDataDao): HealthDataRepository =
        HealthDataRepositoryImpl(healthDataDao)
}
