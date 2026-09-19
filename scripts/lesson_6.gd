# Lesson-specific data; lifecycle, ordering, saving and return live in the base.
extends "res://scripts/ordered_lesson.gd"

const LESSON_ID := "lesson_6"
const TOTAL_TASKS := 5

func _ready() -> void:
	_configure_lesson(LESSON_ID, "Les 6 - Van 1 naar 5", [^"%Step1Target", ^"%Step2Target", ^"%Step3Target", ^"%Step4Target", ^"%Step5Target"])
