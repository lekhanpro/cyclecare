package com.cyclecare.app.domain.repository

import com.cyclecare.app.data.local.entity.BirthControlEntity
import kotlinx.coroutines.flow.Flow

interface BirthControlRepository {
    fun getAllBirthControl(): Flow<List<BirthControlEntity>>
    fun getActiveBirthControl(): Flow<BirthControlEntity?>
    suspend fun insertBirthControl(birthControl: BirthControlEntity)
    suspend fun updateBirthControl(birthControl: BirthControlEntity)
    suspend fun deleteBirthControl(id: Long)
    suspend fun markPillTaken(date: String)
    suspend fun getPillStreak(): Int
}
