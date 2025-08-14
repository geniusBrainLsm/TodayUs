package com.todayus.todayus_frontend

import android.content.pm.PackageManager
import android.content.pm.Signature
import android.content.pm.SigningInfo
import android.os.Build
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.todayus.todayus_frontend/key_hash"
    private val PACKAGE_CHANNEL = "com.todayus.todayus_frontend/package_info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getKeyHash" -> {
                    val keyHash = getKeyHash()
                    if (keyHash != null) {
                        result.success(keyHash)
                    } else {
                        result.error("UNAVAILABLE", "Key hash not available", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PACKAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPackageName" -> {
                    result.success(packageName)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getKeyHash(): String? {
        try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                // API 28 이상
                val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                info.signingInfo?.apkContentsSigners
            } else {
                // API 28 미만
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                info.signatures
            }

            signatures?.let { sigs ->
                for (signature in sigs) {
                    val md = MessageDigest.getInstance("SHA1")
                    md.update(signature.toByteArray())
                    val keyHash = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
                    Log.d("KeyHash", "Key Hash: $keyHash")
                    return keyHash
                }
            }
        } catch (e: PackageManager.NameNotFoundException) {
            Log.e("KeyHash", "Package not found", e)
        } catch (e: NoSuchAlgorithmException) {
            Log.e("KeyHash", "No such algorithm", e)
        }
        return null
    }
}
