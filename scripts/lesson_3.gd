# Lesson-specific data; lifecycle, ordering, saving and return live in the base.
extends "res://scripts/ordered_lesson.gd"

const LESSON_ID := "lesson_3"
const TOTAL_TASKS := 3

func _ready() -> void:
	_configure_lesson(LESSON_ID, "Les 3 - Van 1 naar 3", [^"%Step1Target", ^"%Step2Target", ^"%Step3Target"])
