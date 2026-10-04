class_name ArtPack
extends RefCounted
## Sistema de packs de arte: texturas por NOMBRE con pack activo y fallback.
##
## art/sprites/ es el pack por defecto; art/packs/<id>/sprites/ contiene packs
## alternativos (p. ej. "original" = el pictórico previo al rediseño chunky).
## El pack activo persiste en user://settings.cfg ([art] pack=...). El título
## lo alterna con la tecla A (ArtPack.cycle_pack). Las llamadas son baratas:
## cada textura se resuelve una vez y queda en caché estática.

const BASE_DIR := "res://art/sprites"
const PACKS_DIR := "res://art/packs"
const CFG_PATH := "user://settings.cfg"

static var _cache: Dictionary = {}
static var _pack := ""
static var _loaded := false


static func _load_cfg() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) == OK:
		_pack = String(cf.get_value("art", "pack", ""))


static func active_pack() -> String:
	_load_cfg()
	return _pack


## "default" + un ID por carpeta de art/packs/ que tenga sprites/.
static func available_packs() -> Array[String]:
	var out: Array[String] = ["default"]
	var d := DirAccess.open(PACKS_DIR)
	if d != null:
		for sub in d.get_directories():
			if DirAccess.dir_exists_absolute("%s/%s/sprites" % [PACKS_DIR, sub]):
				out.append(sub)
	return out


static func set_active_pack(id: String) -> void:
	_load_cfg()
	_pack = "" if id == "default" else id
	_cache.clear()
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)
	cf.set_value("art", "pack", _pack)
	cf.save(CFG_PATH)


## Alterna al siguiente pack disponible y lo devuelve ("default" o su ID).
static func cycle_pack() -> String:
	var packs := available_packs()
	var idx := packs.find(active_pack())
	set_active_pack(packs[(idx + 1) % packs.size()])
	return packs[(idx + 1) % packs.size()]


## Textura por nombre base de fichero (sin ruta ni extensión), p. ej.
## "player_idle_p1", "tile_floor", "weapon_bow". Busca en el pack activo y,
## si no existe ahí, en art/sprites/. Devuelve null si no está en ninguno.
static func tex(name: String) -> Texture2D:
	_load_cfg()
	if _cache.has(name):
		return _cache[name]
	var t: Texture2D = null
	if _pack != "":
		var pp := "%s/%s/sprites/%s.png" % [PACKS_DIR, _pack, name]
		if ResourceLoader.exists(pp):
			t = load(pp)
	if t == null:
		var bp := "%s/%s.png" % [BASE_DIR, name]
		if ResourceLoader.exists(bp):
			t = load(bp)
	_cache[name] = t
	return t
