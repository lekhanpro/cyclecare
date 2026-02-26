package com.cyclecare.app.data.local.dao

import androidx.room.*
import com.cyclecare.app.data.local.entity.BirthControlEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface BirthControlDao {
    @Query("SELECT * FROM birth_control WHERE endDate IS NULL ORDER BY startDate DESC LIMIT 1")
    fun getCurrentBirthControl(): Flow<BirthControlEntity?>
    
    @Query("SELECT * FROM birth_control ORDER BY startDate DESC")
    fun getAllBirthControl(): Flow<List<BirthControlEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBirthControl(data: BirthControlEntity): Long
    
    @Update
    suspend fun updateBirthControl(data: BirthControlEntity)
    
    @Delete
    suspend fun deleteBirthControl(data: BirthControlEntity)
}
