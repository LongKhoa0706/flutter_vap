package com.nell.flutter_vap

import android.content.Context
import android.view.View
import com.tencent.qgame.animplayer.AnimConfig
import com.tencent.qgame.animplayer.AnimView
import com.tencent.qgame.animplayer.inter.IAnimListener
import com.tencent.qgame.animplayer.util.ScaleType
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import java.io.File


internal class NativeVapView(binaryMessenger: BinaryMessenger, context: Context, id: Int, creationParams: Map<String?, Any?>?) : MethodChannel.MethodCallHandler, PlatformView {
    private val mContext: Context = context

    private val vapView: AnimView = AnimView(context)
    private var channel: MethodChannel
    private var methodResult: MethodChannel.Result? = null
    private var loop : Int = 0
    private var methodCall: MethodCall? = null
    init {
        vapView.setScaleType(ScaleType.FIT_XY)
        vapView.setAnimListener(object : IAnimListener {
            override fun onFailed(errorType: Int, errorMsg: String?) {
                GlobalScope.launch(Dispatchers.Main) {
                    methodResult?.success(HashMap<String, String>().apply {
                        put("status", "failure")
                        put("errorMsg", errorMsg ?: "unknown error")
                    })

                }
            }

            override fun onVideoComplete() {
                GlobalScope.launch(Dispatchers.Main) {
                    methodResult?.success(HashMap<String, String>().apply {
                        put("status", "complete")
                    })
                }
            }

            override fun onVideoDestroy() {
            }

            override fun onVideoRender(frameIndex: Int, config: AnimConfig?) {
            }

            override fun onVideoStart() {
            }

        })
        channel = MethodChannel(binaryMessenger, "flutter_vap_controller")
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View {
        return vapView
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)

    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        methodResult = result
        methodCall = call
        loop = call.argument<Int>("loop") ?: 0
        vapView.setLoop(loop);
        when (call.method) {
            "playPath" -> {
                call.argument<String>("path")?.let {
                    vapView.startPlay(File(it))
                }
            }
            "playAsset" -> {
                call.argument<String>("asset")?.let {
                    vapView.startPlay(mContext.assets, "flutter_assets/$it")
                }
            }
            "stop" -> {
                vapView.stopPlay()
            }
        }
    }


}