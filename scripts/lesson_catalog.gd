extends RefCounted

const CELEBRATION_PATH := "res://scenes/garden_celebration.tscn"
const SELECT_PATH := "res://scenes/lesson_select.tscn"

const COLOR_NAMES := {
	"red": "rood",
	"blue": "blauw",
	"yellow": "geel",
	"green": "groen",
}

const ORDERED_PROMPTS := {
	"circle": "Loop naar de cirkel.",
	"square": "Loop naar het vierkant.",
	"triangle": "Loop naar de driehoek.",
	"step_1": "Loop naar 1.",
	"step_2": "Loop naar 2.",
	"step_3": "Loop naar 3.",
	"step_4": "Loop naar 4.",
	"step_5": "Loop naar 5.",
}

const COUNT_PIPS := [
	[Vector2.ZERO],
	[Vector2(-1, -1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2.ZERO, Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)],
	[Vector2(-1, -1), Vector2(-1, 1), Vector2.ZERO, Vector2(1, -1), Vector2(1, 1)],
]

const LESSONS: Array[Dictionary] = [
	{
		"id": "lesson_1", "path": "res://scenes/lesson_1.tscn", "label": "Les 1",
		"preview": "res://assets/lessons/previews/lesson_1.webp",
		"caption": "Rood en blauw", "icon": "lesson_colors",
		"icon_colors": [Color(0.86, 0.16, 0.16), Color(0.13, 0.35, 0.82)],
		"prompt": "Raak rood en blauw aan. Pak ook de drie telstenen.",
	},
	{
		"id": "lesson_2", "path": "res://scenes/lesson_2.tscn", "label": "Les 2",
		"preview": "res://assets/lessons/previews/lesson_2.webp",
		"caption": "Vormen zoeken", "icon": "lesson_shapes",
		"prompt": "Eerst de cirkel, dan het vierkant, dan de driehoek.",
	},
	{
		"id": "lesson_3", "path": "res://scenes/lesson_3.tscn", "label": "Les 3",
		"preview": "res://assets/lessons/previews/lesson_3.webp",
		"caption": "Tel tot drie", "icon": "count_3",
		"prompt": "Loop eerst naar 1, dan naar 2 en dan naar 3.",
	},
	{
		"id": "lesson_4", "path": "res://scenes/lesson_4.tscn", "label": "Les 4",
		"preview": "res://assets/lessons/previews/lesson_4.webp",
		"caption": "Geel en groen", "icon": "lesson_colors",
		"icon_colors": [Color(0.98, 0.82, 0.18), Color(0.2, 0.65, 0.28)],
		"prompt": "Raak geel en groen aan. Pak ook de drie telstenen.",
	},
	{
		"id": "lesson_5", "path": "res://scenes/lesson_5.tscn", "label": "Les 5",
		"preview": "res://assets/lessons/previews/lesson_5.webp",
		"caption": "Tel tot vier", "icon": "count_4",
		"prompt": "Loop naar 1, 2, 3 en 4. Volg de volgorde.",
	},
	{
		"id": "lesson_6", "path": "res://scenes/lesson_6.tscn", "label": "Les 6",
		"preview": "res://assets/lessons/previews/lesson_6.webp",
		"caption": "Tel tot vijf", "icon": "count_5",
		"prompt": "Loop naar 1, 2, 3, 4 en 5. Volg de volgorde.",
	},
]


static func index_for_id(lesson_id: String) -> int:
	for index in LESSONS.size():
		if LESSONS[index]["id"] == lesson_id:
			return index
	return -1


## Find the next unfinished lesson, wrapping once after the last lesson.
static func next_unfinished_index(completed: Dictionary, after := -1) -> int:
	for offset in range(1, LESSONS.size() + 1):
		var index := (after + offset) % LESSONS.size()
		if index != after and not completed.has(LESSONS[index]["id"]):
			return index
	return -1


static func count_pips(number: int) -> PackedVector2Array:
	if number < 1 or number > COUNT_PIPS.size():
		return PackedVector2Array()
	return PackedVector2Array(COUNT_PIPS[number - 1])
