package com.cyclecare.app.data.local.dao

import androidx.room.*
import com.cyclecare.app.data.local.entity.DailyLogEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface DailyLogDao {
    @Query("SELECT * FROM daily_logs ORDER BY date DESC")
    fun getAllLogs(): Flow<List<DailyLogEntity>>

    @Query("SELECT * FROM daily_logs ORDER BY date DESC")
    suspend fun getAllLogsList(): List<DailyLogEntity>

    @Query("SELECT * FROM daily_logs WHERE date = :date")
    suspend fun getLogByDate(date: LocalDate): DailyLogEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertLog(log: DailyLogEntity): Long

    @Update
    suspend fun updateLog(log: DailyLogEntity)

    @Delete
    suspend fun deleteLog(log: DailyLogEntity)
    
    @Query("SELECT * FROM daily_logs WHERE date >= :startDate AND date <= :endDate ORDER BY date")
    suspend fun getLogsInRange(startDate: LocalDate, endDate: LocalDate): List<DailyLogEntity>

    @Query("DELETE FROM daily_logs")
    suspend fun deleteAll()
}
