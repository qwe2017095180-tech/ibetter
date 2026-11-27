package com.ibetter.clone.ibetter

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val UPDATER_CHANNEL = "com.ibetter.clone.ibetter/updater"
        private const val NATIVE_BRIDGE_CHANNEL = "com.ibetter.clone.ibetter/native_bridge"
        private const val PICK_IMAGE_REQUEST_CODE = 10042
    }

    private var pendingImageResult: MethodChannel.Result? = null
    private var pendingImageSlot: String = "avatar"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppVersion" -> {
                        try {
                            val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                packageManager.getPackageInfo(
                                    packageName,
                                    android.content.pm.PackageManager.PackageInfoFlags.of(0)
                                )
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, 0)
                            }
                            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                                pkgInfo.longVersionCode
                            } else {
                                @Suppress("DEPRECATION")
                                pkgInfo.versionCode.toLong()
                            }
                            result.success(
                                mapOf(
                                    "versionName" to (pkgInfo.versionName ?: "1.0.0"),
                                    "versionCode" to versionCode.toInt()
                                )
                            )
                        } catch (e: Exception) {
                            result.error("VERSION_ERROR", e.message, null)
                        }
                    }

                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "Missing APK path", null)
                            return@setMethodCallHandler
                        }
                        val file = File(path)
                        if (!file.exists()) {
                            result.error("FILE_NOT_FOUND", "APK file not found: $path", null)
                            return@setMethodCallHandler
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            !packageManager.canRequestPackageInstalls()
                        ) {
                            val settingsIntent = Intent(
                                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(settingsIntent)
                            result.success("permission_required")
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = FileProvider.getUriForFile(
                                this,
                                "$packageName.fileprovider",
                                file
                            )
                            val installIntent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/vnd.android.package-archive")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(installIntent)
                            result.success("launched")
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    }

                    "openUrl" -> {
                        val url = call.argument<String>("url")?.trim()
                        if (url.isNullOrEmpty() ||
                            (!url.startsWith("https://") && !url.startsWith("http://"))
                        ) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_BRIDGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickImage" -> {
                        val slot = call.argument<String>("slot") ?: "avatar"
                        if (pendingImageResult != null) {
                            pendingImageResult?.success(null)
                            pendingImageResult = null
                        }
                        pendingImageResult = result
                        pendingImageSlot = slot.replace(Regex("[^a-zA-Z0-9_-]"), "_")
                        val intent = android.content.Intent(android.content.Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(android.content.Intent.CATEGORY_OPENABLE)
                            type = "image/*"
                        }
                        @Suppress("DEPRECATION")
                        try {
                            startActivityForResult(intent, PICK_IMAGE_REQUEST_CODE)
                        } catch (_: Exception) {
                            val fallback = android.content.Intent(android.content.Intent.ACTION_GET_CONTENT).apply {
                                addCategory(android.content.Intent.CATEGORY_OPENABLE)
                                type = "image/*"
                            }
                            try {
                                startActivityForResult(fallback, PICK_IMAGE_REQUEST_CODE)
                            } catch (e2: Exception) {
                                pendingImageResult = null
                                result.error("PICKER_UNAVAILABLE", e2.message, null)
                            }
                        }
                    }

                    "updateHomeWidget" -> {
                        val title = call.argument<String>("title") ?: "轻松打卡"
                        val lines = call.argument<List<String>>("lines") ?: emptyList()
                        val doneCount = call.argument<Int>("doneCount") ?: 0
                        val totalCount = call.argument<Int>("totalCount") ?: 0
                        CheckInWidgetProvider.saveAndUpdate(
                            context = this,
                            title = title,
                            lines = lines,
                            doneCount = doneCount,
                            totalCount = totalCount,
                        )
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: android.content.Intent?,
    ) {
        if (requestCode == PICK_IMAGE_REQUEST_CODE) {
            val callback = pendingImageResult
            pendingImageResult = null
            if (callback != null) {
                if (resultCode == android.app.Activity.RESULT_OK && data?.data != null) {
                    val copied = copyPickedImageToFiles(data.data!!, pendingImageSlot)
                    callback.success(copied)
                } else {
                    callback.success(null)
                }
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun copyPickedImageToFiles(uri: android.net.Uri, slot: String): String? {
        return try {
            val outDir = java.io.File(filesDir, "profile_media").apply { mkdirs() }
            val stamp = System.currentTimeMillis()
            val outFile = java.io.File(outDir, "${slot}_$stamp.img")
            contentResolver.openInputStream(uri)?.use { input ->
                java.io.FileOutputStream(outFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            outDir.listFiles()?.forEach { f ->
                if (f.name.startsWith("${slot}_") && f.name != outFile.name) {
                    f.delete()
                }
            }
            outFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }
}
