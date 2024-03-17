package com.example.fzwm_wxbc_public

import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import com.google.gson.Gson
import com.kingdee.bos.webapi.entity.QueryParam
import com.kingdee.bos.webapi.sdk.K3CloudApi
import com.kingdee.bos.webapi.utils.MD5Utils
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.*
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.*


/** FzwmWxbcPublicPlugin */
class FzwmWxbcPublicPlugin: FlutterPlugin, MethodCallHandler {

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fzwm_wxbc_public")
    channel.setMethodCallHandler(this)
  }

  @RequiresApi(Build.VERSION_CODES.O)
  @Throws(Exception::class)
  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if(call.method == "arouseAbc"){
      if(call.method == "arouseAbc"){
        println(call.arguments);
        result.success(MD5Utils.hashMAC(call.argument("content") as String?, call.argument("key") as String?))
      }else{
        result.success("fail")
      }
    } else {
      result.notImplemented()
    }
  }
  fun readConfigFile(filePath: String): String {
    val file = File(filePath)
    return try {
      file.readText()
    } catch (e: IOException) {
      // 处理错误，例如打印错误信息或返回默认值
      e.printStackTrace()
      ""
    }
  }
  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
