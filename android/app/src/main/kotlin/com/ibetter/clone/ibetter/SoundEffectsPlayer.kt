package com.ibetter.clone.ibetter

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import java.util.Collections

class SoundEffectsPlayer(context: Context) {
    private val pool: SoundPool
    private val soundIds: Map<String, Int>
    private val loadedIds: MutableSet<Int> = Collections.synchronizedSet(HashSet())

    init {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        pool = SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(attrs)
            .build()
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            if (status == 0) {
                loadedIds.add(sampleId)
            }
        }
        soundIds = mapOf(
            "checkin" to pool.load(context, R.raw.sfx_checkin, 1),
            "uncheck" to pool.load(context, R.raw.sfx_uncheck, 1),
            "perfect_day" to pool.load(context, R.raw.sfx_perfect_day, 1),
            "achievement" to pool.load(context, R.raw.sfx_achievement, 1),
        )
    }

    fun play(type: String) {
        val id = soundIds[type] ?: soundIds["checkin"] ?: return
        if (loadedIds.contains(id)) {
            pool.play(id, 0.85f, 0.85f, 1, 0, 1.0f)
        }
    }

    fun release() {
        loadedIds.clear()
        pool.release()
    }
}
