package com.example.nestpet

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "com.jadfpt.nestpet/app_settings"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			if (call.method == "openNotificationSettings") {
				try {
					openNotificationSettings()
					result.success(null)
				} catch (e: Exception) {
					result.error("error", e.message, null)
				}
			} else {
				result.notImplemented()
			}
		}
	}

	private fun openNotificationSettings() {
		val pkg = applicationContext.packageName
		val intent = Intent().apply {
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
				action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
				putExtra(Settings.EXTRA_APP_PACKAGE, pkg)
			} else {
				action = "android.settings.APP_NOTIFICATION_SETTINGS"
				putExtra("app_package", pkg)
				putExtra("app_uid", applicationInfo.uid)
			}
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}
		startActivity(intent)
	}
}
