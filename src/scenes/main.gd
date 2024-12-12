extends Control

@onready var memory_usage: Label = $MemoryUsage
@onready var game_type_selector: OptionButton = $GameTypeSelector
@onready var game_type_text: Label = $GameTypeText
@onready var game_type_sub_text: Label = $GameTypeSubText

# Game types must be in alphabetical order

enum {
	THREELDK = 0, # 3LDK - Shiawase ni Narouyo
	ANGELSFEATHER,
	ANGELWISH,
	CASTLEFANTASIA,
	COLORFULAQUA,
	DABLACK,
	DAWHITE,
	DCTWO,
	DCFS,
	DCIF,
	DCORIGIN,
	DCPS,
	DEARMYFRIEND,
	DOKOHE,
	DOUBLEWISH,
	EF,
	FANATIC,
	FINALA2,
	FINALIST,
	FUKAKUTEI,
	FUTAKOI,
	FUTAKOIJIMA,
	GIFTPRISIM,
	GINNOECLIPSE, 
	HAPPYBREED,
	HAPPYDELUCKS,
	HARUKAZEPS,
	HOOLIGAN, 
	HOKENSHITSU,
	HURRAH,
	ICHIGOHUNDRED,
	IINAZUKE,
	JUUJIGEN,
	KIRAKIRA, 
	KOKORONOTOBIRA, 
	LOVEDOLL,
	MAGICAL,
	MAIHIME,
	MENATWORK3,
	METALWOLF,
	MISSINGBLUE,
	MOEKAN,
	MYSTEREET,
	NATSUIROHOSHI,
	NATSUIROKOMACHI,
	NORTHWIND,
	OJOUSAMAKUMI,
	ORANGEPOCKET,
	OUKA,
	PATISSERIE,
	PHANTOMINFERNO, 
	PIA3, 
	PRINCESSLOVER,
	PRINCESSPRINCESS,
	PRISAGA,
	PRISMARK,
	PUREPURE,
	QUILT,
	REGISTA, # temp value
	ROZENDUEL,
	SAISHUUSHIKEN,
	SAKURASESTU,
	SCHOOLLOVE,
	SCHOOLNI,
	STARTRAIN,
	STRAWBERRYPANIC,
	SUIKA,
	SWEETLEGACY, 
	TROUBLEFORTUNE,
	TRUETEARS,
	YATOHIME,
	YOJINBO,
	YUMEMI,
	YUMEMISHI,
	ZEROSYSTEM}
	
var game_type:int = FUTAKOI

func _ready() -> void:
	Engine.max_fps = 60
	
	initMenuItems()
	
	game_type_selector.select(game_type)
	game_type_text.text = "Choose game format type:"


func _process(_delta: float) -> void:
	var MEM: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var MEM2: float = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	memory_usage.text = str("%.3f MB / %.3f MB" % [MEM * 0.000001, MEM2 * 0.000001])


