package com.ticketsur.fasosoft

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.provider.Telephony
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
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "whatsapp" -> result.success(sendWhatsApp(call))
                        "sms" -> result.success(sendSms(call))
                        "email" -> result.success(sendEmail(call))
                        "mailbox" -> result.success(openMailbox())
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    // Jamais le contenu (jeton, numéro) dans le message d'erreur.
                    result.error("send_failed", error.javaClass.simpleName, null)
                }
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
    }
}

/** Fournisseur dédié : évite toute collision avec ceux des extensions. */
class EnvoisFileProvider : FileProvider()
