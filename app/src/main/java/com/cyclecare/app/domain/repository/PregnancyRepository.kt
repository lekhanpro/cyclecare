package com.cyclecare.app.domain.repository

import com.cyclecare.app.data.local.entity.PregnancyDataEntity
import kotlinx.coroutines.flow.Flow

interface PregnancyRepository {
    fun getPregnancyData(): Flow<PregnancyDataEntity?>
    suspend fun insertPregnancyData(data: PregnancyDataEntity)
    suspend fun updatePregnancyData(data: PregnancyDataEntity)
    suspend fun deletePregnancyData()
    suspend fun getCurrentWeek(): Int
    fun isPregnancyMode(): Flow<Boolean>
}
