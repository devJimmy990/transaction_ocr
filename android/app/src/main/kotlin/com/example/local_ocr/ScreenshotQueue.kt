package com.example.local_ocr
import java.util.concurrent.ConcurrentLinkedQueue

class ScreenshotQueue {
    private val queue = ConcurrentLinkedQueue<String>()
    
    fun add(imagePath: String) {
        queue.offer(imagePath)
    }
    
    fun poll(): String? {
        return queue.poll()
    }
    
    fun size(): Int {
        return queue.size
    }
    
    fun isEmpty(): Boolean {
        return queue.isEmpty()
    }
    
    fun clear() {
        queue.clear()
    }
}