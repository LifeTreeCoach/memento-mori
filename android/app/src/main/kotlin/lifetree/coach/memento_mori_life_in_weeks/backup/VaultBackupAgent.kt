package lifetree.coach.memento_mori_life_in_weeks.backup

import android.app.backup.BackupAgent
import android.app.backup.BackupDataInput
import android.app.backup.BackupDataOutput
import android.app.backup.FullBackupDataOutput
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.File
import java.io.FileInputStream

/**
 * Auto Backup / device transfer with the vault's data key.
 *
 * The personal data is encrypted in `app_flutter/vault/`; its key lives in
 * flutter_secure_storage, wrapped by an Android Keystore key that never leaves
 * the device, so the backup rules exclude the plugin's files. This agent backs
 * up everything the XML rules allow and, only for end-to-end encrypted backups
 * and device-to-device transfers ([DekBackupPolicy]), adds the plain key as one
 * extra file. On restore it takes that file out of the stream and stores the
 * key again, wrapped by the new device's Keystore.
 *
 * Runs without a Flutter engine: no Flutter APIs here. The key is never logged.
 */
class VaultBackupAgent : BackupAgent() {
    private var restoredKey: ByteArray? = null

    private val staging: VaultTransferStaging
        get() = VaultTransferStaging(filesDir)

    private val stagingFile: File
        get() = staging.file

    // Required by BackupAgent; unused because the manifest sets fullBackupOnly.
    override fun onBackup(
        oldState: ParcelFileDescriptor?,
        data: BackupDataOutput?,
        newState: ParcelFileDescriptor?,
    ) = Unit

    override fun onRestore(data: BackupDataInput?, appVersionCode: Int, newState: ParcelFileDescriptor?) =
        Unit

    override fun onFullBackup(data: FullBackupDataOutput) {
        deleteStaging()
        if (!DekBackupPolicy.mayBackUp(Build.VERSION.SDK_INT)) {
            Log.i(TAG, "No backup below Android 9: the data key could not travel with it")
            return
        }
        super.onFullBackup(data)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) data.transportFlags else 0
        if (!DekBackupPolicy.shouldInclude(flags, Build.VERSION.SDK_INT)) {
            Log.i(TAG, "Backup without the data key (transport flags $flags)")
            return
        }
        try {
            val key = readKey() ?: return
            stagingFile.parentFile?.mkdirs()
            stagingFile.writeBytes(key.toByteArray(Charsets.US_ASCII))
            fullBackupFile(stagingFile, data)
            Log.i(TAG, "Backup includes the data key")
        } catch (e: Exception) {
            Log.w(TAG, "Data key not included: ${e.javaClass.simpleName}")
        } finally {
            deleteStaging()
        }
    }

    private fun readKey(): String? {
        val key = try {
            VaultKeyStorage(this).read()
        } catch (e: Exception) {
            Log.w(TAG, "Data key not readable, backup without it: ${e.javaClass.simpleName}")
            return null
        }
        if (key == null || !DekBackupPolicy.isValidEncodedKey(key)) {
            Log.i(TAG, "No usable data key to back up")
            return null
        }
        return key
    }

    override fun onRestoreFile(
        data: ParcelFileDescriptor,
        size: Long,
        destination: File,
        type: Int,
        mode: Long,
        mtime: Long,
    ) {
        if (destination.canonicalPath != stagingFile.canonicalPath) {
            super.onRestoreFile(data, size, destination, type, mode, mtime)
            return
        }
        // Read exactly `size` bytes; the descriptor belongs to the restore stream.
        restoredKey = RestoreStream.readExactly(
            FileInputStream(data.fileDescriptor),
            size,
            DekBackupPolicy.MAX_STAGED_BYTES,
        )
    }

    override fun onRestoreFinished() {
        super.onRestoreFinished()
        val bytes = restoredKey ?: return
        restoredKey = null
        try {
            val key = String(bytes, Charsets.US_ASCII)
            if (!DekBackupPolicy.isValidEncodedKey(key)) {
                Log.w(TAG, "Restored data key is malformed, ignored")
                return
            }
            VaultKeyStorage(this).write(key)
            Log.i(TAG, "Data key restored")
        } catch (e: Exception) {
            Log.w(TAG, "Restoring the data key failed: ${e.javaClass.simpleName}")
        } finally {
            bytes.fill(0)
            deleteStaging()
        }
    }

    private fun deleteStaging() {
        staging.clear()
    }

    private companion object {
        const val TAG = "VaultBackup"
    }
}
