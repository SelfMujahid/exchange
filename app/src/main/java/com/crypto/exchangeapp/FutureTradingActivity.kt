package com.crypto.exchangeapp

import android.graphics.Color
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.BaseAdapter
import android.widget.ListView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.google.gson.JsonParser
import kotlinx.coroutines.*
import okhttp3.*
import java.io.IOException
import java.util.concurrent.TimeUnit

data class CryptoAsset(val symbol: String, var price: String)

class FutureTradingActivity : AppCompatActivity() {

    private lateinit var tvSymbol: TextView
    private lateinit var tvPrice: TextView
    private lateinit var tvChange: TextView
    private lateinit var tvHigh: TextView
    private lateinit var tvLow: TextView
    private lateinit var lvCryptoPairs: ListView

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    private var webSocket: WebSocket? = null
    private var selectedSymbol = "BTCUSDT"
    private var cryptoList = ArrayList<CryptoAsset>()
    private lateinit var listAdapter: CryptoListAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_future_trading)

        tvSymbol = findViewById(R.id.tvSymbol)
        tvPrice = findViewById(R.id.tvPrice)
        tvChange = findViewById(R.id.tvChange)
        tvHigh = findViewById(R.id.tvHigh)
        tvLow = findViewById(R.id.tvLow)
        lvCryptoPairs = findViewById(R.id.lvCryptoPairs)

        listAdapter = CryptoListAdapter(cryptoList)
        lvCryptoPairs.adapter = listAdapter

        lvCryptoPairs.setOnItemClickListener { _, _, position, _ ->
            selectedSymbol = cryptoList[position].symbol
            tvSymbol.text = selectedSymbol
            tvPrice.text = "Switching..."
            startTargetedWebSocket(selectedSymbol)
        }

        fetchAllBinanceFuturesPairs()
    }

    private fun fetchAllBinanceFuturesPairs() {
        val request = Request.Builder()
            .url("https://fapi.binance.com/fapi/v1/ticker/24hr")
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                lifecycleScope.launch(Dispatchers.Main) {
                    tvPrice.text = "Network Error. Retrying..."
                    delay(5000)
                    fetchAllBinanceFuturesPairs()
                }
            }

            override fun onResponse(call: Call, response: Response) {
                val body = response.body?.string() ?: return
                try {
                    val jsonArray = JsonParser.parseString(body).asJsonArray
                    val temporaryBufferList = ArrayList<CryptoAsset>()

                    for (element in jsonArray) {
                        val obj = element.asJsonObject
                        val symbol = obj.get("symbol").asString
                        if (symbol.endsWith("USDT")) {
                            val priceRaw = obj.get("lastPrice").asDouble
                            temporaryBufferList.add(CryptoAsset(symbol, String.format("%.2f", priceRaw)))
                        }
                    }

                    lifecycleScope.launch(Dispatchers.Main) {
                        cryptoList.clear()
                        cryptoList.addAll(temporaryBufferList)
                        listAdapter.notifyDataSetChanged()
                        startTargetedWebSocket(selectedSymbol)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        })
    }

    private fun startTargetedWebSocket(symbol: String) {
        webSocket?.close(1000, "Switching Stream")
        
        val targetStream = symbol.lowercase()
        val wsUrl = "wss://fstream.binance.com/ws/$targetStream@ticker"
        
        val request = Request.Builder()
            .url(wsUrl)
            .header("User-Agent", "Mozilla/5.0 (Android; Mobile)")
            .build()

        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(webSocket: WebSocket, response: Response) {
                lifecycleScope.launch(Dispatchers.Main) {
                    tvPrice.text = "Syncing Data..."
                }
            }

            override fun onMessage(webSocket: WebSocket, text: String) {
                try {
                    val jsonObject = JsonParser.parseString(text).asJsonObject
                    
                    // Safe Extraction: Crash aur freeze se bachane ke liye safe strings to double
                    val price = jsonObject.get("c").asString.toDouble()
                    val change = jsonObject.get("P").asString.toDouble()
                    val high = jsonObject.get("h").asString.toDouble()
                    val low = jsonObject.get("l").asString.toDouble()

                    lifecycleScope.launch(Dispatchers.Main) {
                        tvPrice.text = String.format("$%.2f", price)
                        tvChange.text = String.format("24h: %.2f%%", change)
                        tvHigh.text = String.format("High: %.1f", high)
                        tvLow.text = String.format("Low: %.1f", low)

                        if (change >= 0) {
                            tvPrice.setTextColor(Color.parseColor("#0ECB81")) // Green
                        } else {
                            tvPrice.setTextColor(Color.parseColor("#F6465D")) // Red
                        }

                        val matchedIndex = cryptoList.indexOfFirst { it.symbol == symbol }
                        if (matchedIndex != -1) {
                            cryptoList[matchedIndex].price = String.format("%.2f", price)
                            listAdapter.notifyDataSetChanged()
                        }
                    }
                } catch (e: Exception) {
                    lifecycleScope.launch(Dispatchers.Main) {
                        tvPrice.text = "Format Error"
                    }
                }
            }

            override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                lifecycleScope.launch(Dispatchers.Main) {
                    tvPrice.text = "Reconnecting Tunnel..."
                    delay(3000)
                    startTargetedWebSocket(selectedSymbol)
                }
            }
        })
    }

    override fun onDestroy() {
        super.onDestroy()
        webSocket?.close(1000, "Destroyed")
    }

    inner class CryptoListAdapter(private val list: ArrayList<CryptoAsset>) : BaseAdapter() {
        override fun getCount(): Int = list.size
        override fun getItem(position: Int): Any = list[position]
        override fun getItemId(position: Int): Long = position.toLong()

        override fun getView(position: Int, convertView: View?, parent: ViewGroup?): View {
            val view: View = convertView ?: LayoutInflater.from(this@FutureTradingActivity)
                .inflate(R.layout.item_crypto_pair, parent, false)

            val sym = view.findViewById<TextView>(R.id.itemSymbol)
            val prc = view.findViewById<TextView>(R.id.itemPrice)

            val currentData = list[position]
            sym.text = currentData.symbol
            prc.text = "$${currentData.price}"

            return view
        }
    }
}
