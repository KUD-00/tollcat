package com.zhechengqi.tollcat.developer

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object DeveloperDebugLog {
    const val LIMIT = 300

    data class Line(
        val atMillis: Long,
        val category: String,
        val message: String,
    )

    data class HttpExchange(
        val summary: String,
        val body: String,
    )

    private val events = ArrayDeque<Line>()
    private val http = ArrayDeque<HttpExchange>()

    @Synchronized
    fun record(category: String, message: String) {
        events.addLast(Line(System.currentTimeMillis(), category, message))
        while (events.size > LIMIT) events.removeFirst()
    }

    @Synchronized
    fun recordHttp(summary: String, body: String) {
        http.addLast(HttpExchange(summary, body))
        while (http.size > LIMIT) http.removeFirst()
    }

    @Synchronized
    fun lines(): List<Line> = events.toList()

    @Synchronized
    fun exchanges(): List<HttpExchange> = http.toList()

    @Synchronized
    fun clear() {
        events.clear()
        http.clear()
    }

    fun exportText(storeDump: String, lastRefresh: String?): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        val parts = mutableListOf(
            "# TollCat debug log",
            "copiedAt ${formatter.format(Date())}",
        )
        if (!lastRefresh.isNullOrBlank()) {
            parts += "lastRefresh $lastRefresh"
        }
        val events = lines()
        if (events.isNotEmpty()) {
            parts += ""
            parts += "## events"
            for (line in events) {
                parts += "${formatter.format(Date(line.atMillis))} [${line.category}] ${line.message}"
            }
        }
        val exchanges = exchanges()
        if (exchanges.isNotEmpty()) {
            parts += ""
            parts += "## http"
            for (exchange in exchanges) {
                parts += exchange.summary
                if (exchange.body.isNotBlank()) {
                    parts += exchange.body
                }
                parts += ""
            }
        }
        parts += "## store"
        parts += storeDump
        return parts.joinToString("\n")
    }
}
