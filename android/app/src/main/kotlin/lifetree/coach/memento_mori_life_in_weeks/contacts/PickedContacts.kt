package lifetree.coach.memento_mori_life_in_weeks.contacts

/** MIME types of the `ContactsContract.Data` rows the picker returns (plain strings, JVM-testable). */
internal object PickedMimeTypes {
    const val STRUCTURED_NAME = "vnd.android.cursor.item/name"
    const val EVENT = "vnd.android.cursor.item/contact_event"
    const val PHOTO = "vnd.android.cursor.item/photo"

    /** `ContactsContract.CommonDataKinds.Event.TYPE_BIRTHDAY`. */
    const val EVENT_TYPE_BIRTHDAY = 3

    val requested = arrayListOf(STRUCTURED_NAME, EVENT, PHOTO)
}

/**
 * One `ContactsContract.Data` row of a picker session, reduced to what the import needs:
 * [data1] is StructuredName.DISPLAY_NAME / Event.START_DATE, [data2] Event.TYPE,
 * [photo] Photo.PHOTO (DATA15).
 */
internal data class PickedRow(
    val contactId: Long,
    val lookupKey: String?,
    val contactDisplayName: String?,
    val mimeType: String?,
    val data1: String?,
    val data2: Int?,
    val photo: ByteArray? = null,
)

/** A picked contact as sent to Dart (see `lib/people_import/picked_contacts_source.dart`). */
internal data class PickedContact(
    val id: String,
    val displayName: String,
    val birthday: String,
    val thumbnail: ByteArray?,
) {
    fun toChannelMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "displayName" to displayName,
        "birthday" to birthday,
        "thumbnail" to thumbnail,
    )
}

/**
 * Groups session rows by contact, in first-seen order. The id is the lookup key (matches
 * flutter_contacts' identifiers), else the contact id. The first birthday event wins; contacts
 * without a name are dropped, contacts without a birthday are kept with an empty birthday
 * (Dart skips them) and no thumbnail, so no photo bytes are sent for nothing.
 */
internal fun pickedContactsFromRows(rows: Iterable<PickedRow>): List<PickedContact> {
    val builders = LinkedHashMap<Long, PickedContactBuilder>()
    for (row in rows) {
        builders.getOrPut(row.contactId) { PickedContactBuilder(row.contactId) }.add(row)
    }
    return builders.values.mapNotNull { it.build() }
}

private class PickedContactBuilder(private val contactId: Long) {
    private var lookupKey: String? = null
    private var contactName: String? = null
    private var structuredName: String? = null
    private var birthday: String? = null
    private var photo: ByteArray? = null

    fun add(row: PickedRow) {
        lookupKey = lookupKey ?: row.lookupKey?.takeIf { it.isNotBlank() }
        contactName = contactName ?: row.contactDisplayName?.takeIf { it.isNotBlank() }
        when (row.mimeType) {
            PickedMimeTypes.STRUCTURED_NAME ->
                structuredName = structuredName ?: row.data1?.takeIf { it.isNotBlank() }
            PickedMimeTypes.EVENT -> if (row.data2 == PickedMimeTypes.EVENT_TYPE_BIRTHDAY) {
                birthday = birthday ?: row.data1?.takeIf { it.isNotBlank() }
            }
            PickedMimeTypes.PHOTO -> photo = photo ?: row.photo?.takeIf { it.isNotEmpty() }
        }
    }

    fun build(): PickedContact? {
        val name = (contactName ?: structuredName)?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        val date = birthday?.trim().orEmpty()
        return PickedContact(
            id = lookupKey ?: contactId.toString(),
            displayName = name,
            birthday = date,
            thumbnail = if (date.isEmpty()) null else photo,
        )
    }
}
