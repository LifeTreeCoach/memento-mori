package lifetree.coach.memento_mori_life_in_weeks.backup

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.InputStream

class RestoreStreamTest {
    private val next = byteArrayOf(9, 9, 9)

    @Test
    fun readsExactlyTheFileAndLeavesTheRest() {
        val input = ByteArrayInputStream(byteArrayOf(1, 2, 3, 4) + next)
        assertArrayEquals(byteArrayOf(1, 2, 3, 4), RestoreStream.readExactly(input, 4, 256))
        assertArrayEquals(next, input.readBytes())
    }

    @Test
    fun collectsShortReads() {
        val input = OneByteAtATime(ByteArray(10) { it.toByte() } + next)
        assertArrayEquals(ByteArray(10) { it.toByte() }, RestoreStream.readExactly(input, 10, 256))
        assertArrayEquals(next, input.readBytes())
    }

    @Test
    fun consumesButDropsOversizedFiles() {
        val input = ByteArrayInputStream(ByteArray(5000) + next)
        assertNull(RestoreStream.readExactly(input, 5000, 256))
        assertArrayEquals(next, input.readBytes())
    }

    @Test
    fun emptyFile() {
        assertEquals(0, RestoreStream.readExactly(ByteArrayInputStream(next), 0, 256)!!.size)
    }

    @Test(expected = IOException::class)
    fun failsWhenTheStreamEndsEarly() {
        RestoreStream.readExactly(ByteArrayInputStream(byteArrayOf(1, 2)), 4, 256)
    }

    private class OneByteAtATime(bytes: ByteArray) : InputStream() {
        private val inner = ByteArrayInputStream(bytes)
        override fun read(): Int = inner.read()
        override fun read(b: ByteArray, off: Int, len: Int): Int = inner.read(b, off, minOf(len, 1))
    }
}
