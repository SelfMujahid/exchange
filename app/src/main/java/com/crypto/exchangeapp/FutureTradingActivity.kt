package com.crypto.exchangeapp

import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.gson.JsonParser
import kotlinx.coroutines.*
import okhttp3.*
import java.io.IOException
import java.net.InetAddress
import java.net.Proxy
import java.util.concurrent.TimeUnit

class FutureTradingActivity : AppCompatActivity() {

    // Hum variables ko nullable bana rahe hain taaki crash ka koi chance na rahe
    private var tvSymbol: TextView? = null
    private var tvPrice: TextView? = null
    private var tvChange: TextView? = null

    private var webSocket: WebSocket? = null
    private var selectedSymbol = "BTCUSDT"
    private lateinit var client: OkHttpClient

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // XML LAYOUT BYPASS: Hum XML file load hi nahi kar rahe taaki missing ID ka crash khatam ho jaye
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#161A20")) // Binance Dark Theme
            padding = 50
        }

        tvSymbol = TextView(this).apply {
            text = selectedSymbol
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        tvPrice = TextView(this).apply {
            text = "Initializing Network..."
            textSize = 22f
            setTextColor(Color.parseColor("#848E9C"))
            gravity = Gravity.CENTER
            setPadding(0, 30, 0, 30)
        }

        tvChange = TextView(this).apply {
            text = "24h: --"
            textSize = 18f
            setTextColor(Color.GRAY)
            gravity = Gravity.CENTER
        }

        rootLayout.addView(tvSymbol)
        rootLayout.addView(tvPrice)
        rootLayout.addView(tvChange)

        // Screen par direct layout set kar rahe hain
        setContentView(rootLayout)

        setupAuthenticNetworkEngine()
        startTargetedWebSocket(selectedSymbol)
    }

    private fun setupAuthenticNetworkEngine() {
        client = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .eventListener(object : EventListener() {
                override fun dnsStart(call: Call, domainName: String) {
                    printDiagnostic("Step 1: Checking Domain...")
                }
                override fun connectStart(call: Call, inetSocketAddress: java.net.InetSocketAddress, proxy: Proxy) {
                    printDiagnostic("Step 2: Starting TCP Pipe...")
                }
                override fun secureConnectStart(call: Call) {
                    printDiagnostic("Step 3: Checking SSL Certificate...")
                }
                override fun connectEnd(call: Call, inetSocketAddress: java.net.InetSocketAddress, proxy: Proxy, protocol: Protocol?) {
                    printDiagnostic("Step 4: Network Connected!")
                }
                override fun connectFailed(call: Call, inetSocketAddress: java.net.InetSocketAddress, proxy: Proxy, protocol: Protocol?, ioe: IOException) {
                    printDiagnostic("Handshake Stop: ${ioe.localizedMessage}")
                }
            })
            .build()
    }

    private fun printDiagnostic(statusMessage: String) {
        lifecycleScope.launch(Dispatchers.Main) {
            tvPrice?.text = statusMessage
            tvPrice?.setTextColor(Color.parseColor("#848E9C"))
        }
    }

    private fun startTargetedWebSocket(symbol: String) {
        webSocket?.close(1000, "Reset")
        val wsUrl = "wss://fstream.binance.com/ws/${symbol.lowercase()}@ticker"
        
        val request = Request.Builder()
            .url(wsUrl)
            .header("User-Agent", "Mozilla/5.0")
            .build()

        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                lifecycleScope.launch(Dispatchers.Main) {
                    tvPrice?.text = "Receiving Live Stream..."
                    tvPrice?.setTextColor(Color.parseColor("#0ECB81"))
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val jsonObject = JsonParser.parseString(text).asJsonObject
                    val price = jsonObject.get("c").asString.toDouble()
                    val change = jsonObject.get("P").asString.toDouble()

                    lifecycleScope.launch(Dispatchers.Main) {
                        tvPrice?.text = String.format("$%.2f", price)
                        tvChange?.text = String.format("24h: %.2f%%", change)

                        if (change >= 0) {
                            tvPrice?.setTextColor(Color.parseColor("#0ECB81"))
                        } else {
                            tvPrice?.setTextColor(Color.parseColor("#F6465D"))
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                lifecycleScope.launch(Dispatchers.Main) {
                    tvPrice?.text = "Reconnecting..."
                    tvPrice?.setTextColor(Color.parseColor("#F6465D"))
                    delay(5000)
                    startTargetedWebSocket(selectedSymbol)
                }
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        webSocket?.close(1000, "Exit")
    }
}
