extends Node
# 音频管理器

@export_category("音频设置")
@export var master_volume: float = 1.0
@export var music_volume: float = 0.8
@export var sfx_volume: float = 1.0
@export var voice_volume: float = 1.0

signal volume_changed(bus_name: String, volume: float)
signal music_changed(track_name: String)
signal sfx_played(sfx_name: String)

var music_players: Array[AudioStreamPlayer] = []
var sfx_players: Array[AudioStreamPlayer] = []
var current_music: String = ""
var music_queue: Array[String] = []

static var instance: Node

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	print("AudioManager 已加载")
	
	# 初始化音频播放器
	_initialize_audio_players()
	
	# 设置音量
	_update_volumes()
	
	# 监听事件
	if EventBus.instance:
		EventBus.instance.game_state_changed.connect(_on_game_state_changed)
		EventBus.instance.level_started.connect(_on_level_started)
		EventBus.instance.player_died.connect(_on_player_died)
	
	print("音频系统初始化完成")

func _initialize_audio_players():
	# 创建2个音乐播放器用于交叉淡入淡出
	for i in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "MusicPlayer%d" % i
		player.bus = "Music"
		player.volume_db = linear_to_db(music_volume)
		add_child(player)
		music_players.append(player)
	
	# 创建8个SFX播放器池
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = "SFX"
		player.volume_db = linear_to_db(sfx_volume)
		add_child(player)
		sfx_players.append(player)
	
	print("创建了 %d 个音乐播放器和 %d 个SFX播放器" % [music_players.size(), sfx_players.size()])

func _update_volumes():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), linear_to_db(voice_volume))

func play_music(track_path: String, fade_duration: float = 1.0):
	var track_name = track_path.get_file().get_basename()
	if current_music == track_name:
		return
	
	print("播放音乐: %s" % track_name)
	current_music = track_name
	
	# 加载音频
	var stream = load(track_path)
	if not stream:
		print("无法加载音乐文件: %s" % track_path)
		return
	
	# 交叉淡入淡出
	if music_players[0].playing:
		# 淡出当前播放器
		var tween = create_tween()
		tween.tween_property(music_players[0], "volume_db", -80.0, fade_duration)
		tween.tween_callback(music_players[0].stop)
		
		# 切换到另一个播放器
		music_players.reverse()
	
	# 设置新音乐
	music_players[0].stream = stream
	music_players[0].volume_db = -80.0
	music_players[0].play()
	
	# 淡入
	var tween = create_tween()
	tween.tween_property(music_players[0], "volume_db", linear_to_db(music_volume), fade_duration)
	
	emit_signal("music_changed", track_name)

func play_sfx(sfx_path: String, pitch_variation: float = 0.0, volume_variation: float = 0.0):
	# 查找空闲的SFX播放器
	var player: AudioStreamPlayer = null
	for p in sfx_players:
		if not p.playing:
			player = p
			break
	
	if not player:
		# 如果没有空闲的，使用第一个
		player = sfx_players[0]
		player.stop()
	
	# 加载音频
	var stream = load(sfx_path)
	if not stream:
		print("无法加载SFX文件: %s" % sfx_path)
		return
	
	var sfx_name = sfx_path.get_file().get_basename()
	
	# 设置音频
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.volume_db = linear_to_db(sfx_volume) + randf_range(-volume_variation, volume_variation)
	player.play()
	
	emit_signal("sfx_played", sfx_name)
	print("播放SFX: %s" % sfx_name)

func stop_music(fade_duration: float = 1.0):
	if music_players[0].playing:
		var tween = create_tween()
		tween.tween_property(music_players[0], "volume_db", -80.0, fade_duration)
		tween.tween_callback(music_players[0].stop)
		current_music = ""

func set_volume(bus_name: String, volume: float):
	match bus_name:
		"Master":
			master_volume = volume
		"Music":
			music_volume = volume
		"SFX":
			sfx_volume = volume
		"Voice":
			voice_volume = volume
	
	_update_volumes()
	emit_signal("volume_changed", bus_name, volume)

func _on_game_state_changed(old_state, new_state):
	match new_state:
		"PAUSED":
			set_volume("Music", music_volume * 0.5)
		"PLAYING":
			set_volume("Music", music_volume)
		"MAIN_MENU":
			play_music("res://assets/audio/music/main_theme.ogg")

func _on_level_started(level_id: String):
	match level_id:
		"level_01":
			play_music("res://assets/audio/music/level_01.ogg")
		"boss_level":
			play_music("res://assets/audio/music/boss_battle.ogg")

func _on_player_died(_cause: String):
	play_sfx("res://assets/audio/sfx/characters/player_death.ogg")
