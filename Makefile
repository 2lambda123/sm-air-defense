
pp_out ?= "pp_main.lua"
minify_out ?= "minified_main.lua"

lua ?= lua
minify_command := $(lua) "./lua-minify/minify.lua" minify $(pp_out)

clippath ?= "clip.exe"

.DEFAULT_GOAL = clip

clip: preprocess
	$(minify_command) | $(clippath)
minify: preprocess
	$(minify_command) > $(minify_out)

preprocess:
	$(lua) "./LuaPreprocess/preprocess-cl.lua" -o main.lua $(pp_out)
