extends ProgressBar

var thread
var generator

func _ready():
	generator = $"/root/Root/Generator"
	thread = Thread.new()
	thread.start(generator, "start_generation", self)
