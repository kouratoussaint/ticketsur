package com.ticketsur.fasosoft

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CalendarContract
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Envoi assisté des tickets (lot 2) : ouvre WhatsApp, l'application SMS ou
 * l'e-mail de l'organisateur avec le destinataire, le texte et le ticket en
 * pièce jointe. L'organisateur appuie lui-même sur « Envoyer ».
 *
 * Réponses : "opened" (application ouverte), "app_missing" (aucune
 * application installée pour ce canal).
 */
class MainActivity : FlutterFragmentActivity() {
    /** Canal des notifications (barre du téléphone, ADR 0054). */
    private var notifications: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /** Notification touchée pendant que l'app tourne : page à ouvrir. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: return
        intent.removeExtra(EXTRA_ROUTE)
        notifications?.invokeMethod("openRoute", route)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notifications = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATIONS)
            .apply {
                setMethodCallHandler { call, result ->
                    try {
                        when (call.method) {
                            "notify" -> result.success(showNotification(call))
                            "launchRoute" -> {
                                val route = intent?.getStringExtra(EXTRA_ROUTE)
                                intent?.removeExtra(EXTRA_ROUTE)
                                result.success(route)
                            }
                            else -> result.notImplemented()
                        }
                    } catch (error: Exception) {
                        result.error("notify_failed", error.javaClass.simpleName, null)
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "whatsapp" -> result.success(sendWhatsApp(call))
                        "sms" -> result.success(sendSms(call))
                        "email" -> result.success(sendEmail(call))
                        "mailbox" -> result.success(openMailbox())
                        "calendar" -> result.success(addToCalendar(call))
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    // Jamais le contenu (jeton, numéro) dans le message d'erreur.
                    result.error("send_failed", error.javaClass.simpleName, null)
                }
            }
    }

    /**
     * Canal « Notifications Tikéo » à importance haute : bandeau en haut de
     * l'écran et son. Utilisé par Firebase (app fermée, `channel_id`) et par
     * [showNotification] (app ouverte).
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL,
            "Notifications Tikéo",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Événements, tickets, support et compte"
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    /**
     * Notification reçue app ouverte : affichée dans la barre comme si l'app
     * était fermée ; la toucher ouvre la page (extra [EXTRA_ROUTE]). Même
     * étiquette que Firebase (identifiant 0) : elles se remplacent. Faux si
     * les notifications sont refusées.
     */
    private fun showNotification(call: MethodCall): Boolean {
        createNotificationChannel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        val manager = NotificationManagerCompat.from(this)
        if (!manager.areNotificationsEnabled()) return false
        val title = call.argument<String>("title") ?: "Tikéo"
        val body = call.argument<String>("body") ?: ""
        val route = call.argument<String>("route")
        val tag = call.argument<String>("tag")
        val requestCode = (tag ?: route ?: "$title$body${System.currentTimeMillis()}").hashCode()
        val open = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (route != null) open.putExtra(EXTRA_ROUTE, route)
        val pending = PendingIntent.getActivity(
            this,
            requestCode,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher_monochrome)
            .setColor(ContextCompat.getColor(this, R.color.tikeo_mint))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .build()
        try {
            manager.notify(tag, if (tag == null) requestCode else 0, notification)
        } catch (_: SecurityException) {
            return false
        }
        return true
    }

    /**
     * Ouvre l'agenda du téléphone sur un nouvel événement prérempli (titre,
     * début, fin, lieu) ; la personne l'enregistre elle-même. Faux si aucun
     * agenda n'est installé.
     */
    private fun addToCalendar(call: MethodCall): Boolean {
        val intent = Intent(Intent.ACTION_INSERT)
            .setData(CalendarContract.Events.CONTENT_URI)
            .putExtra(
                CalendarContract.EXTRA_EVENT_BEGIN_TIME,
                call.argument<Number>("begin")!!.toLong(),
            )
            .putExtra(
                CalendarContract.EXTRA_EVENT_END_TIME,
                call.argument<Number>("end")!!.toLong(),
            )
            .putExtra(CalendarContract.Events.TITLE, call.argument<String>("title"))
            .putExtra(CalendarContract.Events.EVENT_LOCATION, call.argument<String>("location"))
            .putExtra(CalendarContract.Events.DESCRIPTION, call.argument<String>("description"))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (error: ActivityNotFoundException) {
            false
        }
    }

