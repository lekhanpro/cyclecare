package com.cyclecare.app.data.repository

import com.cyclecare.app.data.local.dao.ReminderDao
import com.cyclecare.app.data.local.entity.ReminderEntity
import com.cyclecare.app.domain.model.Reminder
import com.cyclecare.app.domain.model.ReminderType
import com.cyclecare.app.domain.repository.ReminderRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import java.time.LocalTime
import javax.inject.Inject

class ReminderRepositoryImpl @Inject constructor(
    private val reminderDao: ReminderDao
) : ReminderRepository {
    
    override fun getAllReminders(): Flow<List<Reminder>> {
        return reminderDao.getAllReminders().map { entities ->
            entities.map { it.toDomain() }
        }
    }
    
    override fun getEnabledReminders(): Flow<List<Reminder>> {
        return reminderDao.getEnabledReminders().map { entities ->
            entities.map { it.toDomain() }
        }
    }
    
    override suspend fun getReminderById(id: Long): Reminder? {
        return reminderDao.getReminderById(id)?.toDomain()
    }
    
    override suspend fun insertReminder(reminder: Reminder): Long {
        return reminderDao.insertReminder(reminder.toEntity())
    }
    
    override suspend fun updateReminder(reminder: Reminder) {
        reminderDao.updateReminder(reminder.toEntity())
    }
    
    override suspend fun deleteReminder(reminder: Reminder) {
        reminderDao.deleteReminder(reminder.toEntity())
    }
    
    override suspend fun deleteAllReminders() {
        reminderDao.deleteAllReminders()
    }
    
    private fun ReminderEntity.toDomain(): Reminder {
        return Reminder(
            id = id,
            type = runCatching { ReminderType.valueOf(type) }.getOrDefault(ReminderType.DAILY_LOG),
            time = runCatching { LocalTime.parse(time) }.getOrDefault(LocalTime.of(20, 0)),
            enabled = enabled,
            daysBeforePeriod = daysBeforePeriod,
            quietHoursEnabled = quietHoursEnabled,
            quietHoursStart = runCatching { LocalTime.parse(quietHoursStart) }.getOrDefault(LocalTime.of(22, 0)),
            quietHoursEnd = runCatching { LocalTime.parse(quietHoursEnd) }.getOrDefault(LocalTime.of(7, 0)),
            title = title,
            message = message
        )
    }
    
    private fun Reminder.toEntity(): ReminderEntity {
        return ReminderEntity(
            id = id,
            type = type.name,
            time = time.toString(),
            enabled = enabled,
            daysBeforePeriod = daysBeforePeriod,
            quietHoursEnabled = quietHoursEnabled,
            quietHoursStart = quietHoursStart.toString(),
            quietHoursEnd = quietHoursEnd.toString(),
            title = title,
            message = message
        )
    }
}
