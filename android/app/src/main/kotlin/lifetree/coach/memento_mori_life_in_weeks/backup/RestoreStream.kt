package lifetree.coach.memento_mori_life_in_weeks.backup

import java.io.IOException
import java.io.InputStream

/** Reading one file's bytes out of a shared restore stream. Pure JVM logic. */
object RestoreStream {
    private const val BUFFER_SIZE = 4096

    /**
     * Consumes exactly [size] bytes of [input] (never more: the stream carries
     * the next files too) and returns them, or null if [size] exceeds
     * [keepAtMost] (the bytes are consumed and dropped then).
     * Throws [IOException] if the stream ends early.
     */
    fun readExactly(input: InputStream, size: Long, keepAtMost: Int): ByteArray? {
        val keep = size in 0..keepAtMost.toLong()
        val result = if (keep) ByteArray(size.toInt()) else null
        val buffer = ByteArray(BUFFER_SIZE)
        var done = 0L
        try {
            while (done < size) {
                val wanted = minOf(buffer.size.toLong(), size - done).toInt()
                val read = input.read(buffer, 0, wanted)
                if (read < 0) throw IOException("Restore stream ended early")
                result?.let { buffer.copyInto(it, done.toInt(), 0, read) }
                done += read
            }
        } catch (e: IOException) {
            result?.fill(0)
            throw e
        } finally {
            buffer.fill(0)
        }
        return result
    }
}
