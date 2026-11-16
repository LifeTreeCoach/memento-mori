package lifetree.coach.memento_mori_life_in_weeks.backup

/**
 * Decides when the vault's data key (DEK) may travel with a backup, and checks
 * what comes back. Pure JVM logic so it is unit-tested in both flavors.
 *
 * The key protects the personal data in `app_flutter/vault/`. It may only leave
 * the device inside an end-to-end encrypted backup or a direct device-to-device
 * transfer; a plain cloud backup would hand data and key to the same server.
 */
object DekBackupPolicy {
    /** `BackupAgent.FLAG_CLIENT_SIDE_ENCRYPTION_ENABLED` (API 28). */
    const val FLAG_CLIENT_SIDE_ENCRYPTION_ENABLED = 1

    /** `BackupAgent.FLAG_DEVICE_TO_DEVICE_TRANSFER` (API 28). */
    const val FLAG_DEVICE_TO_DEVICE_TRANSFER = 2

    /** Transport flags exist from Android 9 (API 28). */
    const val MIN_SDK = 28

    /** Upper bound for a staged key on restore (base64 of 32 bytes = 44). */
    const val MAX_STAGED_BYTES = 256

    private const val SAFE_FLAGS =
        FLAG_CLIENT_SIDE_ENCRYPTION_ENABLED or FLAG_DEVICE_TO_DEVICE_TRANSFER

    /** Base64 (standard alphabet, padded) of exactly 32 bytes. */
    private val ENCODED_KEY = Regex("[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=")

    /**
     * Whether a backup may run at all. Below API 28 there are no transport flags, so
     * the key can never travel and a restored vault could not be opened (locked
     * screen); backing up nothing is better. API 28-30 filter by the XML rules'
     * `requireFlags`, API 31+ by `data_extraction_rules.xml`.
     */
    fun mayBackUp(sdkInt: Int): Boolean = sdkInt >= MIN_SDK

    fun shouldInclude(transportFlags: Int, sdkInt: Int): Boolean =
        sdkInt >= MIN_SDK && (transportFlags and SAFE_FLAGS) != 0

    /** True if [encoded] is what the app stores: base64 of a 32-byte key. */
    fun isValidEncodedKey(encoded: String): Boolean = ENCODED_KEY.matches(encoded)
}
