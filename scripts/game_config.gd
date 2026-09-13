class_name GameConfig
## Stats de las armas y orden del ciclo de muerte. Compartido por game y player.

const WEAPON_ORDER := ["florete", "espada", "daga", "arco"]

const WEAPONS := {
	"florete": {
		"nombre": "FLORETE", "dur": 0.30, "from": 0.07, "to": 0.20, "reach": 86.0,
		"run_mult": 1.0, "thrown_speed": 760.0,
		"thrown_kills": ["LOW", "MID", "HIGH"],
		"blade_len": 1.0, "blade_w": 4.0, "disarms": false,
	},
	"espada": {
		"nombre": "ESPADÓN", "dur": 0.42, "from": 0.16, "to": 0.30, "reach": 118.0,
		"run_mult": 0.92, "thrown_speed": 620.0,
		"thrown_kills": ["LOW", "MID", "HIGH"],
		"blade_len": 1.3, "blade_w": 6.0, "disarms": true,
	},
	"daga": {
		"nombre": "DAGA", "dur": 0.20, "from": 0.05, "to": 0.13, "reach": 58.0,
		"run_mult": 1.15, "thrown_speed": 980.0,
		"thrown_kills": ["HIGH"],
		"blade_len": 0.6, "blade_w": 3.0, "disarms": false,
	},
	"arco": {
		"nombre": "ARCO", "dur": 0.0, "from": 0.0, "to": 0.0, "reach": 0.0,
		"run_mult": 0.92, "thrown_speed": 0.0,
		"thrown_kills": [],
		"blade_len": 1.0, "blade_w": 4.0, "disarms": false,
		"bow": true, "arrow_speed": 600.0,
	},
}
