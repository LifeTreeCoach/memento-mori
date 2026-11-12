package lifetree.coach.memento_mori_life_in_weeks.contacts

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The raw birthday texts (`Event.START_DATE`) of every contact over the MethodChannel
 * `memento/contact_birthdays` (method `birthdayTexts` -> map contact id -> text). flutter_contacts
 * drops a birthday it cannot parse (e.g. `15.08.1992`); Dart parses these texts as a fallback.
 * Needs READ_CONTACTS (the full import asks for it); without it the map is empty.
 */
class ContactBirthdayTexts(private val context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(::onMethodCall)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "birthdayTexts") {
            result.notImplemented()
            return
        }
        Thread {
            val texts = runCatching { readBirthdayTexts() }
                .onFailure { Log.w(TAG, "Reading birthday texts failed", it) }
                .getOrDefault(emptyMap())
            mainHandler.post { result.success(texts) }
        }.start()
    }

    private fun readBirthdayTexts(): Map<String, String> {
        val cursor = context.contentResolver.query(
            ContactsContract.Data.CONTENT_URI,
            PROJECTION,
            "${ContactsContract.Data.MIMETYPE} = ? AND ${ContactsContract.CommonDataKinds.Event.TYPE} = ?",
            arrayOf(PickedMimeTypes.EVENT, PickedMimeTypes.EVENT_TYPE_BIRTHDAY.toString()),
            null,
        ) ?: return emptyMap()
        val rows = ArrayList<BirthdayTextRow>()
        cursor.use {
            while (it.moveToNext()) {
                rows += BirthdayTextRow(contactId = it.getLong(0), text = it.getString(1))
            }
        }
        return firstBirthdayTexts(rows)
    }

    private companion object {
        const val CHANNEL = "memento/contact_birthdays"
        const val TAG = "ContactBirthdayTexts"

        val PROJECTION = arrayOf(
            ContactsContract.Data.CONTACT_ID,
            ContactsContract.CommonDataKinds.Event.START_DATE,
        )
    }
}

/** One birthday event row: the contact id and its raw `START_DATE`. */
internal data class BirthdayTextRow(val contactId: Long, val text: String?)

/** Contact id (as flutter_contacts' `Contact.id`) -> its first non-blank birthday text, trimmed. */
internal fun firstBirthdayTexts(rows: Iterable<BirthdayTextRow>): Map<String, String> {
    val texts = LinkedHashMap<String, String>()
    for (row in rows) {
        val text = row.text?.trim()?.takeIf { it.isNotEmpty() } ?: continue
        texts.putIfAbsent(row.contactId.toString(), text)
    }
    return texts
}
