package com.example.widget_habit_app

import kotlinx.serialization.Serializable

@Serializable
data class HabitWidgetData(
    val name: String,
    val completed: Boolean
) 