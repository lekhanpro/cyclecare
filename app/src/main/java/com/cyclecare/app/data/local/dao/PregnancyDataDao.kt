package com.cyclecare.app.data.local.dao

import androidx.room.*
import com.cyclecare.app.data.local.entity.PregnancyDataEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface PregnancyDataDao {
    @Query("SELECT * FROM pregnancy_data ORDER BY id DESC LIMIT 1")
    fun getCurrentPregnancyData(): Flow<PregnancyDataEntity?>
    
    @Query("SELECT * FROM pregnancy_data ORDER BY id DESC")
    fun getAllPregnancyData(): Flow<List<PregnancyDataEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertPregnancyData(data: PregnancyDataEntity): Long
    
    @Update
    suspend fun updatePregnancyData(data: PregnancyDataEntity)
    
    @Delete
    suspend fun deletePregnancyData(data: PregnancyDataEntity)
}
