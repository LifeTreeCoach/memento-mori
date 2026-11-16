package lifetree.coach.memento_mori_life_in_weeks.backup

import android.app.backup.BackupAgent
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Base64

class DekBackupPolicyTest {
    private val encrypted = DekBackupPolicy.FLAG_CLIENT_SIDE_ENCRYPTION_ENABLED
    private val transfer = DekBackupPolicy.FLAG_DEVICE_TO_DEVICE_TRANSFER

    @Test
    fun flagsMatchThePlatformConstants() {
        assertEquals(BackupAgent.FLAG_CLIENT_SIDE_ENCRYPTION_ENABLED, encrypted)
        assertEquals(BackupAgent.FLAG_DEVICE_TO_DEVICE_TRANSFER, transfer)
    }

    @Test
    fun includesTheKeyInEncryptedBackupsAndTransfers() {
        assertTrue(DekBackupPolicy.shouldInclude(encrypted, 28))
        assertTrue(DekBackupPolicy.shouldInclude(transfer, 31))
        assertTrue(DekBackupPolicy.shouldInclude(encrypted or transfer, 37))
        assertTrue(DekBackupPolicy.shouldInclude(encrypted or 0x40, 34))
    }

    @Test
    fun neverInPlainBackups() {
        assertFalse(DekBackupPolicy.shouldInclude(0, 37))
        assertFalse(DekBackupPolicy.shouldInclude(0x40, 37))
        assertFalse(DekBackupPolicy.shouldInclude(Int.MIN_VALUE, 37))
    }

    @Test
    fun backsUpNothingBeforeAndroid9() {
        assertFalse(DekBackupPolicy.mayBackUp(24))
        assertFalse(DekBackupPolicy.mayBackUp(27))
        assertTrue(DekBackupPolicy.mayBackUp(28))
        assertTrue(DekBackupPolicy.mayBackUp(37))
    }

    @Test
    fun neverBeforeAndroid9() {
        assertFalse(DekBackupPolicy.shouldInclude(encrypted, 27))
        assertFalse(DekBackupPolicy.shouldInclude(transfer, 24))
    }

    @Test
    fun acceptsBase64OfA32ByteKey() {
        val keys = listOf(ByteArray(32), ByteArray(32) { 0xFF.toByte() }, ByteArray(32) { it.toByte() })
        keys.forEach {
            assertTrue(DekBackupPolicy.isValidEncodedKey(Base64.getEncoder().encodeToString(it)))
        }
    }

    @Test
    fun rejectsOtherValues() {
        val encoder = Base64.getEncoder()
        listOf(
            "",
            encoder.encodeToString(ByteArray(31)),
            encoder.encodeToString(ByteArray(33)),
            encoder.encodeToString(ByteArray(32)).dropLast(1),
            encoder.encodeToString(ByteArray(32)) + "\n",
            Base64.getUrlEncoder().encodeToString(ByteArray(32) { 0xFB.toByte() }),
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB=", // non-zero padding bits
        ).forEach { assertFalse(it, DekBackupPolicy.isValidEncodedKey(it)) }
    }
}
