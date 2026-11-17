package world.zeds.ai.tools

import android.content.Context
import android.print.PrintAttributes
import android.print.PrintManager
import android.webkit.WebView
import android.webkit.WebViewClient

/**
 * Export HTML do PDF. Používá systémový tiskový framework, takže uživatel
 * dostane standardní dialog s volbou „Uložit jako PDF".
 */
object PdfWriter {

    fun printHtml(ctx: Context, html: String, jobName: String) {
        val web = WebView(ctx).apply {
            settings.javaScriptEnabled = false
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String?) {
                    val pm = ctx.getSystemService(Context.PRINT_SERVICE) as PrintManager
                    pm.print(
                        jobName,
                        view.createPrintDocumentAdapter(jobName),
                        PrintAttributes.Builder()
                            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                            .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
                            .build(),
                    )
                }
            }
        }
        web.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
    }
}
