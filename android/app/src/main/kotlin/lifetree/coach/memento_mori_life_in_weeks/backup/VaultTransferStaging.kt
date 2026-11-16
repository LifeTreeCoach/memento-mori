package lifetree.coach.memento_mori_life_in_weeks.backup

import java.io.File

/**
 * Where [VaultBackupAgent] stages the plain data key while a backup or restore
 * runs: `files/vault_transfer/dek`. The backup rules include exactly this
 * folder (`domain="file" path="vault_transfer/"`), so the restore never skips
 * it; it only exists during a backup, so normal backups gain nothing.
 *
 * The folder is deleted when the agent finishes and again at app start
 * ([clear] from MainActivity), in case the process died before the agent's
 * cleanup. Pure JVM: takes the app's `filesDir`.
 */
class VaultTransferStaging(filesDir: File) {
    val directory: File = File(filesDir, DIRECTORY)
    val file: File = File(directory, FILE_NAME)

    /** Deletes the staged key and its folder; true if nothing is left. */
    fun clear(): Boolean {
        if (!directory.exists()) return true
        return directory.deleteRecursively()
    }

    companion object {
        /** Must match the `vault_transfer/` includes in backup_rules.xml and data_extraction_rules.xml. */
        const val DIRECTORY = "vault_transfer"
        const val FILE_NAME = "dek"
    }
}
