extends Node
## Banka zvuků. Všechno je 48 kHz OGG, špička −1 dBFS.

const CESTA := "res://assets/audio/%s.ogg"
var cache := {}
var hracky2d: Array[AudioStreamPlayer] = []

func stream(jmeno: String) -> AudioStream:
	if not cache.has(jmeno):
		var c := CESTA % jmeno
		cache[jmeno] = load(c) if ResourceLoader.exists(c) else null
	return cache[jmeno]

func hraj_2d(jmeno: String, hlasitost := 0.0) -> AudioStreamPlayer:
	var s := stream(jmeno)
	if s == null:
		return null
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = hlasitost
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p

func hraj_3d(jmeno: String, kde: Node3D, hlasitost := 0.0, dosah := 60.0,
		velikost := 1.0) -> AudioStreamPlayer3D:
	var s := stream(jmeno)
	if s == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.volume_db = hlasitost
	p.max_distance = dosah
	p.unit_size = velikost
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	kde.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p

func nahodny(seznam: Array) -> String:
	return seznam[randi() % seznam.size()]

const KROKY_HRAC := ["hrac_krok_01", "hrac_krok_02", "hrac_krok_03", "hrac_krok_04"]
const KROKY_KULHA := ["hrac_krok_kulha_01", "hrac_krok_kulha_02"]
const KROKY_SUT := ["hrac_krok_sut_01", "hrac_krok_sut_02"]
const KROKY_ZED := ["zed_step_01", "zed_step_02", "zed_step_03", "zed_step_04"]
const HLAS_ZED := ["zed_hlas_vola", "zed_hlas_vrci", "zed_hlas_smich", "zed_hlas_sepot"]
const SEKERA := ["sekera_zasah_01", "sekera_zasah_02", "sekera_zasah_03"]
