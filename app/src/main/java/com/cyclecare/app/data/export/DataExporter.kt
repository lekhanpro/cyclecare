package com.cyclecare.app.data.export

import android.content.Context
import com.cyclecare.app.data.local.dao.BirthControlDao
import com.cyclecare.app.data.local.dao.DailyLogDao
import com.cyclecare.app.data.local.dao.HealthDataDao
import com.cyclecare.app.data.local.dao.PeriodDao
import com.cyclecare.app.data.local.dao.PregnancyDataDao
import com.cyclecare.app.data.local.dao.ReminderDao
import com.cyclecare.app.data.local.dao.SettingsDao
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DataExporter @Inject constructor(
    @ApplicationContext private val context: Context,
    private val periodDao: PeriodDao,
    private val dailyLogDao: DailyLogDao,
    private val reminderDao: ReminderDao,
    private val settingsDao: SettingsDao,
    private val healthDataDao: HealthDataDao,
    private val pregnancyDataDao: PregnancyDataDao,
    private val birthControlDao: BirthControlDao
) {

    suspend fun exportToCsv(fileName: String = "cyclecare_export.csv"): String {
        val file = File(context.getExternalFilesDir(null), fileName)
        val formatter = DateTimeFormatter.ISO_DATE

        val periods = periodDao.getAllPeriodsList()
        val logs = dailyLogDao.getAllLogsList()

        val csvContent = buildString {
            appendLine("date,type,period_start,period_end,flow,mood,symptoms,discharge,weight_kg,temperature,sleep_hours,water_ml,intimacy,ovulation_test,pregnancy_test,notes")

            periods.forEach { period ->
                appendLine(
                    listOf(
                        period.startDate.format(formatter),
                        "period",
                        period.startDate.format(formatter),
                        period.endDate?.format(formatter).orEmpty(),
                        period.flow,
                        "",
                        period.symptoms.joinToString("|"),
                        "",
                        "",
                        "",
                        "",
                        "",
                        "",
                        "",
                        "",
                        sanitize(period.notes)
                    ).joinToString(",")
                )
            }

            logs.forEach { log ->
                appendLine(
                    listOf(
                        log.date.format(formatter),
                        "daily_log",
                        "",
                        "",
                        log.flow.orEmpty(),
                        log.mood.orEmpty(),
                        log.symptoms.joinToString("|"),
                        log.discharge.orEmpty(),
                        log.weightKg?.toString().orEmpty(),
                        log.temperature?.toString().orEmpty(),
                        log.sleepHours?.toString().orEmpty(),
                        log.waterMl.toString(),
                        log.intimacy,
                        log.ovulationTest,
                        log.pregnancyTest,
                        sanitize(log.notes)
                    ).joinToString(",")
                )
            }
        }

        file.writeText(csvContent)
        return file.absolutePath
    }

    suspend fun exportToPdf(fileName: String = "cyclecare_summary.txt"): String {
        val file = File(context.getExternalFilesDir(null), fileName)
        val periodsCount = periodDao.getPeriodsCount()
        val logsCount = dailyLogDao.getAllLogsList().size
        val remindersCount = reminderDao.getAllRemindersList().size

        file.writeText(
            buildString {
                appendLine("CycleCare Summary")
                appendLine("=================")
                appendLine("Periods tracked: $periodsCount")
                appendLine("Daily logs: $logsCount")
                appendLine("Reminders: $remindersCount")
                appendLine()
                appendLine("Generated locally on your device.")
            }
        )
        return file.absolutePath
    }

    suspend fun createBackup(fileName: String = "cyclecare_backup.json"): String {
        val file = File(context.getExternalFilesDir(null), fileName)

        val periods = periodDao.getAllPeriodsList()
        val logs = dailyLogDao.getAllLogsList()
        val reminders = reminderDao.getAllRemindersList()

        val json = buildString {
            append("{\n")
            append("  \"periodCount\": ${periods.size},\n")
            append("  \"dailyLogCount\": ${logs.size},\n")
            append("  \"reminderCount\": ${reminders.size}\n")
            append("}\n")
        }

        file.writeText(json)
        return file.absolutePath
    }

    suspend fun deleteAllData() {
        periodDao.deleteAll()
        dailyLogDao.deleteAll()
        reminderDao.deleteAllReminders()
        settingsDao.clear()
        healthDataDao.deleteAll()
        pregnancyDataDao.deleteAll()
        birthControlDao.deleteAll()
    }

    private fun sanitize(value: String): String {
        return value.replace(',', ';').replace('\n', ' ')
    }
}
