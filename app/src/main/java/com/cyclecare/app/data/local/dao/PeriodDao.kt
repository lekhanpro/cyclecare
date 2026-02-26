package com.cyclecare.app.data.local.dao

import androidx.room.*
import com.cyclecare.app.data.local.entity.PeriodEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface PeriodDao {
    @Query("SELECT * FROM periods ORDER BY startDate DESC")
    fun getAllPeriods(): Flow<List<PeriodEntity>>

    @Query("SELECT * FROM periods WHERE id = :id")
    suspend fun getPeriodById(id: Long): PeriodEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPeriod(period: PeriodEntity): Long

    @Update
    suspend fun updatePeriod(period: PeriodEntity)

    @Delete
    suspend fun deletePeriod(period: PeriodEntity)

    @Query("SELECT * FROM periods ORDER BY startDate DESC LIMIT :limit")
    suspend fun getRecentPeriods(limit: Int): List<PeriodEntity>
    
    @Query("SELECT * FROM periods WHERE startDate >= :startDate AND startDate <= :endDate ORDER BY startDate")
    suspend fun getPeriodsInRange(startDate: LocalDate, endDate: LocalDate): List<PeriodEntity>
    
    @Query("SELECT COUNT(*) FROM periods")
    suspend fun getPeriodsCount(): Int
}