func _on_game_type_selector_item_selected(index: int) -> void:
	if index == THREELDK:
		game_type_sub_text.text = "Supports '3LDK - Shiawase ni Narouyo'."
		game_type_selector.select(THREELDK)
		game_type = THREELDK
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == COLORFULAQUA:
		game_type_sub_text.text = "Supports 'Colorful Aquarium: My Little Mermaid'."
		game_type_selector.select(COLORFULAQUA)
		game_type = COLORFULAQUA
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem2.tscn")
		sceneChanger(next_scene)
	elif index == MENATWORK3:
		game_type_sub_text.text = "Supports 'Men at Work! 3: Ai to Seishun no Hunter Gakuen'."
		game_type_selector.select(MENATWORK3)
		game_type = MENATWORK3
		var next_scene: PackedScene = load("res://src/scenes/TamTam.tscn")
		sceneChanger(next_scene)
	elif index == ANGELSFEATHER:
		game_type_sub_text.text = "Supports 'Angel's Feather'."
		game_type_selector.select(ANGELSFEATHER)
		game_type = ANGELSFEATHER
		var next_scene: PackedScene = load("res://src/scenes/TamTam.tscn")
		sceneChanger(next_scene)
	elif index == CASTLEFANTASIA:
		game_type_sub_text.text = "Supports 'Castle Fantasia: Erencia Senki - Plus Stories'."
		game_type_selector.select(CASTLEFANTASIA)
		game_type = CASTLEFANTASIA
		var next_scene: PackedScene = load("res://src/scenes/TamTam.tscn")
		sceneChanger(next_scene)
	elif index == DCTWO:
		game_type_sub_text.text = "Supports 'D.C. II P.S.: Da Capo II Plus Situation'."
		game_type_selector.select(DCTWO)
		game_type = DCTWO
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == DCFS:
		game_type_sub_text.text = "Supports 'D.C.F.S.: Da Capo Four Seasons'."
		game_type_selector.select(DCFS)
		game_type = DCFS
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == DCIF:
		game_type_sub_text.text = "Supports 'D.C.I.F.: Da Capo Innocent Finale'."
		game_type_selector.select(DCIF)
		game_type = DCIF
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == DCORIGIN:
		game_type_sub_text.text = "Supports 'D.C.: The Origin'."
		game_type_selector.select(DCORIGIN)
		game_type = DCORIGIN
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == DCPS:
		game_type_sub_text.text = "Supports D.C.P.S.: Da Capo Plus Situation."
		game_type_selector.select(DCPS)
		game_type = DCPS
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == DABLACK:
		game_type_sub_text.text = "Supports 'D-A: Black' (except character images)."
		game_type_selector.select(DABLACK)
		game_type = DABLACK
		var next_scene: PackedScene = load("res://src/scenes/TonkinHouse.tscn")
		sceneChanger(next_scene)
	elif index == DAWHITE:
		game_type_sub_text.text = "Supports 'D-A: White' (except character images)."
		game_type_selector.select(DAWHITE)
		game_type = DAWHITE
		var next_scene: PackedScene = load("res://src/scenes/TonkinHouse.tscn")
		sceneChanger(next_scene)
	elif index == DOKOHE:
		game_type_sub_text.text = "Supports 'Doko he Iku no, Anohi'."
		game_type_selector.select(DOKOHE)
		game_type = DOKOHE
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == DOUBLEWISH:
		game_type_sub_text.text = "Supports 'Double Wish'."
		game_type_selector.select(DOUBLEWISH)
		game_type = DOUBLEWISH
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == EF:
		game_type_sub_text.text = "Supports 'ef: A Fairy Tale of the Two'."
		game_type_selector.select(EF)
		game_type = EF
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem2.tscn")
		sceneChanger(next_scene)
	elif index == FANATIC:
		game_type_sub_text.text = "Supports 'F: Fanatic'."
		game_type_selector.select(FANATIC)
		game_type = FANATIC
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == DEARMYFRIEND:
		game_type_sub_text.text = "Supports 'Dear My Friend: Love Like Powdery Snow'."
		game_type_selector.select(DEARMYFRIEND)
		game_type = DEARMYFRIEND
		var next_scene: PackedScene = load("res://src/scenes/TamTam.tscn")
		sceneChanger(next_scene)
	elif index == MOEKAN:
		game_type_sub_text.text = "Supports 'Moekan: Moekko Company'."
		game_type_selector.select(MOEKAN)
		game_type = MOEKAN
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == NATSUIROHOSHI:
		game_type_sub_text.text = "Supports 'Natsuiro: Hoshikuzu no Memory'."
		game_type_selector.select(NATSUIROHOSHI)
		game_type = NATSUIROHOSHI
		var next_scene: PackedScene = load("res://src/scenes/TamTam.tscn")
		sceneChanger(next_scene)
	elif index == FINALIST:
		game_type_sub_text.text = "Supports 'Finalist' (temp)."
		game_type_selector.select(FINALIST)
		game_type = FINALIST
		var next_scene: PackedScene = load("res://src/scenes/TamTam.tscn")
		sceneChanger(next_scene)
	elif index == FINALA2:
		game_type_sub_text.text = "Supports 'Final Approach 2 - 1st Priority'."
		game_type_selector.select(FINALA2)
		game_type = FINALA2
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == FUKAKUTEI:
		game_type_sub_text.text = "Supports 'Fukakutei Sekai no Tantei Shinshi: Akugyou Futaasa no Jiken File'."
		game_type_selector.select(FUKAKUTEI)
		game_type = FUKAKUTEI
		var next_scene: PackedScene = load("res://src/scenes/AbelSoft.tscn")
		sceneChanger(next_scene)
	elif index == FUTAKOI:
		game_type_sub_text.text = "Supports 'Futakoi'."
		game_type_selector.select(FUTAKOI)
		game_type = FUTAKOI
		var next_scene: PackedScene = load("res://src/scenes/AlphaUnit.tscn")
		sceneChanger(next_scene)
	elif index == FUTAKOIJIMA:
		game_type_sub_text.text = "Supports 'Futakoijima: Koi to Mizugi no Survival'."
		game_type_selector.select(FUTAKOIJIMA)
		game_type = FUTAKOIJIMA
		var next_scene: PackedScene = load("res://src/scenes/AlphaUnit.tscn")
		sceneChanger(next_scene)
	elif index == GIFTPRISIM:
		game_type_sub_text.text = "Supports 'Gift: Prism'."
		game_type_selector.select(GIFTPRISIM)
		game_type = GIFTPRISIM
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == GINNOECLIPSE:
		game_type_sub_text.text = "Supports 'Gin no Eclipse'."
		game_type_selector.select(GINNOECLIPSE)
		game_type = GINNOECLIPSE
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == HAPPYBREED:
		game_type_sub_text.text = "Supports 'Happy Breeding: Cheerful Party'."
		game_type_selector.select(HAPPYBREED)
		game_type = HAPPYBREED
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == HAPPYDELUCKS:
		game_type_sub_text.text = "Supports 'Happiness! De-Lucks'."
		game_type_selector.select(HAPPYDELUCKS)
		game_type = HAPPYDELUCKS
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == HARUKAZEPS:
		game_type_sub_text.text = "Supports 'Harukaze P.S: Plus Situation'."
		game_type_selector.select(HARUKAZEPS)
		game_type = HARUKAZEPS
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == HOKENSHITSU:
		game_type_sub_text.text = "Supports 'Hokenshitsu he Youkoso'."
		game_type_selector.select(HOKENSHITSU)
		game_type = HOKENSHITSU
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == HURRAH:
		game_type_sub_text.text = "Supports 'Hurrah! Sailor'."
		game_type_selector.select(HURRAH)
		game_type = HURRAH
		var next_scene: PackedScene = load("res://src/scenes/DatamPolystar.tscn")
		sceneChanger(next_scene)
	elif index == JUUJIGEN:
		game_type_sub_text.text = "Supports 'Juujigen Rippoutai Cipher: Game of Survival'."
		game_type_selector.select(JUUJIGEN)
		game_type = JUUJIGEN
		var next_scene: PackedScene = load("res://src/scenes/AbelSoft.tscn")
		sceneChanger(next_scene)
	elif index == IINAZUKE:
		game_type_sub_text.text = "Supports 'Iinazuke'."
		game_type_selector.select(IINAZUKE)
		game_type = IINAZUKE
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == ICHIGOHUNDRED:
		game_type_sub_text.text = "Supports 'Ichigo 100% Strawberry Diary'."
		game_type_selector.select(ICHIGOHUNDRED)
		game_type = ICHIGOHUNDRED
		var next_scene: PackedScene = load("res://src/scenes/AlphaUnit.tscn")
		sceneChanger(next_scene)
	elif index == ANGELWISH:
		game_type_sub_text.text = "Supports 'Angel Wish: Kimi no Egao ni Chu!' (most images)."
		game_type_selector.select(ANGELWISH)
		game_type = ANGELWISH
		var next_scene: PackedScene = load("res://src/scenes/PioneSoft.tscn")
		sceneChanger(next_scene)
	elif index == MYSTEREET:
		game_type_sub_text.text = "Supports 'Mystereet: Yasogami Kaoru no Jiken File'."
		game_type_selector.select(MYSTEREET)
		game_type = MYSTEREET
		var next_scene: PackedScene = load("res://src/scenes/AbelSoft.tscn")
		sceneChanger(next_scene)
	elif index == KIRAKIRA:
		game_type_sub_text.text = "Supports 'Kira Kira: Rock 'N' Roll Show'."
		game_type_selector.select(KIRAKIRA)
		game_type = KIRAKIRA
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == KOKORONOTOBIRA:
		game_type_sub_text.text = "Supports 'Kokoro no Tobira'."
		game_type_selector.select(KOKORONOTOBIRA)
		game_type = KOKORONOTOBIRA
		var next_scene: PackedScene = load("res://src/scenes/GeneX.tscn")
		sceneChanger(next_scene)
	elif index == HOOLIGAN:
		game_type_sub_text.text = "Supports 'Hooligan: Kimi no Naka no Yuuki' (most images)."
		game_type_selector.select(HOOLIGAN)
		game_type = HOOLIGAN
		var next_scene: PackedScene = load("res://src/scenes/GeneX.tscn")
		sceneChanger(next_scene)
	elif index == NORTHWIND:
		game_type_sub_text.text = "Supports 'North Wind: Eien no Yakusoku'."
		game_type_selector.select(NORTHWIND)
		game_type = NORTHWIND
		var next_scene: PackedScene = load("res://src/scenes/DatamPolystar.tscn")
		sceneChanger(next_scene)
	elif index == PUREPURE:
		game_type_sub_text.text = "Supports 'Pure Pure - Mimi to Shippo no Monogatari'."
		game_type_selector.select(PUREPURE)
		game_type = PUREPURE
		var next_scene: PackedScene = load("res://src/scenes/DatamPolystar.tscn")
		sceneChanger(next_scene)
	elif index == ROZENDUEL:
		game_type_sub_text.text = "Supports 'Rozen Maiden: duellwalzer' (most images)."
		game_type_selector.select(ROZENDUEL)
		game_type = ROZENDUEL
		var next_scene: PackedScene = load("res://src/scenes/RozenDuel.tscn")
		sceneChanger(next_scene)
	elif index == SAISHUUSHIKEN:
		game_type_sub_text.text = "Supports 'Saishuu Shiken Kujira: Alive'."
		game_type_selector.select(SAISHUUSHIKEN)
		game_type = SAISHUUSHIKEN
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == SAKURASESTU:
		game_type_sub_text.text = "Supports 'Sakura: Setsugekka'."
		game_type_selector.select(SAKURASESTU)
		game_type = SAKURASESTU
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == SCHOOLNI:
		game_type_sub_text.text = "Supports 'School Rumble Ni-Gakki'."
		game_type_selector.select(SCHOOLNI)
		game_type = SCHOOLNI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == STARTRAIN:
		game_type_sub_text.text = "Supports 'StarTRain: Your Past Makes Your Future'."
		game_type_selector.select(STARTRAIN)
		game_type = STARTRAIN
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == STRAWBERRYPANIC:
		game_type_sub_text.text = "Supports 'Strawberry Panic!'."
		game_type_selector.select(STRAWBERRYPANIC)
		game_type = STRAWBERRYPANIC
		var next_scene: PackedScene = load("res://src/scenes/MediaWorks.tscn")
		sceneChanger(next_scene)
	elif index == SUIKA:
		game_type_sub_text.text = "Supports 'Suika A.S+: Eternal Name'."
		game_type_selector.select(SUIKA)
		game_type = SUIKA
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == SWEETLEGACY:
		game_type_sub_text.text = "Supports 'Sweet Legacy: Boku to Kanojo no Na mo Nai Okashi' (most images)."
		game_type_selector.select(SWEETLEGACY)
		game_type = SWEETLEGACY
		var next_scene: PackedScene = load("res://src/scenes/GeneX.tscn")
		sceneChanger(next_scene)
	elif index == NATSUIROKOMACHI:
		game_type_sub_text.text = "Supports 'Natsuiro Komachi."
		game_type_selector.select(NATSUIROKOMACHI)
		game_type = NATSUIROKOMACHI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == PHANTOMINFERNO:
		game_type_sub_text.text = "Supports 'Phantom: Phantom of Inferno'."
		game_type_selector.select(PHANTOMINFERNO)
		game_type = PHANTOMINFERNO
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == PRINCESSPRINCESS:
		game_type_sub_text.text = "Supports 'Princess Princess: Himetachi no Abunai Houkago'."
		game_type_selector.select(PRINCESSPRINCESS)
		game_type = PRINCESSPRINCESS
		var next_scene: PackedScene = load("res://src/scenes/AbelSoft.tscn")
		sceneChanger(next_scene)
	elif index == QUILT:
		game_type_sub_text.text = "Supports 'Quilt: Anata to Tsumugu Yume to Koi no Dress."
		game_type_selector.select(QUILT)
		game_type = QUILT
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == TRUETEARS:
		game_type_sub_text.text = "Supports 'True Tears'."
		game_type_selector.select(TRUETEARS)
		game_type = TRUETEARS
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == OJOUSAMAKUMI:
		game_type_sub_text.text = "Supports 'Ojousama Kumikyoku: Sweet Concert'."
		game_type_selector.select(OJOUSAMAKUMI)
		game_type = OJOUSAMAKUMI
		var next_scene: PackedScene = load("res://src/scenes/PioneSoft.tscn")
		sceneChanger(next_scene)
	elif index == ORANGEPOCKET:
		game_type_sub_text.text = "Supports 'Orange Pocket:  Root'."
		game_type_selector.select(ORANGEPOCKET)
		game_type = ORANGEPOCKET
		var next_scene: PackedScene = load("res://src/scenes/PioneSoft.tscn")
		sceneChanger(next_scene)
	elif index == OUKA:
		game_type_sub_text.text = "Supports 'Ouka: Kokoro Kagayakaseru Sakura'."
		game_type_selector.select(OUKA)
		game_type = OUKA
		var next_scene: PackedScene = load("res://src/scenes/TamTam.tscn")
		sceneChanger(next_scene)
	elif index == PATISSERIE:
		game_type_sub_text.text = "Supports 'Patisserie na Nyanko: Hatsukoi wa Ichigo Aji'."
		game_type_selector.select(PATISSERIE)
		game_type = PATISSERIE
		var next_scene: PackedScene = load("res://src/scenes/PioneSoft.tscn")
		sceneChanger(next_scene)
	elif index == PIA3:
		game_type_sub_text.text = "Supports 'Pia Carrot he Youkoso!! 3: Round Summer'."
		game_type_selector.select(PIA3)
		game_type = PIA3
		var next_scene: PackedScene = load("res://src/scenes/AlphaUnit.tscn")
		sceneChanger(next_scene)
	elif index == PRISMARK:
		game_type_sub_text.text = "Supports 'Prism Ark: Awake' (archive extraction, some images except PA_CG.DAT compressed images)."
		game_type_selector.select(PRISMARK)
		game_type = PRISMARK
		var next_scene: PackedScene = load("res://src/scenes/PrismArk.tscn")
		sceneChanger(next_scene)
	elif index == REGISTA:
		game_type_sub_text.text = "Basic support for Regista games."
		game_type_selector.select(REGISTA)
		game_type = REGISTA
		var next_scene: PackedScene = load("res://src/scenes/Regista.tscn")
		sceneChanger(next_scene)
	elif index == SCHOOLLOVE:
		game_type_sub_text.text = "Supports 'School Love! Koi to Kibou no Metronome'."
		game_type_selector.select(SCHOOLLOVE)
		game_type = SCHOOLLOVE
		var next_scene: PackedScene = load("res://src/scenes/AbelSoft.tscn")
		sceneChanger(next_scene)
	elif index == LOVEDOLL:
		game_type_sub_text.text = "Supports 'Love Doll: Lovely Idol'."
		game_type_selector.select(LOVEDOLL)
		game_type = LOVEDOLL
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == MAGICAL:
		game_type_sub_text.text = "Supports 'Magical Tale: Chiicha na Mahoutsukai'"
		game_type_selector.select(MAGICAL)
		game_type = MAGICAL
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == MAIHIME:
		game_type_sub_text.text = "Supports 'Mai-HiME: Unmei no Keitouju'."
		game_type_selector.select(MAIHIME)
		game_type = MAIHIME
		var next_scene: PackedScene = load("res://src/scenes/Circus.tscn")
		sceneChanger(next_scene)
	elif index == MISSINGBLUE:
		game_type_sub_text.text = "Supports 'Missing Blue'."
		game_type_selector.select(MISSINGBLUE)
		game_type = MISSINGBLUE
		var next_scene: PackedScene = load("res://src/scenes/TonkinHouse.tscn")
		sceneChanger(next_scene)
	elif index == METALWOLF:
		game_type_sub_text.text = "Supports 'Metal Wolf REV'."
		game_type_selector.select(METALWOLF)
		game_type = METALWOLF
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == TROUBLEFORTUNE:
		game_type_sub_text.text = "Supports 'Trouble Fortune Company:  Happy Cure'."
		game_type_selector.select(TROUBLEFORTUNE)
		game_type = TROUBLEFORTUNE
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == PRINCESSLOVER:
		game_type_sub_text.text = "Supports 'Princess Lover! Eternal Love for My Lady'."
		game_type_selector.select(PRINCESSLOVER)
		game_type = PRINCESSLOVER
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem2.tscn")
		sceneChanger(next_scene)
	elif index == PRISAGA:
		game_type_sub_text.text = "Supports 'Pri-Saga! Princess wo Sagase!'."
		game_type_selector.select(PRISAGA)
		game_type = PRISAGA
		var next_scene: PackedScene = load("res://src/scenes/AbelSoft.tscn")
		sceneChanger(next_scene)
	elif index == YATOHIME:
		game_type_sub_text.text = "Supports 'Yatohime Zankikou'."
		game_type_selector.select(YATOHIME)
		game_type = YATOHIME
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == YOJINBO:
		game_type_sub_text.text = "Supports 'Yo-Jin-Bo - Unmei no Freude' (most images)."
		game_type_selector.select(YOJINBO)
		game_type = YOJINBO
		var next_scene: PackedScene = load("res://src/scenes/RozenDuel.tscn")
		sceneChanger(next_scene)
	elif index == YUMEMI:
		game_type_sub_text.text = "Supports 'Yumemi Hakusho: Second Dream'."
		game_type_selector.select(YUMEMI)
		game_type = YUMEMI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == YUMEMISHI:
		game_type_sub_text.text = "Supports 'Yumemishi'."
		game_type_selector.select(YUMEMISHI)
		game_type = YUMEMISHI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == ZEROSYSTEM:
		game_type_sub_text.text = "Supports Zero System games."
		game_type_selector.select(ZEROSYSTEM)
		game_type = ZEROSYSTEM
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
		
