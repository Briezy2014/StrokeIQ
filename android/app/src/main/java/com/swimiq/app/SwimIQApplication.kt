package com.swimiq.app

import android.app.Application
import com.swimiq.app.data.SupabaseProvider

class SwimIQApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SupabaseProvider.init(this)
    }
}
