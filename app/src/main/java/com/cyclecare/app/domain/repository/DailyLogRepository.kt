package com.cyclecare.app.domain.repository

import com.cyclecare.app.domain.model.DailyLog
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface DailyLogRepository {
    fun getAllLogs(): Flow<List<DailyLog>>
    suspend fun getLogByDate(date: LocalDate): DailyLog?
    suspend fun insertLog(log: DailyLog): Long
    suspend fun updateLog(log: DailyLog)
    suspend fun deleteLog(log: DailyLog)
    suspend fun getLogsInRange(startDate: LocalDate, endDate: LocalDate): List<DailyLog>
}
