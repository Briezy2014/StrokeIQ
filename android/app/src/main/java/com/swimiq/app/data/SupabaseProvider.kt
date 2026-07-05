package com.swimiq.app.data

import android.content.Context
import com.swimiq.app.BuildConfig
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.postgrest.Postgrest

object SupabaseProvider {
    lateinit var client: io.github.jan.supabase.SupabaseClient
        private set

    fun init(context: Context) {
        if (::client.isInitialized) return

        client = createSupabaseClient(
            supabaseUrl = BuildConfig.SUPABASE_URL,
            supabaseKey = BuildConfig.SUPABASE_KEY,
        ) {
            install(Auth)
            install(Postgrest)
        }
    }
}
