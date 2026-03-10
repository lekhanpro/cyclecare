package com.cyclecare.app.data.local.dao

import androidx.room.*
import com.cyclecare.app.data.local.entity.HealthDataEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HealthDataDao {
    @Query("SELECT * FROM health_data ORDER BY date DESC")
    fun getAllHealthData(): Flow<List<HealthDataEntity>>
    
    @Query("SELECT * FROM health_data WHERE date = :date")
    suspend fun getHealthDataByDate(date: String): HealthDataEntity?
    
    @Query("SELECT * FROM health_data WHERE date BETWEEN :startDate AND :endDate ORDER BY date DESC")
    fun getHealthDataInRange(startDate: String, endDate: String): Flow<List<HealthDataEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHealthData(healthData: HealthDataEntity): Long
    
    @Update
    suspend fun updateHealthData(healthData: HealthDataEntity)
    
    @Delete
    suspend fun deleteHealthData(healthData: HealthDataEntity)

    @Query("DELETE FROM health_data")
    suspend fun deleteAll()
}
