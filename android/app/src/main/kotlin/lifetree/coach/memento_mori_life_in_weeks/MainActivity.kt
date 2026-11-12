package lifetree.coach.memento_mori_life_in_weeks

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import lifetree.coach.memento_mori_life_in_weeks.contacts.ContactBirthdayTexts
import lifetree.coach.memento_mori_life_in_weeks.contacts.ContactsPicker
import lifetree.coach.memento_mori_life_in_weeks.widget.WidgetLaunchFlag

class MainActivity : FlutterActivity() {
    private val widgetLaunch = WidgetLaunchFlag(HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION)
    private var widgetLaunchChannel: MethodChannel? = null
    private var contactsPicker: ContactsPicker? = null
    private var contactBirthdayTexts: ContactBirthdayTexts? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A recreated activity keeps its old intent; that launch was handled already.
        if (savedInstanceState == null) widgetLaunch.record(intent?.action)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        widgetLaunch.record(intent.action)
        // Flutter also checks on every resume; this covers an app that is already in front.
        widgetLaunchChannel?.invokeMethod(WIDGET_LAUNCHED, null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, APP_SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        startActivity(notificationSettingsIntent())
                        result.success(null)
                    }
                    OPEN_PLAY_STORE_LISTING ->
                        result.success(openPlayStoreListing(call.argument<String>("uri")))
                    else -> result.notImplemented()
                }
            }
        contactsPicker = ContactsPicker(this, messenger)
        contactBirthdayTexts = ContactBirthdayTexts(applicationContext, messenger)
        widgetLaunchChannel = MethodChannel(messenger, WIDGET_LAUNCH_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method == CONSUME_WIDGET_LAUNCH) {
                    result.success(widgetLaunch.consume())
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        widgetLaunchChannel?.setMethodCallHandler(null)
        widgetLaunchChannel = null
        contactsPicker?.dispose()
        contactsPicker = null
        contactBirthdayTexts?.dispose()
        contactBirthdayTexts = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    // FlutterActivity is no ComponentActivity, so no Activity Result API: forward by request code.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (contactsPicker?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    /** This app's notification settings (API 26+), else its app info screen. */
    private fun notificationSettingsIntent(): Intent =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
        }

    /**
     * Opens [uri] (default: this app's `market://` listing) in the Play Store app only, so
     * other stores that also handle `market://` (F-Droid, ...) don't raise a chooser.
     * Returns false when the Play Store is not installed; Flutter then opens the web page.
     */
    private fun openPlayStoreListing(uri: String?): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri ?: "market://details?id=$packageName"))
            .setPackage(PLAY_STORE_PACKAGE)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private companion object {
        const val APP_SETTINGS_CHANNEL = "memento/app_settings"
        const val OPEN_PLAY_STORE_LISTING = "openPlayStoreListing"
        const val PLAY_STORE_PACKAGE = "com.android.vending"
        const val WIDGET_LAUNCH_CHANNEL = "memento/widget_launch"
        const val CONSUME_WIDGET_LAUNCH = "consumeWidgetLaunch"
        const val WIDGET_LAUNCHED = "widgetLaunched"
    }
}
