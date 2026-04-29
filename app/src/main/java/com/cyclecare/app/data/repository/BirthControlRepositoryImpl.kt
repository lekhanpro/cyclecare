package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.BirthControlDao
import com.cyclecare.app.data.local.dao.DailyLogDao
import com.cyclecare.app.data.local.entity.BirthControlEntity
import com.cyclecare.app.domain.repository.BirthControlRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import java.time.LocalDate
import javax.inject.Inject

class BirthControlRepositoryImpl @Inject constructor(
    private val birthControlDao: BirthControlDao,
    private val dailyLogDao: DailyLogDao
) : BirthControlRepository {

    override fun getAllBirthControl(): Flow<List<BirthControlEntity>> {
        return birthControlDao.getAllBirthControl()
    }

    override fun getActiveBirthControl(): Flow<BirthControlEntity?> {
        return birthControlDao.getCurrentBirthControl()
    }

    override suspend fun insertBirthControl(birthControl: BirthControlEntity) {
        birthControlDao.insertBirthControl(birthControl)
    }

    override suspend fun updateBirthControl(birthControl: BirthControlEntity) {
        birthControlDao.updateBirthControl(birthControl)
    }

    override suspend fun deleteBirthControl(id: Long) {
        val entity = birthControlDao.getAllBirthControl().first().find { it.id == id }
        entity?.let { birthControlDao.deleteBirthControl(it) }
    }

    override suspend fun markPillTaken(date: String) {
        // This could be tracked in daily logs or a separate table
        // For now, we'll use the notes field in daily log as a simple implementation
        val localDate = LocalDate.parse(date)
        val log = dailyLogDao.getDailyLogByDate(localDate).first()
        if (log != null) {
            val updatedNotes = if (log.notes.contains("Pill taken")) {
                log.notes
            } else {
                "${log.notes}\nPill taken".trim()
            }
            dailyLogDao.updateDailyLog(log.copy(notes = updatedNotes))
        }
    }

    override suspend fun getPillStreak(): Int {
        // Calculate consecutive days with "Pill taken" in notes
        // This is a simplified implementation
        var streak = 0
        var currentDate = LocalDate.now()
        
        for (i in 0 until 365) {
            val log = dailyLogDao.getDailyLogByDate(currentDate).first()
            if (log?.notes?.contains("Pill taken") == true) {
                streak++
                currentDate = currentDate.minusDays(1)
            } else {
                break
            }
        }
        
        return streak
    }
}
