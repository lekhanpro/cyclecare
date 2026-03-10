package com.cyclecare.app.data.local.dao

import androidx.room.*
import com.cyclecare.app.data.local.entity.ReminderEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ReminderDao {
    @Query("SELECT * FROM reminders ORDER BY time ASC")
    fun getAllReminders(): Flow<List<ReminderEntity>>
    
    @Query("SELECT * FROM reminders WHERE id = :id")
    suspend fun getReminderById(id: Long): ReminderEntity?
    
    @Query("SELECT * FROM reminders WHERE enabled = 1")
    fun getEnabledReminders(): Flow<List<ReminderEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReminder(reminder: ReminderEntity): Long
    
    @Update
    suspend fun updateReminder(reminder: ReminderEntity)
    
    @Delete
    suspend fun deleteReminder(reminder: ReminderEntity)
    
    @Query("DELETE FROM reminders")
    suspend fun deleteAllReminders()

    @Query("SELECT * FROM reminders ORDER BY time ASC")
    suspend fun getAllRemindersList(): List<ReminderEntity>
}
