package com.crypto.exchangeapp

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import android.os.PowerManager
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

    private lateinit var tvSymbol: TextView
    private lateinit var tvPrice: TextView
    private lateinit var tvChange: TextView
    private lateinit var tvHigh: TextView
    private lateinit var tvLow: TextView

    private var webSocket: WebSocket? = null
    private var selectedSymbol = "BTCUSDT"
    private lateinit var client: OkHttpClient
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Safety Layer: Agar layout inflation mein bhi koi masla ho toh handles exception
        try {
            setContentView(R.layout.activity_future_trading)
            
            tvSymbol = findViewById(R.id.tvSymbol)
            tvPrice = findViewById(R.id.tvPrice)
            tvChange = findViewById(R.id.tvChange)
            tvHigh = findViewById(R.id.tvHigh)
            tvLow = findViewById(R.id.tvLow)

            tvSymbol.text = selectedSymbol
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Safe WakeLock Configuration (Crash Proof Barrier)
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ExchangeApp::NetworkWakeLock")
            wakeLock?.acquire(5 * 60 * 1000L /*5 Minutes Safety Window*/)
        } catch (e: Exception) {
            // Android OS agar block karega toh app close nahi hogi, default mode par chalegi
            e.printStackTrace()
        }

        setupAuthenticNetworkEngine()
        startTargetedWebSocket(selectedSymbol)
    }

    private fun setupAuthenticNetworkEngine() {
        client = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .writeTimeout(15, TimeUnit.SECONDS)
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
            if (::tvPrice.isInitialized) {
                tvPrice.text = statusMessage
                tvPrice.setTextColor(Color.parseColor("#848E9C"))
            }
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
                    if (::tvPrice.isInitialized) {
                        tvPrice.text = "Receiving Live Stream..."
                        tvPrice.setTextColor(Color.parseColor("#0ECB81"))
                    }
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val jsonObject = JsonParser.parseString(text).asJsonObject
                    val price = jsonObject.get("c").asString.toDouble()
                    val change = jsonObject.get("P").asString.toDouble()
                    val high = jsonObject.get("h").asString.toDouble()
                    val low = jsonObject.get("l").asString.toDouble()

                    lifecycleScope.launch(Dispatchers.Main) {
                        if (::tvPrice.isInitialized) {
                            tvPrice.text = String.format("$%.2f", price)
                            tvChange.text = String.format("24h: %.2f%%", change)
                            tvHigh.text = String.format("High: %.1f", high)
                            tvLow.text = String.format("Low: %.1f", low)

                            if (change >= 0) {
                                tvPrice.setTextColor(Color.parseColor("#0ECB81"))
                            } else {
                                tvPrice.setTextColor(Color.parseColor("#F6465D"))
                            }
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                lifecycleScope.launch(Dispatchers.Main) {
                    if (::tvPrice.isInitialized) {
                        tvPrice.text = "Reconnecting Tunnel..."
                        tvPrice.setTextColor(Color.parseColor("#F6465D"))
                    }
                    delay(5000)
                    startTargetedWebSocket(selectedSymbol)
                }
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        webSocket?.close(1000, "Exit")
    }
}