func sceneChanger(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
	return
	
func initMenuItems() -> void:
	# Menu items must be in alphabetical order based on their enum value.
	
	game_type_selector.add_item("3LDK - Shiawase ni Narouyo", THREELDK)
	game_type_selector.add_item("Angel's Feather", ANGELSFEATHER)
	game_type_selector.add_item("Angel Wish: Kimi no Egao ni Chu!", ANGELWISH)
	game_type_selector.add_item("Castle Fantasia: Erencia Senki - Plus Stories", CASTLEFANTASIA)
	game_type_selector.add_item("Colorful Aquarium: My Little Mermaid", COLORFULAQUA)
	game_type_selector.add_item("D-A:  Black", DABLACK)
	game_type_selector.add_item("D-A:  White", DAWHITE)
	game_type_selector.add_item("D.C. II P.S.: Da Capo II Plus Situation", DCTWO)
	game_type_selector.add_item("D.C.F.S.: Da Capo Four Seasons", DCFS)
	game_type_selector.add_item("D.C.I.F.: Da Capo Innocent Finale", DCIF)
	game_type_selector.add_item("D.C.P.S.: Da Capo Plus Situation", DCPS)
	game_type_selector.add_item("D.C.: The Origin", DCORIGIN)
	game_type_selector.add_item("Dear My Friend: Love Like Powdery Snow", DEARMYFRIEND)
	game_type_selector.add_item("Doko he Iku no, Anohi", DOKOHE)
	game_type_selector.add_item("Double Wish (WWish)", DOUBLEWISH)
	game_type_selector.add_item("ef: A Fairy Tale of the Two", EF)
	game_type_selector.add_item("F: Fanatic", FANATIC)
	game_type_selector.add_item("Final Approach 2 - 1st Priority", FINALA2)
	game_type_selector.add_item("Finalist", FINALIST) #make a AFS file reader
	game_type_selector.add_item("Fukakutei Sekai no Tantei Shinshi: Akugyou Futaasa no Jiken File", FUKAKUTEI)
	game_type_selector.add_item("Futakoi", FUTAKOI)
	game_type_selector.add_item("Futakoijima: Koi to Mizugi no Survival", FUTAKOIJIMA)
	game_type_selector.add_item("Gift: Prism", GIFTPRISIM)
	game_type_selector.add_item("Gin no Eclipse", GINNOECLIPSE)
	game_type_selector.add_item("Happy Breeding: Cheerful Party", HAPPYBREED)
	game_type_selector.add_item("Happiness! De-Lucks", HAPPYDELUCKS)
	game_type_selector.add_item("Harukaze P.S: Plus Situation", HARUKAZEPS)
	game_type_selector.add_item("Hooligan: Kimi no Naka no Yuuki", HOOLIGAN)
	game_type_selector.add_item("Hokenshitsu he Youkoso", HOKENSHITSU)
	game_type_selector.add_item("Hurrah! Sailor", HURRAH)
	game_type_selector.add_item("Juujigen Rippoutai Cipher: Game of Survival", JUUJIGEN)
	game_type_selector.add_item("Ichigo 100% Strawberry Diary", ICHIGOHUNDRED)
	game_type_selector.add_item("Iinazuke", IINAZUKE)
	game_type_selector.add_item("Kira Kira: Rock 'N' Roll Show", KIRAKIRA)
	game_type_selector.add_item("Kokoro no Tobira", KOKORONOTOBIRA)
	game_type_selector.add_item("Love Doll: Lovely Idol", LOVEDOLL)
	game_type_selector.add_item("Magical Tale: Chiicha na Mahoutsukai", MAGICAL)
	game_type_selector.add_item("Mai-HiME: Unmei no Keitouju", MAIHIME)
	game_type_selector.add_item("Men at Work! 3: Ai to Seishun no Hunter Gakuen", MENATWORK3)
	game_type_selector.add_item("Metal Wolf REV", METALWOLF)
	game_type_selector.add_item("Missing Blue", MISSINGBLUE)
	game_type_selector.add_item("Moekan: Moekko Company", MOEKAN)
	game_type_selector.add_item("Mystereet: Yasogami Kaoru no Jiken File", MYSTEREET)
	game_type_selector.add_item("Natsuiro: Hoshikuzu no Memory", NATSUIROHOSHI)
	game_type_selector.add_item("Natsuiro Komachi", NATSUIROKOMACHI)
	game_type_selector.add_item("North Wind: Eien no Yakusoku", NORTHWIND)
	game_type_selector.add_item("Ojousama Kumikyoku: Sweet Concert", OJOUSAMAKUMI)
	game_type_selector.add_item("Orange Pocket:  Root", ORANGEPOCKET)
	game_type_selector.add_item("Ouka: Kokoro Kagayakaseru Sakura", OUKA)
	game_type_selector.add_item("Patisserie na Nyanko: Hatsukoi wa Ichigo Aji", PATISSERIE)
	game_type_selector.add_item("Phantom: Phantom of Inferno", PHANTOMINFERNO)
	game_type_selector.add_item("Pia Carrot he Youkoso!! 3: Round Summer", PIA3)
	game_type_selector.add_item("Princess Lover! Eternal Love for My Lady", PRINCESSLOVER)
	game_type_selector.add_item("Princess Princess: Himetachi no Abunai Houkago", PRINCESSPRINCESS)
	game_type_selector.add_item("Pri-Saga! Princess wo Sagase!", PRISAGA)
	game_type_selector.add_item("Prism Ark: Awake", PRISMARK)
	game_type_selector.add_item("Pure Pure - Mimi to Shippo no Monogatari", PUREPURE)
	game_type_selector.add_item("Quilt: Anata to Tsumugu Yume to Koi no Dress", QUILT)
	game_type_selector.add_item("Regista Games", REGISTA)
	game_type_selector.add_item("Rozen Maiden: duellwalzer", ROZENDUEL)
	game_type_selector.add_item("Saishuu Shiken Kujira: Alive", SAISHUUSHIKEN)
	game_type_selector.add_item("Sakura: Setsugekka", SAKURASESTU)
	game_type_selector.add_item("School Love! Koi to Kibou no Metronome", SCHOOLLOVE)
	game_type_selector.add_item("School Rumble Ni-Gakki", SCHOOLNI)
	game_type_selector.add_item("StarTRain: Your Past Makes Your Future", STARTRAIN)
	game_type_selector.add_item("Strawberry Panic!", STRAWBERRYPANIC)
	game_type_selector.add_item("Suika A.S+: Eternal Name", SUIKA)
	game_type_selector.add_item("Sweet Legacy: Boku to Kanojo no Na mo Nai Okashi", SWEETLEGACY)
	game_type_selector.add_item("Trouble Fortune Company:  Happy Cure", TROUBLEFORTUNE)
	game_type_selector.add_item("True Tears", TRUETEARS)
	game_type_selector.add_item("Yatohime Zankikou", YATOHIME)
	game_type_selector.add_item("Yo-Jin-Bo - Unmei no Freude", YOJINBO)
	game_type_selector.add_item("Yumemi Hakusho: Second Dream", YUMEMI)
	game_type_selector.add_item("Yumemishi", YUMEMISHI)
	game_type_selector.add_item("Zero System Games", ZEROSYSTEM)
	#print(game_type_selector.item_count)
	#for i in range(game_type_selector.item_count):
		#print("* %s" % game_type_selector.get_item_text(i))
	return
