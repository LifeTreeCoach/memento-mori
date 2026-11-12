package lifetree.coach.memento_mori_life_in_weeks.contacts

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract
import android.provider.ContactsPickerSessionContract
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android 17's system contact picker (`ContactsPickerSessionContract.ACTION_PICK_CONTACTS`,
 * API 37) over the MethodChannel `memento/contacts_picker`. Needs no READ_CONTACTS: the picker
 * grants one-time read access to the session URI of the chosen contacts, which is read right
 * away. The activity forwards [onActivityResult].
 */
class ContactsPicker(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(::onMethodCall)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingResult?.success(null)
        pendingResult = null
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(isSupported())
            "pickContacts" -> pickContacts(result)
            else -> result.notImplemented()
        }
    }

    private fun pickContacts(result: MethodChannel.Result) {
        if (!isSupported()) {
            result.error("unsupported", "The contact picker needs Android 17 (API 37)", null)
            return
        }
        if (pendingResult != null) {
            result.error("already_active", "The contact picker is already open", null)
            return
        }
        try {
            activity.startActivityForResult(pickIntent(), REQUEST_CODE)
            pendingResult = result
        } catch (e: ActivityNotFoundException) {
            result.error("unavailable", "No contact picker on this device", null)
        }
    }

    /** Handles the picker's result; returns false for other request codes. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult ?: return true
        pendingResult = null
        val sessionUri = data?.data
        if (resultCode != Activity.RESULT_OK || sessionUri == null) {
            result.success(null)
            return true
        }
        // The grant is temporary: read the session now, off the main thread.
        Thread {
            val reply = runCatching { readSession(sessionUri) }
            mainHandler.post {
                reply.fold(
                    onSuccess = { contacts -> result.success(contacts.map { it.toChannelMap() }) },
                    onFailure = { e ->
                        Log.w(TAG, "Reading the picked contacts failed", e)
                        result.error("read_failed", e.message, null)
                    },
                )
            }
        }.start()
        return true
    }

    private fun isSupported(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.CINNAMON_BUN

    @RequiresApi(Build.VERSION_CODES.CINNAMON_BUN)
    private fun pickIntent(): Intent =
        Intent(ContactsPickerSessionContract.ACTION_PICK_CONTACTS)
            .putStringArrayListExtra(
                ContactsPickerSessionContract.EXTRA_PICK_CONTACTS_REQUESTED_DATA_FIELDS,
                PickedMimeTypes.requested,
            )
            .putExtra(ContactsPickerSessionContract.EXTRA_PICK_CONTACTS_SELECTION_LIMIT, SELECTION_LIMIT)
            .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)

    private fun readSession(sessionUri: Uri): List<PickedContact> {
        // No selection: the session provider rejects one (the user already selected).
        val cursor = activity.contentResolver.query(sessionUri, PROJECTION, null, null, null)
            ?: return emptyList()
        return cursor.use { pickedContactsFromRows(it.rows()) }
    }

    private fun Cursor.rows(): List<PickedRow> {
        val rows = ArrayList<PickedRow>(count.coerceAtLeast(0))
        while (moveToNext()) rows += currentRow()
        return rows
    }

    private fun Cursor.currentRow(): PickedRow {
        val mimeType = string(ContactsContract.Data.MIMETYPE)
        return PickedRow(
            contactId = getLong(getColumnIndexOrThrow(ContactsContract.Data.CONTACT_ID)),
            lookupKey = string(ContactsContract.Data.LOOKUP_KEY),
            contactDisplayName = string(ContactsContract.Data.DISPLAY_NAME),
            mimeType = mimeType,
            data1 = string(ContactsContract.Data.DATA1),
            data2 = int(ContactsContract.Data.DATA2),
            photo = if (mimeType == PickedMimeTypes.PHOTO) blob(ContactsContract.Data.DATA15) else null,
        )
    }

    private fun Cursor.string(column: String): String? =
        getColumnIndex(column).takeIf { it >= 0 && !isNull(it) }?.let(::getString)

    private fun Cursor.int(column: String): Int? =
        string(column)?.toIntOrNull()

    private fun Cursor.blob(column: String): ByteArray? =
        getColumnIndex(column).takeIf { it >= 0 && !isNull(it) && getType(it) == Cursor.FIELD_TYPE_BLOB }
            ?.let(::getBlob)

    private companion object {
        const val CHANNEL = "memento/contacts_picker"
        const val TAG = "ContactsPicker"
        const val REQUEST_CODE = 0x4D43 // "MC"
        /** The picker's documented maximum; with more contacts the user simply picks again. */
        const val SELECTION_LIMIT = 100

        val PROJECTION = arrayOf(
            ContactsContract.Data.CONTACT_ID,
            ContactsContract.Data.LOOKUP_KEY,
            ContactsContract.Data.DISPLAY_NAME,
            ContactsContract.Data.MIMETYPE,
            ContactsContract.Data.DATA1,
            ContactsContract.Data.DATA2,
            ContactsContract.Data.DATA15,
        )
    }
}
