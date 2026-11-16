package lifetree.coach.memento_mori_life_in_weeks.backup

import android.content.Context
import com.it_nomads.fluttersecurestorage.FlutterSecureStorage
import com.it_nomads.fluttersecurestorage.FlutterSecureStorageConfig
import com.it_nomads.fluttersecurestorage.SecurePreferencesCallback

/**
 * Reads and writes the vault's data key through flutter_secure_storage's own
 * Java class, without a Flutter engine (the backup agent runs without one).
 *
 * [OPTIONS] must equal what Dart sends for `SecureStorageDataKeyStore
 * .defaultStorage` (lib/security/data_key.dart, `AndroidOptions.toMap()`), or
 * the plugin would use other prefs, another key prefix or migrate the entry.
 * With the default RSA-OAEP key cipher no biometric prompt is involved, so all
 * callbacks run synchronously on the calling thread.
 */
class VaultKeyStorage(private val context: Context) {
    private val storage = FlutterSecureStorage(context)
    private var initError: Exception? = null

    init {
        storage.initialize(FlutterSecureStorageConfig(OPTIONS), callback({ }, { initError = it }))
    }

    /** The stored (base64) key, null if none is stored; throws on errors. */
    fun read(): String? {
        initError?.let { throw it }
        var value: String? = null
        var error: Exception? = null
        storage.read(storage.addPrefixToKey(KEY_NAME), callback({ value = it }, { error = it }))
        error?.let { throw it }
        return value
    }

    /** Stores [encodedKey], wrapped with this device's Keystore key; throws on errors. */
    fun write(encodedKey: String) {
        initError?.let { throw it }
        var error: Exception? = null
        storage.write(storage.addPrefixToKey(KEY_NAME), encodedKey, callback({ }, { error = it }))
        error?.let { throw it }
        flushToDisk()
    }

    /**
     * The plugin writes with `apply()`; the backup agent's process may end right
     * after the restore, so wait for the pending writes. An empty `commit()` is
     * queued behind earlier `apply()` calls of the same file.
     */
    private fun flushToDisk() {
        PLUGIN_PREFS.forEach { name ->
            context.getSharedPreferences(name, Context.MODE_PRIVATE).edit().commit()
        }
    }

    private fun <T> callback(onSuccess: (T) -> Unit, onError: (Exception) -> Unit) =
        object : SecurePreferencesCallback<T> {
            override fun onSuccess(result: T) = onSuccess(result)
            override fun onError(e: Exception) = onError(e)
        }

    companion object {
        /** `SecureStorageDataKeyStore.keyName` in lib/security/data_key.dart. */
        const val KEY_NAME = "vault_dek_v1"

        /** `AndroidOptions(resetOnError: false).toMap()` of flutter_secure_storage 11.2.0. */
        val OPTIONS: Map<String, Any> = mapOf(
            "resetOnError" to "false",
            "migrateOnAlgorithmChange" to "true",
            "migrateWithBackup" to "false",
            "enforceBiometrics" to "false",
            "requireBiometricsPerOperation" to "false",
            "keyCipherAlgorithm" to "RSA_ECB_OAEPwithSHA_256andMGF1Padding",
            "storageCipherAlgorithm" to "AES_GCM_NoPadding",
            "biometricType" to "biometricOrDeviceCredential",
            "requireBiometricConfirmation" to "true",
            "preferencesKeyPrefix" to "",
            "storageNamespace" to "",
            "biometricPromptTitle" to "Authenticate to access",
            "biometricPromptSubtitle" to "Use biometrics or device credentials",
            "biometricPromptNegativeButton" to "Cancel",
        )

        /** Data, wrapped key and algorithm-marker prefs of the default config. */
        private val PLUGIN_PREFS = listOf(
            "FlutterSecureStorage",
            "FlutterSecureKeyStorage",
            "FlutterSecureStorageConfiguration",
            "FlutterSecureStorageConfiguration:FlutterSecureStorage",
        )
    }
}
