# Lesson-specific data; lifecycle, ordering, saving and return live in the base.
extends "res://scripts/ordered_lesson.gd"

const LESSON_ID := "lesson_2"
const TOTAL_TASKS := 3

func _ready() -> void:
	_configure_lesson(LESSON_ID, "Les 2 - Vormen op volgorde", [^"%CircleTarget", ^"%SquareTarget", ^"%TriangleTarget"])
