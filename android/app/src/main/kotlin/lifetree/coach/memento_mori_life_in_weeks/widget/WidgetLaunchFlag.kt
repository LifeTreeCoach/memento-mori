package lifetree.coach.memento_mori_life_in_weeks.widget

/**
 * Remembers that the activity was started or brought to front by a widget tap until
 * Flutter asks for it ([consume]), so a tap is never lost when it arrives before the
 * Dart side listens (home_widget forwards `onNewIntent` only to an active listener and
 * does not buffer it).
 */
class WidgetLaunchFlag(private val launchAction: String) {
    private var pending = false

    /** Records a launch if [action] is the widget's launch action. */
    fun record(action: String?) {
        if (action == launchAction) pending = true
    }

    /** True once per recorded launch; clears the flag. */
    fun consume(): Boolean {
        val wasPending = pending
        pending = false
        return wasPending
    }
}