    /**
     * Ouvre l'application de messagerie (boîte de réception), pour trouver
     * l'e-mail de confirmation ou de réinitialisation. Faux si aucune.
     */
    private fun openMailbox(): Boolean {
        val intent = Intent.makeMainSelectorActivity(
            Intent.ACTION_MAIN,
            Intent.CATEGORY_APP_EMAIL,
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    /** Pièce jointe écrite dans le cache, partagée par une adresse content://. */
    private fun attach(intent: Intent, call: MethodCall) {
        val bytes = call.argument<ByteArray>("bytes") ?: return
        val dir = File(cacheDir, "envois").apply { mkdirs() }
        // Pièces des envois précédents : supprimées au-delà d'une heure.
        val now = System.currentTimeMillis()
        dir.listFiles()?.forEach { if (now - it.lastModified() > 3_600_000L) it.delete() }
        val name = (call.argument<String>("fileName") ?: "ticket.png")
            .replace(Regex("[^A-Za-z0-9._-]"), "_")
        val file = File(dir, name).apply { writeBytes(bytes) }
        val uri = FileProvider.getUriForFile(this, "$packageName.envois", file)
        intent.type = call.argument<String>("mimeType") ?: "image/png"
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        // ClipData : propage la lecture accordée, y compris via un sélecteur.
        intent.clipData = ClipData.newRawUri(name, uri)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    private fun start(intent: Intent): Boolean = try {
        startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    }

    /** Conversation WhatsApp du numéro (WhatsApp, puis WhatsApp Business). */
    private fun sendWhatsApp(call: MethodCall): String {
        val digits = (call.argument<String>("phone") ?: "").filter { it.isDigit() }
        val text = call.argument<String>("text") ?: ""
        for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                setPackage(pkg)
                type = "text/plain"
                putExtra("jid", "$digits@s.whatsapp.net")
                putExtra(Intent.EXTRA_TEXT, text)
            }
            attach(intent, call)
            if (start(intent)) return "opened"
        }
        return "app_missing"
    }

    /** Application SMS par défaut : MMS avec l'image si possible, sinon texte. */
    private fun sendSms(call: MethodCall): String {
        val phone = call.argument<String>("phone") ?: ""
        val text = call.argument<String>("text") ?: ""
        if (call.argument<ByteArray>("bytes") != null) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                Telephony.Sms.getDefaultSmsPackage(this@MainActivity)?.let { setPackage(it) }
                putExtra("address", phone)
                putExtra("sms_body", text)
                putExtra(Intent.EXTRA_TEXT, text)
            }
            attach(intent, call)
            if (start(intent)) return "opened"
        }
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:" + Uri.encode(phone))).apply {
            putExtra("sms_body", text)
        }
        return if (start(intent)) "opened" else "app_missing"
    }

    /** Messagerie e-mail (seules les applications d'e-mail sont proposées). */
    private fun sendEmail(call: MethodCall): String {
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_EMAIL, arrayOf(call.argument<String>("email") ?: ""))
            putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject") ?: "")
            putExtra(Intent.EXTRA_TEXT, call.argument<String>("text") ?: "")
            selector = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
        }
        attach(intent, call)
        return if (start(intent)) "opened" else "app_missing"
    }

    companion object {
        private const val CHANNEL = "ticketsur/send"
        private const val NOTIFICATIONS = "tikeo/notifications"
        private const val NOTIFICATION_CHANNEL = "tikeo"
        private const val EXTRA_ROUTE = "tikeo_route"
    }
}

/** Fournisseur dédié : évite toute collision avec ceux des extensions. */
class EnvoisFileProvider : FileProvider()
