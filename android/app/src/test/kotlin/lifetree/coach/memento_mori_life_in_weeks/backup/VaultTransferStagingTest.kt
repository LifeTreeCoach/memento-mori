package lifetree.coach.memento_mori_life_in_weeks.backup

import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VaultTransferStagingTest {
    private val filesDir = Files.createTempDirectory("files").toFile()
    private val staging = VaultTransferStaging(filesDir)

    @Test
    fun stagesTheKeyInFilesVaultTransferDek() {
        assertEquals("vault_transfer/dek", staging.file.relativeTo(filesDir).invariantSeparatorsPath)
    }

    @Test
    fun clearDeletesALeftOverKeyAndItsFolder() {
        staging.directory.mkdirs()
        staging.file.writeText("key")
        assertTrue(staging.clear())
        assertFalse(staging.file.exists())
        assertFalse(staging.directory.exists())
    }

    @Test
    fun clearWithoutAStagedKeyIsANoOp() {
        assertTrue(staging.clear())
        assertTrue(filesDir.exists())
    }
}
