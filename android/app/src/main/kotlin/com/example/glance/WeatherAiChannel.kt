package com.example.glance

import android.content.Context
import com.google.mlkit.genai.summarization.Summarization
import com.google.mlkit.genai.summarization.SummarizerOptions
import com.google.mlkit.genai.summarization.SummarizationRequest
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.GenAiException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import kotlinx.coroutines.guava.await
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class WeatherAiChannel(
    private val context: Context,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "com.example.glance/weather_ai")
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var summarizer: com.google.mlkit.genai.summarization.Summarizer? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkAvailability" -> checkAvailability(result)
            "generateAction" -> {
                val weatherContext = call.argument<String>("weatherContext")
                if (weatherContext != null) {
                    generateAction(weatherContext, result)
                } else {
                    result.error("INVALID_ARGUMENT", "weatherContext is required", null)
                }
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkAvailability(result: MethodChannel.Result) {
        scope.launch {
            try {
                val options = SummarizerOptions.builder(context)
                    .setInputType(SummarizerOptions.InputType.ARTICLE)
                    .setOutputType(SummarizerOptions.OutputType.ONE_BULLET)
                    .setLanguage(SummarizerOptions.Language.ENGLISH)
                    .build()

                val tempSummarizer = Summarization.getClient(options)
                val status = tempSummarizer.checkFeatureStatus().await()
                tempSummarizer.close()

                result.success(mapOf(
                    "available" to (status == FeatureStatus.AVAILABLE ||
                                   status == FeatureStatus.DOWNLOADABLE ||
                                   status == FeatureStatus.DOWNLOADING),
                    "status" to when (status) {
                        FeatureStatus.AVAILABLE -> "available"
                        FeatureStatus.DOWNLOADABLE -> "downloadable"
                        FeatureStatus.DOWNLOADING -> "downloading"
                        else -> "unavailable"
                    }
                ))
            } catch (e: Exception) {
                result.success(mapOf(
                    "available" to false,
                    "status" to "error",
                    "error" to e.message
                ))
            }
        }
    }

    private fun generateAction(weatherContext: String, result: MethodChannel.Result) {
        scope.launch {
            try {
                // Create prompt for weather action
                val prompt = """
                    Based on the following weather conditions, provide ONE short,
                    actionable recommendation (max 10 words) for someone going outside.
                    Focus on practical advice like bringing an umbrella, wearing warm clothes, etc.

                    $weatherContext

                    Recommendation:
                """.trimIndent()

                val options = SummarizerOptions.builder(context)
                    .setInputType(SummarizerOptions.InputType.ARTICLE)
                    .setOutputType(SummarizerOptions.OutputType.ONE_BULLET)
                    .setLanguage(SummarizerOptions.Language.ENGLISH)
                    .build()

                summarizer = Summarization.getClient(options)

                // Check and download if needed
                val status = summarizer!!.checkFeatureStatus().await()

                if (status == FeatureStatus.DOWNLOADABLE) {
                    // Wait for download
                    suspendCancellableCoroutine { cont ->
                        summarizer!!.downloadFeature(object : DownloadCallback {
                            override fun onDownloadStarted(bytesToDownload: Long) {}
                            override fun onDownloadProgress(totalBytesDownloaded: Long) {}
                            override fun onDownloadFailed(e: GenAiException) {
                                cont.resumeWithException(e)
                            }
                            override fun onDownloadCompleted() {
                                cont.resume(Unit)
                            }
                        })
                    }
                } else if (status == FeatureStatus.UNAVAILABLE) {
                    result.success(mapOf(
                        "success" to false,
                        "error" to "AI features unavailable on this device"
                    ))
                    return@launch
                }

                // Run inference using await()
                val request = SummarizationRequest.builder(prompt).build()
                val summaryResult = summarizer!!.runInference(request).await()

                result.success(mapOf(
                    "success" to true,
                    "action" to summaryResult.summary.trim()
                ))

            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "error" to (e.message ?: "Unknown error")
                ))
            }
        }
    }

    fun dispose() {
        summarizer?.close()
        summarizer = null
        scope.cancel()
    }
}
