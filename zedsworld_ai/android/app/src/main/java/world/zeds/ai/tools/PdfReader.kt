package world.zeds.ai.tools

import android.content.Context
import android.net.Uri
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Vytáhne text z PDF, aby se dal předat modelu do kontextu.
 *
 * Skenovaná PDF (obrázky bez textové vrstvy) tímhle neprojdou – tam je
 * potřeba OCR, které je připravené v závislostech (ML Kit) a doplní se ve fázi 5.
 */
object PdfReader {

    private var initialized = false

    data class Result(val text: String, val pages: Int, val needsOcr: Boolean)

    suspend fun extract(ctx: Context, uri: Uri, maxChars: Int = 60_000): Result =
        withContext(Dispatchers.IO) {
            if (!initialized) { PDFBoxResourceLoader.init(ctx); initialized = true }

            ctx.contentResolver.openInputStream(uri).use { input ->
                PDDocument.load(input).use { doc ->
                    val stripper = PDFTextStripper().apply { sortByPosition = true }
                    val raw = stripper.getText(doc)
                    val text = raw.replace(Regex("\n{3,}"), "\n\n").trim()
                    Result(
                        text     = if (text.length > maxChars) text.take(maxChars) + "\n\n[zkráceno]" else text,
                        pages    = doc.numberOfPages,
                        needsOcr = text.length < doc.numberOfPages * 20,
                    )
                }
            }
        }

    /** Zabalí text PDF do zprávy pro model. */
    fun asPrompt(fileName: String, r: Result, question: String): String = buildString {
        append("Obsah PDF „").append(fileName).append("\" (").append(r.pages).append(" stran):\n\n")
        append("---\n").append(r.text).append("\n---\n\n")
        append(question.ifBlank { "Rozeber tento dokument a vytáhni z něj podstatné." })
    }
}
