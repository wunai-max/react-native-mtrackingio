package com.mtrackingio

import android.app.Application
import android.net.Uri
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReadableType
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.reyun.tracking.sdk.InitParameters
import com.reyun.tracking.sdk.Tracking
import com.reyun.tracking.utils.IDeepLinkListener

class MtrackingioModule(private val reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private var hasInitialized = false
  private var cachedInstallParams: Map<String, Any> = emptyMap()
  private var cachedStartupParams: Map<String, Any> = emptyMap()
  private var cachedInitialDeepLink: WritableMap? = null
  private var cachedDebugLoggingEnabled: Boolean? = null
  private var deepLinkListenerInstalled = false

  override fun getName(): String = NAME

  @ReactMethod
  fun preInit(appKey: String, promise: Promise) {
    try {
      Tracking.preInit(reactContext.applicationContext, appKey)
      promise.resolve(null)
    } catch (error: Throwable) {
      promise.reject("ERR_PREINIT_FAILED", error.message, error)
    }
  }

  @ReactMethod
  fun initialize(options: ReadableMap, promise: Promise) {
    try {
      val application = getApplicationOrThrow()
      val parameters = InitParameters().apply {
        appKey = options.getString("appKey") ?: throw IllegalArgumentException("appKey is required")
        channelId = options.getString("channelId") ?: DEFAULT_CHANNEL_ID
        installParams = readableMapToTrackingMap(options.getMap("installParams"))
        startupParams = readableMapToTrackingMap(options.getMap("startupParams"))
      }

      cachedInstallParams = parameters.installParams ?: emptyMap()
      cachedStartupParams = parameters.startupParams ?: emptyMap()

      cachedDebugLoggingEnabled?.let(Tracking::setDebugMode)
      ensureDeepLinkListenerInstalled()
      Tracking.initWithKeyAndChannelId(application, parameters)
      hasInitialized = true
      promise.resolve(null)
    } catch (error: Throwable) {
      promise.reject("ERR_INITIALIZE_FAILED", error.message, error)
    }
  }

  @ReactMethod
  fun setDebugLogging(enabled: Boolean, promise: Promise) {
    try {
      cachedDebugLoggingEnabled = enabled
      Tracking.setDebugMode(enabled)
      promise.resolve(null)
    } catch (error: Throwable) {
      promise.reject("ERR_SET_DEBUG_LOGGING_FAILED", error.message, error)
    }
  }

  @ReactMethod
  fun setASAEnabled(enabled: Boolean, promise: Promise) {
    promise.reject("ERR_UNSUPPORTED", "setASAEnabled 仅支持 iOS")
  }

  @ReactMethod
  fun register(options: ReadableMap, promise: Promise) {
    if (!hasInitialized) {
      promise.reject("ERR_NOT_INITIALIZED", "initialize must be called before register")
      return
    }

    try {
      val accountId = options.getString("accountId")
        ?: throw IllegalArgumentException("accountId is required")
      val params = readableMapToTrackingMap(options.getMap("params"))

      if (params == null) {
        Tracking.setRegisterWithAccountID(accountId)
      } else {
        Tracking.setRegisterWithAccountID(accountId, params)
      }
      promise.resolve(null)
    } catch (error: Throwable) {
      promise.reject("ERR_REGISTER_FAILED", error.message, error)
    }
  }

  @ReactMethod
  fun login(options: ReadableMap, promise: Promise) {
    if (!hasInitialized) {
      promise.reject("ERR_NOT_INITIALIZED", "initialize must be called before login")
      return
    }

    try {
      val accountId = options.getString("accountId")
        ?: throw IllegalArgumentException("accountId is required")
      val params = readableMapToTrackingMap(options.getMap("params"))

      if (params == null) {
        Tracking.setLoginSuccessBusiness(accountId)
      } else {
        Tracking.setLoginSuccessBusiness(accountId, params)
      }
      promise.resolve(null)
    } catch (error: Throwable) {
      promise.reject("ERR_LOGIN_FAILED", error.message, error)
    }
  }

  @ReactMethod
  fun setAttributionParameter(gdtClickId: String, promise: Promise) {
    try {
      Tracking.setAttributionParameter(hashMapOf("gdtClickId" to gdtClickId))
      promise.resolve(null)
    } catch (error: Throwable) {
      promise.reject("ERR_SET_ATTRIBUTION_PARAMETER_FAILED", error.message, error)
    }
  }

  @ReactMethod
  fun getInstallParams(promise: Promise) {
    promise.resolve(trackingMapToWritableMap(cachedInstallParams))
  }

  @ReactMethod
  fun getStartupParams(promise: Promise) {
    promise.resolve(trackingMapToWritableMap(cachedStartupParams))
  }

  @ReactMethod
  fun getInitialDeepLink(promise: Promise) {
    promise.resolve(cachedInitialDeepLink)
  }

  @ReactMethod
  fun addListener(eventName: String) {}

  @ReactMethod
  fun removeListeners(count: Int) {}

  private fun getApplicationOrThrow(): Application {
    return reactContext.applicationContext as? Application
      ?: throw IllegalStateException("Application is not available")
  }

  private fun readableMapToTrackingMap(map: ReadableMap?): HashMap<String, Any>? {
    if (map == null) {
      return null
    }

    val result = HashMap<String, Any>()
    val iterator = map.keySetIterator()
    while (iterator.hasNextKey()) {
      val key = iterator.nextKey()
      when (map.getType(key)) {
        ReadableType.String -> map.getString(key)?.let { result[key] = it }
        ReadableType.Number -> result[key] = map.getDouble(key)
        else -> Unit
      }
    }
    return if (result.isEmpty()) null else result
  }

  private fun trackingMapToWritableMap(map: Map<String, Any>): WritableMap {
    val writableMap = Arguments.createMap()
    map.forEach { (key, value) ->
      when (value) {
        is String -> writableMap.putString(key, value)
        is Number -> writableMap.putDouble(key, value.toDouble())
      }
    }
    return writableMap
  }

  private fun ensureDeepLinkListenerInstalled() {
    if (deepLinkListenerInstalled) {
      return
    }

    Tracking.setDeepLinkListener(object : IDeepLinkListener {
      override fun onComplete(success: Boolean, data: String?) {
        if (!success || data.isNullOrBlank()) {
          return
        }

        val payload = buildDeepLinkPayload(data)
        if (cachedInitialDeepLink == null) {
          cachedInitialDeepLink = payload
        }
        emitDeepLinkEvent(payload)
      }
    })
    deepLinkListenerInstalled = true
  }

  private fun buildDeepLinkPayload(raw: String): WritableMap {
    val payload = Arguments.createMap()
    payload.putString("url", raw)

    val params = Arguments.createMap()
    val uri = Uri.parse(raw)
    for (name in uri.queryParameterNames) {
      uri.getQueryParameter(name)?.let { params.putString(name, it) }
    }
    payload.putMap("params", params)
    return payload
  }

  private fun emitDeepLinkEvent(payload: WritableMap) {
    reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit(DEEP_LINK_EVENT, payload)
  }

  companion object {
    const val NAME = "Mtrackingio"
    private const val DEEP_LINK_EVENT = "mtrackingio:deepLink"
    private const val DEFAULT_CHANNEL_ID = "_default_"
  }
}
