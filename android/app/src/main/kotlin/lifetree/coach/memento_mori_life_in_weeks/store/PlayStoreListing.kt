package lifetree.coach.memento_mori_life_in_weeks.store

/**
 * The only link `memento/app_settings` `openPlayStoreListing` opens: this app's own
 * `market://` listing. Whatever the caller passes is ignored, so the channel can never
 * be used to open another app's page or an arbitrary URI. Pure JVM logic (unit-tested).
 */
object PlayStoreListing {
    /** This app's listing in the Play Store app. */
    fun uriFor(packageName: String): String = "market://details?id=$packageName"

    /**
     * True when [requested] (the channel's `uri` argument, of any type) is something
     * other than this app's listing, i.e. ignored; null means "not given".
     */
    fun isIgnored(requested: Any?, packageName: String): Boolean =
        requested != null && requested != uriFor(packageName)
}
