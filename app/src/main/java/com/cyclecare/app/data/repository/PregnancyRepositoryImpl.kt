package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.PregnancyDataDao
import com.cyclecare.app.data.local.entity.PregnancyDataEntity
import com.cyclecare.app.domain.repository.PregnancyRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import javax.inject.Inject

class PregnancyRepositoryImpl @Inject constructor(
    private val pregnancyDataDao: PregnancyDataDao
) : PregnancyRepository {

    override fun getPregnancyData(): Flow<PregnancyDataEntity?> {
        return pregnancyDataDao.getCurrentPregnancyData()
    }

    override suspend fun insertPregnancyData(data: PregnancyDataEntity) {
        pregnancyDataDao.insertPregnancyData(data)
    }

    override suspend fun updatePregnancyData(data: PregnancyDataEntity) {
        pregnancyDataDao.updatePregnancyData(data)
    }

    override suspend fun deletePregnancyData() {
        pregnancyDataDao.deleteAll()
    }

    override suspend fun getCurrentWeek(): Int {
        val data = pregnancyDataDao.getCurrentPregnancyData().first() ?: return 0
        val conceptionDate = data.conceptionDate?.let { LocalDate.parse(it) } ?: return 0
        val today = LocalDate.now()
        val daysSinceConception = ChronoUnit.DAYS.between(conceptionDate, today)
        return (daysSinceConception / 7).toInt()
    }

    override fun isPregnancyMode(): Flow<Boolean> {
        return pregnancyDataDao.getCurrentPregnancyData().map { it != null }
    }
}
