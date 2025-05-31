extends Control

@onready var memory_usage: Label = $MemoryUsage
@onready var game_type_selector: OptionButton = $GameTypeSelector
@onready var game_type_text: Label = $GameTypeText
@onready var game_type_sub_text: Label = $GameTypeSubText

# Game types must be in alphabetical order

enum {
	THREELDK = 0, # 3LDK - Shiawase ni Narouyo
	TWELVERIVEN = 1, # 12Riven: The Psi-Climinal of Integral
	AIR,
	AIYORIAOSHI,
	AFTER,
	AMAGAMI,
	ANGELSFEATHER,
	ANGELWISH,
	AONOMAMA,
	ARABIANS,
	ARCANAHEART,
	ASOBINIIKUYO,
	BINCHOUTAN,
	CAFELINDBERGHSUMMER,
	CAFELITTLEWISH,
	CAMBRIAN,
	CANVAS1,
	CANVAS2,
	CARTAGRA,
	CASTLEFANTASIA,
	CHANTER,
	CHOCOLAT,
	CLOVERNOKUNI,
	CODEGEASS,
	COLORFULAQUA,
	DABLACK,
	DAWHITE,
	DCTWO,
	DCFS,
	DCIF,
	DCORIGIN,
	DCPS,
	DEARMYFRIEND,
	DIGI,
	DOKOHE,
	DOUBLEREACTION,
	DOUBLEWISH,
	EF,
	ELYSION,
	ERDE,
	FANATIC,
	FESTAHYPER,
	FINALA,
	FINALA2,
	FINALIST,
	FRAGMENTSBLUE,
	FRIENDS,
	FUKAKUTEI,
	FUSHIGINOUMI,
	FUSHIGINOUMIDENNOU,
	FUTAKOI,
	FUTAKOIALT,
	FUTAKOIJIMA,
	GALAXYANGEL,
	GALAXYANGEL2EI,
	GALAXYANGEL2MU,
	GALAXYANGEL2ZE,
	GALAXYANGELETERNAL,
	GALAXYANGELMOON,
	GAMENINATTA,
	GETSUMENTO,
	GIFTPRISIM,
	GINNOECLIPSE, 
	GIRLSBRAVO,
	GUISARD,
	HAKARENA,
	HAKUSHAKU,
	HAMETSU,
	HAPPYBREED,
	HAPPYDELUCKS,
	HARUKAZEPS,
	HEARTNOKUNI,
	HIGURASHI,
	HIGURASHIKAKERA,
	HIMEHIBINEW,
	HINOKAKERASHIN,
	HOKENSHITSU,
	HOOLIGAN,
	HOSHIFURU,
	HOSHIGARI,
	HURRAH,
	HYAKKO,
	ICHIGOHUNDRED,
	IDOLJANSHIR,
	IINAZUKE,
	INTERLUDE,
	INUYASHATHESECRET,
	ITSUKA,
	IZUMOZERO,
	JEWELSOCEAN,
	JIGOKUSHOUJO,
	JUUJIGEN,
	KAIKETSUOSHABAKIINA,
	KANOKON,
	KANON,
	KATAKAMUNA,
	KAZEIROSURF,
	KIDOUSHINSENGUMI,
	KIMIGAARUJI,
	KIMIKISS,
	KIMISUTA,
	KIRAKIRA, 
	KISHINHOUKOU,
	KOIHIMEMUSOU,
	KOISURU,
	KOKORONOTOBIRA, 
	KONOAOZORA,
	LITTLEBUSTERS,
	LNOKISETSU,
	LOSTAYA,
	LOSTPASSAGE,
	LOVEDOLL,
	LOVEDROPS,
	LOVEHINA,
	LUXBEVIL,
	MABINOSTYLE,
	MAGI,
	MAGICAL,
	MAHOUSENSEINEGIMA1,
	MAHOUSENSEINEGIMA2,
	MAIHIME,
	MEITANTEIEVA,
	MEMORIESOFF5EN,
	MEMORIESOFF5TO,
	MEMORIESOFF6NEXT,
	MEMORIESOFF6TWAVE,
	MEMORIESOFFSOREAGAIN,
	MENATWORK3,
	METALWOLF,
	MISSINGBLUE,
	MIZUNOSENRITSU,
	MIZUNOSENRITSU2,
	MOEKAN,
	MOEMOE2JI2,
	MOEMOE2JIDEL,
	MONOCHROME,
	MONOCHROMEFACTOR,
	MUTSUBOSHI,
	MYMARRYMAYBE,
	MYMARRYWITHBE,
	MYSTEREET,
	NATSUIROHOSHI,
	NATSUIROKOMACHI,
	NATSUIROSUNADOKEI,
	NATSUZORA,
	NATURAL2,
	NETTAITEIKIATSU,
	NIGHTWIZARD,
	NOGIZAKA,
	NORTHWIND,
	NUGA,
	NURSEWITCH,
	OJOUSAMAKUMI,
	ORANGEPOCKET,
	OSOUJI,
	OTOMENOJIJOU,
	OTOMEWABOKU,
	OUKA,
	PARFAIT,
	PATISSERIE,
	PHANTOMINFERNO, 
	PIA3, 
	PIAGO,
	PIZZICATOPOLKA,
	PLANETARIAN,
	PPOI,
	PRINCESSCONCERTO,
	PRINCESSHOLIDAY,
	PRINCESSLOVER,
	PRINCESSMAKER5,
	PRINCESSNIGHTMARE,
	PRINCESSPRINCESS,
	PRISAGA,
	PRISMARK,
	PRIVATENURSE,
	PUREPURE,
	PUREXCURE,
	QUE,
	QUILT,
	#REGISTA, # temp value
	ROSARIO,
	ROUTESPE,
	ROZENDUEL,
	RUNEPRINCESS,
	RYUUKOKU,
	SAISHUUSHIKEN,
	SAKURASESTU,
	SANGOKURENSEKI,
	SCHOOLLOVE,
	SCHOOLNI,
	SEIKAINOSENKI,
	SEGAAGESVOL12,
	SENGOKUHIME2,
	SENTIMENTALPRELUDE,
	SEPARATEHEARTS,
	SHAKUGAN,
	SHINE,
	SHINKOIHIME,
	SHINSEIKIEVABATTLE,
	SHOUJOMAHOU,
	SHIROGANE,
	SHUFFLE,
	SHUUMATSUSHOUJO,
	SKIPBEAT,
	SORAIROFUUKIN,
	SOTSUGYOU,
	SOULLINK,
	STARTRAIN,
	STEADYXSTUDY,
	STRAWBERRYPANIC,
	STRIKEWITCHES,
	SUGARSPICE,
	SUGGOIARCANAHEART2,
	SUIGETSUMAYOI,
	SUIKA,
	SUISUISWEET,
	SUMOMOMO,
	SUZUMIYA,
	SWEETLEGACY, 
	SWEETSEASON,
	TENHIRO,
	TENKUU,
	TENTAMA1ST,
	TENTAMA2,
	THEMAGICIAN,
	TOGAINU,
	TOHEART,
	TOHEART2,
	TRIGGERHEART,
	TROUBLEFORTUNE,
	TRUELOVESTORY3,
	TRUELOVESTORYSUMMER,
	TRUETEARS,
	TSUKIWAHIGASHI, 
	TSUYOKISS,
	TSUYOKISS2,
	UMISHO,
	UNDERTHEMOON,
	UTAU,
	WEARE,
	WHITEBREATH,
	WHITEPRINCESS,
	YAMIYO,
	YATOHIME,
	YOJINBO,
	YOAKE,
	YOUKIHIMDEN,
	YRMEMORIES,
	YUKIGATARI,
	YUMEMI,
	YUMEMISHI,
	ZNTKOAKUMA,
	ZNTMAIGO,
	ZNTMUMA
	}
	
var game_type: int = FUTAKOI

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
	elif index == TRIGGERHEART:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(TRIGGERHEART)
		game_type = TRIGGERHEART
		var next_scene: PackedScene = load("res://src/scenes/Gulti.tscn")
		sceneChanger(next_scene)
	elif index == IZUMOZERO:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(IZUMOZERO)
		game_type = IZUMOZERO
		var next_scene: PackedScene = load("res://src/scenes/BlackJack.tscn")
		sceneChanger(next_scene)
	elif index == SHOUJOMAHOU:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(SHOUJOMAHOU)
		game_type = SHOUJOMAHOU
		var next_scene: PackedScene = load("res://src/scenes/BlackJack.tscn")
		sceneChanger(next_scene)
	elif index == MOEMOE2JI2:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(MOEMOE2JI2)
		game_type = MOEMOE2JI2
		var next_scene: PackedScene = load("res://src/scenes/BlackJack.tscn")
		sceneChanger(next_scene)
	elif index == MOEMOE2JIDEL:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(MOEMOE2JIDEL)
		game_type = MOEMOE2JIDEL
		var next_scene: PackedScene = load("res://src/scenes/BlackJack.tscn")
		sceneChanger(next_scene)
	elif index == FUSHIGINOUMI:
		game_type_sub_text.text = "Supports:\nExtraction, images (BMP)."
		game_type_selector.select(FUSHIGINOUMI)
		game_type = FUSHIGINOUMI
		var next_scene: PackedScene = load("res://src/scenes/ThunderstoneJapan.tscn")
		sceneChanger(next_scene)
	elif index == FUSHIGINOUMIDENNOU:
		game_type_sub_text.text = "Supports:\nExtraction, images (BMP)."
		game_type_selector.select(FUSHIGINOUMIDENNOU)
		game_type = FUSHIGINOUMIDENNOU
		var next_scene: PackedScene = load("res://src/scenes/ThunderstoneJapan.tscn")
		sceneChanger(next_scene)
	elif index == SEIKAINOSENKI:
		game_type_sub_text.text = "Supports:\nExtraction, images (BMP)."
		game_type_selector.select(SEIKAINOSENKI)
		game_type = SEIKAINOSENKI
		var next_scene: PackedScene = load("res://src/scenes/ThunderstoneJapan.tscn")
		sceneChanger(next_scene)
	elif index == SEGAAGESVOL12:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(SEGAAGESVOL12)
		game_type = SEGAAGESVOL12
		var next_scene: PackedScene = load("res://src/scenes/Digimix.tscn")
		sceneChanger(next_scene)
	elif index == KIDOUSHINSENGUMI:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nSupports most images."
		game_type_selector.select(KIDOUSHINSENGUMI)
		game_type = KIDOUSHINSENGUMI
		var next_scene: PackedScene = load("res://src/scenes/Quintet.tscn")
		sceneChanger(next_scene)
	elif index == SENGOKUHIME2:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(SENGOKUHIME2)
		game_type = SENGOKUHIME2
		var next_scene: PackedScene = load("res://src/scenes/MileStone.tscn")
		sceneChanger(next_scene)
	elif index == CODEGEASS:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(CODEGEASS)
		game_type = CODEGEASS
		var next_scene: PackedScene = load("res://src/scenes/Crafts&Meister.tscn")
		sceneChanger(next_scene)
	elif index == PRINCESSNIGHTMARE:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(PRINCESSNIGHTMARE)
		game_type = PRINCESSNIGHTMARE
		var next_scene: PackedScene = load("res://src/scenes/RainEntertainment.tscn")
		sceneChanger(next_scene)
	elif index == KOIHIMEMUSOU:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(KOIHIMEMUSOU)
		game_type = KOIHIMEMUSOU
		var next_scene: PackedScene = load("res://src/scenes/RainEntertainment.tscn")
		sceneChanger(next_scene)
	elif index == SHINKOIHIME:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(SHINKOIHIME)
		game_type = SHINKOIHIME
		var next_scene: PackedScene = load("res://src/scenes/RainEntertainment.tscn")
		sceneChanger(next_scene)
	elif index == UTAU:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(UTAU)
		game_type = UTAU
		var next_scene: PackedScene = load("res://src/scenes/Ecole.tscn")
		sceneChanger(next_scene)
	elif index == ARCANAHEART:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(ARCANAHEART)
		game_type = ARCANAHEART
		var next_scene: PackedScene = load("res://src/scenes/Ecole.tscn")
		sceneChanger(next_scene)
	elif index == SUGGOIARCANAHEART2:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMultiple palettes not supported for some images."
		game_type_selector.select(SUGGOIARCANAHEART2)
		game_type = SUGGOIARCANAHEART2
		var next_scene: PackedScene = load("res://src/scenes/Ecole.tscn")
		sceneChanger(next_scene)
	elif index == IDOLJANSHIR:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(IDOLJANSHIR)
		game_type = IDOLJANSHIR
		var next_scene: PackedScene = load("res://src/scenes/PccwJapan.tscn")
		sceneChanger(next_scene)
	elif index == PRINCESSCONCERTO:
		game_type_sub_text.text = "Supports:\nExtraction, images (BMP, PNG)."
		game_type_selector.select(PRINCESSCONCERTO)
		game_type = PRINCESSCONCERTO
		var next_scene: PackedScene = load("res://src/scenes/Headlock.tscn")
		sceneChanger(next_scene)
	elif index == MEITANTEIEVA:
		game_type_sub_text.text = "Supports:\nExtraction, images (BMP, PNG)."
		game_type_selector.select(MEITANTEIEVA)
		game_type = MEITANTEIEVA
		var next_scene: PackedScene = load("res://src/scenes/Headlock.tscn")
		sceneChanger(next_scene)
	elif index == SHINSEIKIEVABATTLE:
		game_type_sub_text.text = "Supports:\nExtraction, images (BMP, PNG)."
		game_type_selector.select(SHINSEIKIEVABATTLE)
		game_type = SHINSEIKIEVABATTLE
		var next_scene: PackedScene = load("res://src/scenes/Headlock.tscn")
		sceneChanger(next_scene)
	elif index == SUISUISWEET:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(SUISUISWEET)
		game_type = SUISUISWEET
		var next_scene: PackedScene = load("res://src/scenes/BillikenSoft.tscn")
		sceneChanger(next_scene)
	elif index == KISHINHOUKOU:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(KISHINHOUKOU)
		game_type = KISHINHOUKOU
		var next_scene: PackedScene = load("res://src/scenes/Digiturbo.tscn")
		sceneChanger(next_scene)
	elif index == KIMIKISS:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(KIMIKISS)
		game_type = KIMIKISS
		var next_scene: PackedScene = load("res://src/scenes/EnterBrain.tscn")
		sceneChanger(next_scene)
	elif index == TRUELOVESTORY3:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(TRUELOVESTORY3)
		game_type = TRUELOVESTORY3
		var next_scene: PackedScene = load("res://src/scenes/EnterBrain.tscn")
		sceneChanger(next_scene)
	elif index == AMAGAMI:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(AMAGAMI)
		game_type = AMAGAMI
		var next_scene: PackedScene = load("res://src/scenes/EnterBrain.tscn")
		sceneChanger(next_scene)
	elif index == THEMAGICIAN:
		game_type_sub_text.text = "Supports:\nExtraction only.\nUnknown image format, scripts encrypted?"
		game_type_selector.select(THEMAGICIAN)
		game_type = THEMAGICIAN
		var next_scene: PackedScene = load("res://src/scenes/EnterBrain.tscn")
		sceneChanger(next_scene)
	elif index == TRUELOVESTORYSUMMER:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(TRUELOVESTORYSUMMER)
		game_type = TRUELOVESTORYSUMMER
		var next_scene: PackedScene = load("res://src/scenes/GameCrab.tscn")
		sceneChanger(next_scene)
	elif index == ROUTESPE:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported."
		game_type_selector.select(ROUTESPE)
		game_type = ROUTESPE
		var next_scene: PackedScene = load("res://src/scenes/Sting.tscn")
		sceneChanger(next_scene)
	elif index == TOHEART:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(TOHEART)
		game_type = TOHEART
		var next_scene: PackedScene = load("res://src/scenes/Sting.tscn")
		sceneChanger(next_scene)
	elif index == TOHEART2:
		game_type_sub_text.text = "Supports:\nExtraction, images (BMP, PNG)."
		game_type_selector.select(TOHEART2)
		game_type = TOHEART2
		var next_scene: PackedScene = load("res://src/scenes/Sting.tscn")
		sceneChanger(next_scene)
	elif index == CANVAS2:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(CANVAS2)
		game_type = CANVAS2
		var next_scene: PackedScene = load("res://src/scenes/Tose.tscn")
		sceneChanger(next_scene)
	elif index == PRINCESSMAKER5:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(PRINCESSMAKER5)
		game_type = PRINCESSMAKER5
		var next_scene: PackedScene = load("res://src/scenes/Tose.tscn")
		sceneChanger(next_scene)
	elif index == NATURAL2:
		game_type_sub_text.text = "Supports:\nExtraction, unsupported tiled images."
		game_type_selector.select(NATURAL2)
		game_type = NATURAL2
		var next_scene: PackedScene = load("res://src/scenes/Tose.tscn")
		sceneChanger(next_scene)
	elif index == ROSARIO:
		game_type_sub_text.text = "Supports:\nExtraction, images (custom TM2 to PNG). Most images supported."
		game_type_selector.select(ROSARIO)
		game_type = ROSARIO
		var next_scene: PackedScene = load("res://src/scenes/CompileHeart.tscn")
		sceneChanger(next_scene)
	elif index == JIGOKUSHOUJO:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(JIGOKUSHOUJO)
		game_type = JIGOKUSHOUJO
		var next_scene: PackedScene = load("res://src/scenes/CompileHeart.tscn")
		sceneChanger(next_scene)
	elif index == TWELVERIVEN:
		game_type_sub_text.text = "Supports '12Riven: The Psi-Climinal of Integral'."
		game_type_selector.select(TWELVERIVEN)
		game_type = TWELVERIVEN
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == AIYORIAOSHI:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(AIYORIAOSHI)
		game_type = AIYORIAOSHI
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == ERDE:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(ERDE)
		game_type = ERDE
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == KANOKON:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(KANOKON)
		game_type = KANOKON
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == CARTAGRA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(CARTAGRA)
		game_type = CARTAGRA
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == NURSEWITCH:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(NURSEWITCH)
		game_type = NURSEWITCH
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == UMISHO:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(UMISHO)
		game_type = UMISHO
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == WHITEPRINCESS:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(WHITEPRINCESS)
		game_type = WHITEPRINCESS
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == FESTAHYPER:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(FESTAHYPER)
		game_type = FESTAHYPER
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == KAIKETSUOSHABAKIINA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(KAIKETSUOSHABAKIINA)
		game_type = KAIKETSUOSHABAKIINA
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == NIGHTWIZARD:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(NIGHTWIZARD)
		game_type = NIGHTWIZARD
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == GUISARD:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(GUISARD)
		game_type = GUISARD
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MIZUNOSENRITSU:
		game_type_sub_text.text = "Supports 'Mizu no Senritsu'."
		game_type_selector.select(MIZUNOSENRITSU)
		game_type = MIZUNOSENRITSU
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MIZUNOSENRITSU2:
		game_type_sub_text.text = "Supports 'Mizu no Senritsu 2: Hi no Kioku'."
		game_type_selector.select(MIZUNOSENRITSU2)
		game_type = MIZUNOSENRITSU2
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MABINOSTYLE:
		game_type_sub_text.text = "Supports 'Mabino x Style'."
		game_type_selector.select(MABINOSTYLE)
		game_type = MABINOSTYLE
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == LUXBEVIL:
		game_type_sub_text.text = "Supports 'Luxury & Beauty: Lucian Bee's - Evil Violet'."
		game_type_selector.select(LUXBEVIL)
		game_type = LUXBEVIL
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == HAKUSHAKU:
		game_type_sub_text.text = "Supports 'Hakushaku to Yousei: Yume to Kizuna ni Omoi Hasete'."
		game_type_selector.select(HAKUSHAKU)
		game_type = HAKUSHAKU
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == LNOKISETSU:
		game_type_sub_text.text = "Supports 'L no Kisetsu 2: Invisible Memories!'."
		game_type_selector.select(LNOKISETSU)
		game_type = LNOKISETSU
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == HYAKKO:
		game_type_sub_text.text = "Supports 'Hyakko: Yorozuya Jikenbo!'."
		game_type_selector.select(HYAKKO)
		game_type = HYAKKO
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == PIZZICATOPOLKA:
		game_type_sub_text.text = "Supports 'Pizzicato Polka: Suisei Genya'."
		game_type_selector.select(PIZZICATOPOLKA)
		game_type = PIZZICATOPOLKA
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MYMARRYMAYBE:
		game_type_sub_text.text = "Supports 'My Merry Maybe'."
		game_type_selector.select(MYMARRYMAYBE)
		game_type = MYMARRYMAYBE
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MYMARRYWITHBE:
		game_type_sub_text.text = "Supports 'My Merry May with be'."
		game_type_selector.select(MYMARRYWITHBE)
		game_type = MYMARRYWITHBE
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MONOCHROME:
		game_type_sub_text.text = "Supports 'Monochrome'."
		game_type_selector.select(MONOCHROME)
		game_type = MONOCHROME
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MONOCHROMEFACTOR:
		game_type_sub_text.text = "Supports 'Monochrome Factor: Cross Road'."
		game_type_selector.select(MONOCHROMEFACTOR)
		game_type = MONOCHROMEFACTOR
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MEMORIESOFFSOREAGAIN:
		game_type_sub_text.text = "Supports 'Memories Off: Sorekara Again'."
		game_type_selector.select(MEMORIESOFFSOREAGAIN)
		game_type = MEMORIESOFFSOREAGAIN
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MEMORIESOFF6NEXT:
		game_type_sub_text.text = "Supports 'Memories Off 6: Next Relation'."
		game_type_selector.select(MEMORIESOFF6NEXT)
		game_type = MEMORIESOFF6NEXT
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == RYUUKOKU:
		game_type_sub_text.text = "Supports 'Ryuu Koku'."
		game_type_selector.select(RYUUKOKU)
		game_type = RYUUKOKU
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == YRMEMORIES:
		game_type_sub_text.text = "Supports 'Your Memories Off: Girl's Style'."
		game_type_selector.select(YRMEMORIES)
		game_type = YRMEMORIES
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MEMORIESOFF6TWAVE:
		game_type_sub_text.text = "Supports 'Memories Off 6: T-Wave'."
		game_type_selector.select(MEMORIESOFF6TWAVE)
		game_type = MEMORIESOFF6TWAVE
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MEMORIESOFF5EN:
		game_type_sub_text.text = "Supports 'Memories Off 5: Encore'."
		game_type_selector.select(MEMORIESOFF5EN)
		game_type = MEMORIESOFF5EN
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == MEMORIESOFF5TO:
		game_type_sub_text.text = "Supports 'Memories Off 5: Togireta Film'."
		game_type_selector.select(MEMORIESOFF5TO)
		game_type = MEMORIESOFF5TO
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == SEPARATEHEARTS:
		game_type_sub_text.text = "Supports 'Separate Hearts'."
		game_type_selector.select(SEPARATEHEARTS)
		game_type = SEPARATEHEARTS
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == SKIPBEAT:
		game_type_sub_text.text = "Supports 'Skip Beat!'."
		game_type_selector.select(SKIPBEAT)
		game_type = SKIPBEAT
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == SUIGETSUMAYOI:
		game_type_sub_text.text = "Supports 'Suigetsu: Mayoi Gokoro'."
		game_type_selector.select(SUIGETSUMAYOI)
		game_type = SUIGETSUMAYOI
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == TENTAMA1ST:
		game_type_sub_text.text = "Supports 'Tentama: 1st Sunny Side'."
		game_type_selector.select(TENTAMA1ST)
		game_type = TENTAMA1ST
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == TENTAMA2:
		game_type_sub_text.text = "Supports 'Tentama 2: Wins'."
		game_type_selector.select(TENTAMA2)
		game_type = TENTAMA2
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == WEARE:
		game_type_sub_text.text = "Supports 'WeAre*'."
		game_type_selector.select(WEARE)
		game_type = WEARE
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == WHITEBREATH:
		game_type_sub_text.text = "Supports 'White Breath: Kizuna'."
		game_type_selector.select(WHITEBREATH)
		game_type = WHITEBREATH
		var next_scene: PackedScene = load("res://src/scenes/Kid.tscn")
		sceneChanger(next_scene)
	elif index == BINCHOUTAN:
		game_type_sub_text.text = "Supports 'Binchou-Tan: Shiawasegoyomi'."
		game_type_selector.select(BINCHOUTAN)
		game_type = BINCHOUTAN
		var next_scene: PackedScene = load("res://src/scenes/Marvelous.tscn")
		sceneChanger(next_scene)
	elif index == COLORFULAQUA:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(COLORFULAQUA)
		game_type = COLORFULAQUA
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem2.tscn")
		sceneChanger(next_scene)
	elif index == QUE:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(QUE)
		game_type = QUE
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem2.tscn")
		sceneChanger(next_scene)
	elif index == KIMIGAARUJI:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(KIMIGAARUJI)
		game_type = KIMIGAARUJI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem2.tscn")
		sceneChanger(next_scene)
	elif index == TSUYOKISS:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(TSUYOKISS)
		game_type = TSUYOKISS
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem2.tscn")
		sceneChanger(next_scene)
	elif index == DIGI:
		game_type_sub_text.text = "Supports 'Di Gi Charat Fantasy: Excellent' (most images)."
		game_type_selector.select(DIGI)
		game_type = DIGI
		var next_scene: PackedScene = load("res://src/scenes/DiGiCharat.tscn")
		sceneChanger(next_scene)
	elif index == GALAXYANGEL:
		game_type_sub_text.text = "Supports 'Galaxy Angel' (most images)."
		game_type_selector.select(GALAXYANGEL)
		game_type = GALAXYANGEL
		var next_scene: PackedScene = load("res://src/scenes/ArtDink.tscn")
		sceneChanger(next_scene)
	elif index == GALAXYANGEL2EI:
		game_type_sub_text.text = "Supports 'Galaxy Angel II: Eigou Kaiki no Toki'"
		game_type_selector.select(GALAXYANGEL2EI)
		game_type = GALAXYANGEL2EI
		var next_scene: PackedScene = load("res://src/scenes/ArtDink.tscn")
		sceneChanger(next_scene)
	elif index == GALAXYANGEL2MU:
		game_type_sub_text.text = "Supports 'Galaxy Angel II: Mugen Kairou no Kagi'"
		game_type_selector.select(GALAXYANGEL2MU)
		game_type = GALAXYANGEL2MU
		var next_scene: PackedScene = load("res://src/scenes/ArtDink.tscn")
		sceneChanger(next_scene)
	elif index == GALAXYANGEL2ZE:
		game_type_sub_text.text = "Supports 'Galaxy Angel II: Zettai Ryouiki no Tobira'"
		game_type_selector.select(GALAXYANGEL2ZE)
		game_type = GALAXYANGEL2ZE
		var next_scene: PackedScene = load("res://src/scenes/ArtDink.tscn")
		sceneChanger(next_scene)
	elif index == GALAXYANGELETERNAL:
		game_type_sub_text.text = "Supports 'Galaxy Angel: Eternal Lovers' (most images)."
		game_type_selector.select(GALAXYANGELETERNAL)
		game_type = GALAXYANGELETERNAL
		var next_scene: PackedScene = load("res://src/scenes/ArtDink.tscn")
		sceneChanger(next_scene)
	elif index == GALAXYANGELMOON:
		game_type_sub_text.text = "Supports 'Galaxy Angel: Moonlit Lovers' (most images)."
		game_type_selector.select(GALAXYANGELMOON)
		game_type = GALAXYANGELMOON
		var next_scene: PackedScene = load("res://src/scenes/ArtDink.tscn")
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
	elif index == MAGI:
		game_type_sub_text.text = "Supports 'Ma-Gi: Marginal'."
		game_type_selector.select(MAGI)
		game_type = MAGI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == OTOMENOJIJOU:
		game_type_sub_text.text = "Supports 'Otome no Jijou'."
		game_type_selector.select(OTOMENOJIJOU)
		game_type = OTOMENOJIJOU
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == LOSTPASSAGE:
		game_type_sub_text.text = "Supports 'Lost Passage: Ushinawareta Hitofushi'."
		game_type_selector.select(LOSTPASSAGE)
		game_type = LOSTPASSAGE
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == SORAIROFUUKIN:
		game_type_sub_text.text = "Supports 'Sorairo no Fuukin Remix'."
		game_type_selector.select(SORAIROFUUKIN)
		game_type = SORAIROFUUKIN
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == DOUBLEWISH:
		game_type_sub_text.text = "Supports 'Double Wish'."
		game_type_selector.select(DOUBLEWISH)
		game_type = DOUBLEWISH
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == TENHIRO:
		game_type_sub_text.text = "Supports 'Tenohira wo Taiyou ni - Eikyuu no Kizuna'."
		game_type_selector.select(TENHIRO)
		game_type = TENHIRO
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
	elif index == INTERLUDE:
		game_type_sub_text.text = "Supports 'Interlude'."
		game_type_selector.select(INTERLUDE)
		game_type = INTERLUDE
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == SENTIMENTALPRELUDE:
		game_type_sub_text.text = "Supports 'Sentimental Prelude'."
		game_type_selector.select(SENTIMENTALPRELUDE)
		game_type = SENTIMENTALPRELUDE
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == AIR:
		game_type_sub_text.text = "Supports 'Air' (most images)."
		game_type_selector.select(AIR)
		game_type = AIR
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == ARABIANS:
		game_type_sub_text.text = "Supports 'Arabians Lost: The Engagement on Desert' (most images)."
		game_type_selector.select(ARABIANS)
		game_type = ARABIANS
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene) 
	elif index == LITTLEBUSTERS:
		game_type_sub_text.text = "Supports 'Little Busters! Converted Edition' (most images)."
		game_type_selector.select(LITTLEBUSTERS)
		game_type = LITTLEBUSTERS
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene) 
	elif index == CANVAS1:
		game_type_sub_text.text = "Supports 'Canvas: Sepia-iro no Motif' (most images)."
		game_type_selector.select(CANVAS1)
		game_type = CANVAS1
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == PLANETARIAN:
		game_type_sub_text.text = "Supports 'Planetarian: Chiisana Hoshi no Yume' (most images)."
		game_type_selector.select(PLANETARIAN)
		game_type = PLANETARIAN
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == SANGOKURENSEKI:
		game_type_sub_text.text = "Supports 'Sangoku Rensenki: Otome no Heihou!' (most images)."
		game_type_selector.select(SANGOKURENSEKI)
		game_type = SANGOKURENSEKI
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == FRIENDS:
		game_type_sub_text.text = "Supports 'Friends: Seishun no Kagayaki' (most images)."
		game_type_selector.select(FRIENDS)
		game_type = FRIENDS
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == CLOVERNOKUNI:
		game_type_sub_text.text = "Supports 'Clover no Kuni no Alice: Wonderful Wonder World' (most images)."
		game_type_selector.select(CLOVERNOKUNI)
		game_type = CLOVERNOKUNI
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == HEARTNOKUNI:
		game_type_sub_text.text = "Supports 'Heart no Kuni no Alice: Wonderful Wonder World' (most images)."
		game_type_selector.select(HEARTNOKUNI)
		game_type = HEARTNOKUNI
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == ELYSION:
		game_type_sub_text.text = "Supports 'Elysion: Eien no Sanctuary' (most images)."
		game_type_selector.select(ELYSION)
		game_type = ELYSION
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
		sceneChanger(next_scene)
	elif index == KANON:
		game_type_sub_text.text = "Supports 'Kanon' (most images)."
		game_type_selector.select(KANON)
		game_type = KANON
		var next_scene: PackedScene = load("res://src/scenes/Cybelle.tscn")
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
	elif index == FINALA:
		game_type_sub_text.text = "Supports 'Final Approach'."
		game_type_selector.select(FINALA)
		game_type = FINALA
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == FINALA2:
		game_type_sub_text.text = "Supports 'Final Approach 2: 1st Priority'."
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
	elif index == RUNEPRINCESS:
		game_type_sub_text.text = "Supports 'Rune Princess'."
		game_type_selector.select(RUNEPRINCESS)
		game_type = RUNEPRINCESS
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
	elif index == NATSUIROSUNADOKEI:
		game_type_sub_text.text = "Supports 'Natsuiro no Sunadokei'."
		game_type_selector.select(NATSUIROSUNADOKEI)
		game_type = NATSUIROSUNADOKEI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == NETTAITEIKIATSU:
		game_type_sub_text.text = "Supports 'Nettai Teikiatsu Shoujo'."
		game_type_selector.select(NETTAITEIKIATSU)
		game_type = NETTAITEIKIATSU
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == CAFELINDBERGHSUMMER:
		game_type_sub_text.text = "Supports 'Cafe Lindbergh: Summer Season'."
		game_type_selector.select(CAFELINDBERGHSUMMER)
		game_type = CAFELINDBERGHSUMMER
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == CAFELITTLEWISH:
		game_type_sub_text.text = "Supports 'Cafe Little Wish: Mahou no Recipe'."
		game_type_selector.select(CAFELITTLEWISH)
		game_type = CAFELITTLEWISH
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
	elif index == DOUBLEREACTION:
		game_type_sub_text.text = "Supports 'Double Reaction! Plus'."
		game_type_selector.select(DOUBLEREACTION)
		game_type = DOUBLEREACTION
		var next_scene: PackedScene = load("res://src/scenes/DatamPolystar.tscn")
		sceneChanger(next_scene)
	elif index == PRIVATENURSE:
		game_type_sub_text.text = "Supports 'Private Nurse: Maria'."
		game_type_selector.select(PRIVATENURSE)
		game_type = PRIVATENURSE
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
	elif index == JEWELSOCEAN:
		game_type_sub_text.text = "Supports 'Jewels Ocean: Star of Sierra Leone'."
		game_type_selector.select(JEWELSOCEAN)
		game_type = JEWELSOCEAN
		var next_scene: PackedScene = load("res://src/scenes/PioneSoft.tscn")
		sceneChanger(next_scene)
	elif index == AFTER:
		game_type_sub_text.text = "Supports:\nImages: PNG/TM2"
		game_type_selector.select(AFTER)
		game_type = AFTER
		var next_scene: PackedScene = load("res://src/scenes/PioneSoft.tscn")
		sceneChanger(next_scene)
	elif index == MUTSUBOSHI:
		game_type_sub_text.text = "Supports:\nImages: PNG/TM2"
		game_type_selector.select(MUTSUBOSHI)
		game_type = MUTSUBOSHI
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
	#elif index == REGISTA:
		#game_type_sub_text.text = "Basic support for Regista games."
		#game_type_selector.select(REGISTA)
		#game_type = REGISTA
		#var next_scene: PackedScene = load("res://src/scenes/Regista.tscn")
		#sceneChanger(next_scene)
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
	elif index == KIMISUTA:
		game_type_sub_text.text = "Supports 'KimiSuta: Kimi to Study'."
		game_type_selector.select(KIMISUTA)
		game_type = KIMISUTA
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == YUMEMISHI:
		game_type_sub_text.text = "Supports 'Yumemishi'."
		game_type_selector.select(YUMEMISHI)
		game_type = YUMEMISHI
		var next_scene: PackedScene = load("res://src/scenes/ZeroSystem.tscn")
		sceneChanger(next_scene)
	elif index == HOSHIFURU:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(HOSHIFURU)
		game_type = HOSHIFURU
		var next_scene: PackedScene = load("res://src/scenes/Piacci.tscn")
		sceneChanger(next_scene)
	elif index == TSUYOKISS2:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(TSUYOKISS2)
		game_type = TSUYOKISS2
		var next_scene: PackedScene = load("res://src/scenes/Piacci.tscn")
		sceneChanger(next_scene)
	elif index == TSUKIWAHIGASHI:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(TSUKIWAHIGASHI)
		game_type = TSUKIWAHIGASHI
		var next_scene: PackedScene = load("res://src/scenes/HuneX.tscn")
		sceneChanger(next_scene)
	elif index == PRINCESSHOLIDAY:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(PRINCESSHOLIDAY)
		game_type = PRINCESSHOLIDAY
		var next_scene: PackedScene = load("res://src/scenes/HuneX.tscn")
		sceneChanger(next_scene)
	elif index == KOISURU:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(KOISURU)
		game_type = KOISURU
		var next_scene: PackedScene = load("res://src/scenes/HuneX.tscn")
		sceneChanger(next_scene)
	elif index == OTOMEWABOKU:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(OTOMEWABOKU)
		game_type = OTOMEWABOKU
		var next_scene: PackedScene = load("res://src/scenes/HuneX.tscn")
		sceneChanger(next_scene)
	elif index == SOULLINK:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(SOULLINK)
		game_type = SOULLINK
		var next_scene: PackedScene = load("res://src/scenes/HuneX.tscn")
		sceneChanger(next_scene)
	elif index == KONOAOZORA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(KONOAOZORA)
		game_type = KONOAOZORA
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == YOAKE:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(YOAKE)
		game_type = YOAKE
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == HIGURASHI:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(HIGURASHI)
		game_type = HIGURASHI
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == HIGURASHIKAKERA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(HIGURASHIKAKERA)
		game_type = HIGURASHIKAKERA
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == PIAGO:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(PIAGO)
		game_type = PIAGO
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == PUREXCURE:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(PUREXCURE)
		game_type = PUREXCURE
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == KATAKAMUNA:
		game_type_sub_text.text = "Supports extraction only.\nDecompression routines not implemented yet."
		game_type_selector.select(KATAKAMUNA)
		game_type = KATAKAMUNA
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == PARFAIT:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(PARFAIT)
		game_type = PARFAIT
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == UNDERTHEMOON:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(UNDERTHEMOON)
		game_type = UNDERTHEMOON
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == SUGARSPICE:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(SUGARSPICE)
		game_type = SUGARSPICE
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == LOVEDROPS:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(LOVEDROPS)
		game_type = LOVEDROPS
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == CHANTER:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(CHANTER)
		game_type = CHANTER
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == TOGAINU:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG).\nMost images supported except .txa, .wip"
		game_type_selector.select(TOGAINU)
		game_type = TOGAINU
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == CHOCOLAT:
		game_type_sub_text.text = "Supports extraction only.\nDecompression routines not implemented yet."
		game_type_selector.select(CHOCOLAT)
		game_type = CHOCOLAT
		var next_scene: PackedScene = load("res://src/scenes/S_neo.tscn")
		sceneChanger(next_scene)
	elif index == SWEETSEASON:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(SWEETSEASON)
		game_type = SWEETSEASON
		var next_scene: PackedScene = load("res://src/scenes/Takuyo.tscn")
		sceneChanger(next_scene)
	elif index == HOSHIGARI:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(HOSHIGARI)
		game_type = HOSHIGARI
		var next_scene: PackedScene = load("res://src/scenes/Takuyo.tscn")
		sceneChanger(next_scene)
	elif index == YUKIGATARI:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(YUKIGATARI)
		game_type = YUKIGATARI
		var next_scene: PackedScene = load("res://src/scenes/Takuyo.tscn")
		sceneChanger(next_scene)
	elif index == HIMEHIBINEW:
		game_type_sub_text.text = "Supports:\nExtraction\nLSD decompression not implemented yet."
		game_type_selector.select(HIMEHIBINEW)
		game_type = HIMEHIBINEW
		var next_scene: PackedScene = load("res://src/scenes/Takuyo.tscn")
		sceneChanger(next_scene)
	elif index == ASOBINIIKUYO:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(ASOBINIIKUYO)
		game_type = ASOBINIIKUYO
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == PPOI:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(PPOI)
		game_type = PPOI
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == LOSTAYA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(LOSTAYA)
		game_type = LOSTAYA
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == AONOMAMA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(AONOMAMA)
		game_type = AONOMAMA
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == STEADYXSTUDY:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(STEADYXSTUDY)
		game_type = STEADYXSTUDY
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == HINOKAKERASHIN:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(HINOKAKERASHIN)
		game_type = HINOKAKERASHIN
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == YAMIYO:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(YAMIYO)
		game_type = YAMIYO
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == GAMENINATTA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(GAMENINATTA)
		game_type = GAMENINATTA
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == YOUKIHIMDEN:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(YOUKIHIMDEN)
		game_type = YOUKIHIMDEN
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == GETSUMENTO:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(GETSUMENTO)
		game_type = GETSUMENTO
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == NATSUZORA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(NATSUZORA)
		game_type = NATSUZORA
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == HAMETSU:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(HAMETSU)
		game_type = HAMETSU
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == NUGA:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(NUGA)
		game_type = NUGA
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == OSOUJI:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(OSOUJI)
		game_type = OSOUJI
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == TENKUU:
		game_type_sub_text.text = "Supports:\nExtraction, images (PNG)."
		game_type_selector.select(TENKUU)
		game_type = TENKUU
		var next_scene: PackedScene = load("res://src/scenes/IdeaFactory.tscn")
		sceneChanger(next_scene)
	elif index == SHUFFLE:
		game_type_sub_text.text = "Supports:\nImages (PNG)."
		game_type_selector.select(SHUFFLE)
		game_type = SHUFFLE
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == FRAGMENTSBLUE:
		game_type_sub_text.text = "Supports:\nImages (PNG)."
		game_type_selector.select(FRAGMENTSBLUE)
		game_type = FRAGMENTSBLUE
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == SHINE:
		game_type_sub_text.text = "Supports:\nImages (PNG).\nSupports some images"
		game_type_selector.select(SHINE)
		game_type = SHINE
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == SHAKUGAN:
		game_type_sub_text.text = "Supports:\nImages (PNG).\nSupports most images."
		game_type_selector.select(SHAKUGAN)
		game_type = SHAKUGAN
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == FUTAKOIALT:
		game_type_sub_text.text = "Supports:\nImages (PNG).\nSupports most images."
		game_type_selector.select(FUTAKOIALT)
		game_type = FUTAKOIALT
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == NOGIZAKA:
		game_type_sub_text.text = "Supports:\nImages (PNG).\nSupports BK images only."
		game_type_selector.select(NOGIZAKA)
		game_type = NOGIZAKA
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == GIRLSBRAVO:
		game_type_sub_text.text = "Supports:\nImages (PNG).\nSupports BK images only."
		game_type_selector.select(GIRLSBRAVO)
		game_type = GIRLSBRAVO
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == SOTSUGYOU:
		game_type_sub_text.text = "Supports:\nImages (PNG).\nSupports most images."
		game_type_selector.select(SOTSUGYOU)
		game_type = SOTSUGYOU
		var next_scene: PackedScene = load("res://src/scenes/Vridge.tscn")
		sceneChanger(next_scene)
	elif index == SUZUMIYA:
		game_type_sub_text.text = "Supports:\nExtraction, images (Custom TM2?)"
		game_type_selector.select(SUZUMIYA)
		game_type = SUZUMIYA
		var next_scene: PackedScene = load("res://src/scenes/AtelierDouble.tscn")
		sceneChanger(next_scene)
	elif index == MAHOUSENSEINEGIMA1:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)"
		game_type_selector.select(MAHOUSENSEINEGIMA1)
		game_type = MAHOUSENSEINEGIMA1
		var next_scene: PackedScene = load("res://src/scenes/AtelierDouble.tscn")
		sceneChanger(next_scene)
	elif index == MAHOUSENSEINEGIMA2:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)"
		game_type_selector.select(MAHOUSENSEINEGIMA2)
		game_type = MAHOUSENSEINEGIMA2
		var next_scene: PackedScene = load("res://src/scenes/AtelierDouble.tscn")
		sceneChanger(next_scene)
	elif index == INUYASHATHESECRET:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)"
		game_type_selector.select(INUYASHATHESECRET)
		game_type = INUYASHATHESECRET
		var next_scene: PackedScene = load("res://src/scenes/AtelierDouble.tscn")
		sceneChanger(next_scene)
	elif index == LOVEHINA:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)"
		game_type_selector.select(LOVEHINA)
		game_type = LOVEHINA
		var next_scene: PackedScene = load("res://src/scenes/AtelierDouble.tscn")
		sceneChanger(next_scene)
	elif index == CAMBRIAN:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2)."
		game_type_selector.select(CAMBRIAN)
		game_type = CAMBRIAN
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == HAKARENA:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(HAKARENA)
		game_type = HAKARENA
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == SHIROGANE:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(SHIROGANE)
		game_type = SHIROGANE
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == KAZEIROSURF:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(KAZEIROSURF)
		game_type = KAZEIROSURF
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == ITSUKA:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(ITSUKA)
		game_type = ITSUKA
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == STRIKEWITCHES:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(STRIKEWITCHES)
		game_type = STRIKEWITCHES
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == SUMOMOMO:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(SUMOMOMO)
		game_type = SUMOMOMO
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == SHUUMATSUSHOUJO:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(SHUUMATSUSHOUJO)
		game_type = SHUUMATSUSHOUJO
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == ZNTKOAKUMA:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(ZNTKOAKUMA)
		game_type = ZNTKOAKUMA
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == ZNTMAIGO:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(ZNTMAIGO)
		game_type = ZNTMAIGO
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
	elif index == ZNTMUMA:
		game_type_sub_text.text = "Supports:\nExtraction, images (TM2 and some BMP)."
		game_type_selector.select(ZNTMUMA)
		game_type = ZNTMUMA
		var next_scene: PackedScene = load("res://src/scenes/SocioArtLogic.tscn")
		sceneChanger(next_scene)
		
		
func sceneChanger(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
	return
	
	
func initMenuItems() -> void:
	# Menu items must be in alphabetical order based on their enum value.
	
	game_type_selector.add_item("3LDK - Shiawase ni Narouyo", THREELDK)
	game_type_selector.add_item("12Riven: The Psi-Climinal of Integral", TWELVERIVEN)
	game_type_selector.add_item("Air", AIR)
	game_type_selector.add_item("Ai Yori Aoshi", AIYORIAOSHI)
	game_type_selector.add_item("After... Wasureenu Kizuna", AFTER)
	game_type_selector.add_item("Amagami", AMAGAMI)
	game_type_selector.add_item("Angel's Feather", ANGELSFEATHER)
	game_type_selector.add_item("Angel Wish: Kimi no Egao ni Chu!", ANGELWISH)
	game_type_selector.add_item("Ao no Mama de", AONOMAMA)
	game_type_selector.add_item("Arabians Lost: The Engagement on Desert", ARABIANS)
	game_type_selector.add_item("Arcana Heart", ARCANAHEART)
	game_type_selector.add_item("Asobi ni Iku yo! Chikyuu Pinch no Kon'yaku Sengen", ASOBINIIKUYO)
	game_type_selector.add_item("Binchou-Tan: Shiawasegoyomi", BINCHOUTAN)
	game_type_selector.add_item("Cafe Lindbergh: Summer Season", CAFELINDBERGHSUMMER)
	game_type_selector.add_item("Cafe Little Wish: Mahou no Recipe", CAFELITTLEWISH)
	game_type_selector.add_item("Cambrian QTS: Kaseki ni Nattemo", CAMBRIAN)
	game_type_selector.add_item("Canvas: Sepia-iro no Motif", CANVAS1)
	game_type_selector.add_item("Canvas 2: Akaneiro no Palette", CANVAS2)
	game_type_selector.add_item("Cartagra: Tamashii no Kunou", CARTAGRA)
	game_type_selector.add_item("Castle Fantasia: Erencia Senki - Plus Stories", CASTLEFANTASIA)
	game_type_selector.add_item("Chanter: Kimi no Uta ga Todoitara", CHANTER)
	game_type_selector.add_item("Chocolat: Maid Cafe Curio", CHOCOLAT)
	game_type_selector.add_item("Clover no Kuni no Alice: Wonderful Wonder World", CLOVERNOKUNI)
	game_type_selector.add_item("Code Geass: Hangyaku no Lelouch - Lost Colors", CODEGEASS)
	game_type_selector.add_item("Colorful Aquarium: My Little Mermaid", COLORFULAQUA)
	game_type_selector.add_item("D-A:  Black", DABLACK)
	game_type_selector.add_item("D-A:  White", DAWHITE)
	game_type_selector.add_item("D.C. II P.S.: Da Capo II Plus Situation", DCTWO)
	game_type_selector.add_item("D.C.F.S.: Da Capo Four Seasons", DCFS)
	game_type_selector.add_item("D.C.I.F.: Da Capo Innocent Finale", DCIF)
	game_type_selector.add_item("D.C.P.S.: Da Capo Plus Situation", DCPS)
	game_type_selector.add_item("D.C.: The Origin", DCORIGIN)
	game_type_selector.add_item("Dear My Friend: Love Like Powdery Snow", DEARMYFRIEND)
	game_type_selector.add_item("Di Gi Charat Fantasy: Excellent", DIGI)
	game_type_selector.add_item("Doko he Iku no, Anohi", DOKOHE)
	game_type_selector.add_item("Double Reaction! Plus", DOUBLEREACTION)
	game_type_selector.add_item("Double Wish (WWish)", DOUBLEWISH)
	game_type_selector.add_item("ef: A Fairy Tale of the Two", EF)
	game_type_selector.add_item("Elysion: Eien no Sanctuary", ELYSION)
	game_type_selector.add_item("Erde: Nezu no Ki no Shita de", ERDE)
	game_type_selector.add_item("F: Fanatic", FANATIC)
	game_type_selector.add_item("Festa!! Hyper Girls Party", FESTAHYPER)
	game_type_selector.add_item("Final Approach", FINALA)
	game_type_selector.add_item("Final Approach 2: 1st Priority", FINALA2)
	game_type_selector.add_item("Finalist", FINALIST) #make a AFS file reader
	game_type_selector.add_item("Fragments Blue", FRAGMENTSBLUE)
	game_type_selector.add_item("Friends: Seishun no Kagayaki", FRIENDS)
	game_type_selector.add_item("Fukakutei Sekai no Tantei Shinshi: Akugyou Futaasa no Jiken File", FUKAKUTEI)
	game_type_selector.add_item("Fushigi no Umi no Nadia: Inherit the Blue Water", FUSHIGINOUMI)
	game_type_selector.add_item("Fushigi no Umi no Nadia: Dennou Battle - Miss Nautilus Contest", FUSHIGINOUMIDENNOU)
	game_type_selector.add_item("Futakoi", FUTAKOI)
	game_type_selector.add_item("Futakoi Alternative: Koi to Shoujo to Machine Gun", FUTAKOIALT)
	game_type_selector.add_item("Futakoijima: Koi to Mizugi no Survival", FUTAKOIJIMA)
	game_type_selector.add_item("Galaxy Angel", GALAXYANGEL)
	game_type_selector.add_item("Galaxy Angel II: Eigou Kaiki no Toki", GALAXYANGEL2EI)
	game_type_selector.add_item("Galaxy Angel II: Mugen Kairou no Kagi", GALAXYANGEL2MU)
	game_type_selector.add_item("Galaxy Angel II: Zettai Ryouiki no Tobira", GALAXYANGEL2ZE)
	game_type_selector.add_item("Galaxy Angel: Eternal Lovers", GALAXYANGELETERNAL)
	game_type_selector.add_item("Galaxy Angel: Moonlit Lovers", GALAXYANGELMOON)
	game_type_selector.add_item("Game ni Natta yo! Dokuro-chan - Kenkou Shindan Daisakusen", GAMENINATTA)
	game_type_selector.add_item("Getsumento Heiki Mina: Futatsu no Project M", GETSUMENTO)
	game_type_selector.add_item("Gift: Prism", GIFTPRISIM)
	game_type_selector.add_item("Gin no Eclipse", GINNOECLIPSE)
	game_type_selector.add_item("Girls Bravo: Romance 15's", GIRLSBRAVO)
	game_type_selector.add_item("Guisard Revolution: Bokura wa Omoi wo Mi ni Matou", GUISARD)
	game_type_selector.add_item("Hakarena Heart: Kimi ga Tame ni Kagayaki wo", HAKARENA)
	game_type_selector.add_item("Hakushaku to Yousei: Yume to Kizuna ni Omoi Hasete", HAKUSHAKU)
	game_type_selector.add_item("Hametsu no Mars", HAMETSU)
	game_type_selector.add_item("Happy Breeding: Cheerful Party", HAPPYBREED)
	game_type_selector.add_item("Happiness! De-Lucks", HAPPYDELUCKS)
	game_type_selector.add_item("Harukaze P.S: Plus Situation", HARUKAZEPS)
	game_type_selector.add_item("Heart no Kuni no Alice: Wonderful Wonder World", HEARTNOKUNI)
	game_type_selector.add_item("Higurashi no Naku Koro ni Matsuri", HIGURASHI)
	game_type_selector.add_item("Higurashi no Naku Koro ni Matsuri: Kakera Asobi", HIGURASHIKAKERA)
	game_type_selector.add_item("Himehibi: New Princess Days!! Zoku! Nigakki", HIMEHIBINEW)
	game_type_selector.add_item("Hiiro no Kakera: Shin Tamayorihime Denshou", HINOKAKERASHIN)
	game_type_selector.add_item("Hokenshitsu he Youkoso", HOKENSHITSU)
	game_type_selector.add_item("Hooligan: Kimi no Naka no Yuuki", HOOLIGAN)
	game_type_selector.add_item("Hoshifuru: Hoshi no Furu Machi", HOSHIFURU)
	game_type_selector.add_item("Hoshigari Empusa", HOSHIGARI)
	game_type_selector.add_item("Hurrah! Sailor", HURRAH)
	game_type_selector.add_item("Hyakko: Yorozuya Jikenbo!", HYAKKO)
	game_type_selector.add_item("Ichigo 100% Strawberry Diary", ICHIGOHUNDRED)
	game_type_selector.add_item("Idol Janshi R: Janguru Project", IDOLJANSHIR)
	game_type_selector.add_item("Iinazuke", IINAZUKE)
	game_type_selector.add_item("Interlude", INTERLUDE)
	game_type_selector.add_item("Inuyasha: The Secret of the Cursed Mask", INUYASHATHESECRET)
	game_type_selector.add_item("Itsuka, Todoku, Ano Sora ni. ~You no Michi to Hi no Tasogare to~", ITSUKA)
	game_type_selector.add_item("Izumo Zero: Yokohama Ayakashi Emaki", IZUMOZERO)
	game_type_selector.add_item("Jewels Ocean: Star of Sierra Leone", JEWELSOCEAN)
	game_type_selector.add_item("Jigoku Shoujo Mioyosuga", JIGOKUSHOUJO)
	game_type_selector.add_item("Juujigen Rippoutai Cipher: Game of Survival", JUUJIGEN)
	game_type_selector.add_item("Kaiketsu! Osabakiina", KAIKETSUOSHABAKIINA)
	game_type_selector.add_item("Kanokon Esuii", KANOKON)
	game_type_selector.add_item("Kanon", KANON)
	game_type_selector.add_item("Katakamuna: Ushinawareta Ingaritsu", KATAKAMUNA)
	game_type_selector.add_item("Kazeiro Surf", KAZEIROSURF)
	game_type_selector.add_item("Kidou Shinsengumi: Moe yo Ken", KIDOUSHINSENGUMI)
	game_type_selector.add_item("Kimi ga Aruji de Shitsuji ga Ore de: Otsukae Nikki", KIMIGAARUJI)
	game_type_selector.add_item("KimiKiss", KIMIKISS)
	game_type_selector.add_item("KimiSuta: Kimi to Study", KIMISUTA)
	game_type_selector.add_item("Kira Kira: Rock 'N' Roll Show", KIRAKIRA)
	game_type_selector.add_item("Kishin Houkou Demonbane", KISHINHOUKOU)
	game_type_selector.add_item("Koi-hime Musou: Doki Otome Darake no Sangokushi Engi", KOIHIMEMUSOU)
	game_type_selector.add_item("Koi suru Otome to Shugo no Tate: The Shield of AIGIS", KOISURU)
	game_type_selector.add_item("Kokoro no Tobira", KOKORONOTOBIRA)
	game_type_selector.add_item("Kono Aozora ni Yakusoku wo: Melody of the Sun and Sea", KONOAOZORA)
	game_type_selector.add_item("Little Busters! Converted Edition", LITTLEBUSTERS)
	game_type_selector.add_item("L no Kisetsu 2: Invisible Memories", LNOKISETSU)
	game_type_selector.add_item("Lost Aya Sophia", LOSTAYA)
	game_type_selector.add_item("Lost Passage: Ushinawareta Hitofushi", LOSTPASSAGE)
	game_type_selector.add_item("Love Doll: Lovely Idol", LOVEDOLL)
	game_type_selector.add_item("Love Drops", LOVEDROPS)
	game_type_selector.add_item("Love Hina Gorgeous: Chiratto Happening!!", LOVEHINA)
	game_type_selector.add_item("Luxury & Beauty: Lucian Bee's - Evil Violet", LUXBEVIL)
	game_type_selector.add_item("Mabino x Style", MABINOSTYLE)
	game_type_selector.add_item("Ma-Gi: Marginal", MAGI)
	game_type_selector.add_item("Magical Tale: Chiicha na Mahoutsukai", MAGICAL)
	game_type_selector.add_item("Mahou Sensei Negima! 1-Jikanme ~Okochama Sensei wa Mahoutsukai!~", MAHOUSENSEINEGIMA1)
	game_type_selector.add_item("Mahou Sensei Negima! 2-jikanme Tatakau Otome-tachi! Mahora Daiundoukai Special!", MAHOUSENSEINEGIMA2)
	game_type_selector.add_item("Mai-HiME: Unmei no Keitouju", MAIHIME)
	game_type_selector.add_item("Meitantei Evangelion", MEITANTEIEVA)
	game_type_selector.add_item("Memories Off 5: Encore", MEMORIESOFF5EN)
	game_type_selector.add_item("Memories Off 5: Togireta Film", MEMORIESOFF5TO)
	game_type_selector.add_item("Memories Off 6: Next Relation", MEMORIESOFF6NEXT)
	game_type_selector.add_item("Memories Off 6: T-Wave", MEMORIESOFF6TWAVE)
	game_type_selector.add_item("Memories Off: Sorekara Again", MEMORIESOFFSOREAGAIN)
	game_type_selector.add_item("Men at Work! 3: Ai to Seishun no Hunter Gakuen", MENATWORK3)
	game_type_selector.add_item("Metal Wolf REV", METALWOLF)
	game_type_selector.add_item("Missing Blue", MISSINGBLUE)
	game_type_selector.add_item("Mizu no Senritsu", MIZUNOSENRITSU)
	game_type_selector.add_item("Mizu no Senritsu 2: Hi no Kioku", MIZUNOSENRITSU2)
	game_type_selector.add_item("Moekan: Moekko Company", MOEKAN)
	game_type_selector.add_item("Moe Moe 2-Ji Taisen 2 (Ryaku)", MOEMOE2JI2)
	game_type_selector.add_item("Moe Moe 2-Ji Taisen (Ryaku) Deluxe", MOEMOE2JIDEL)
	game_type_selector.add_item("Monochrome", MONOCHROME)
	game_type_selector.add_item("Monochrome Factor: Cross Road", MONOCHROMEFACTOR)
	game_type_selector.add_item("Mutsuboshi Kirari: Hoshi Furu Miyako", MUTSUBOSHI)
	game_type_selector.add_item("My Merry Maybe", MYMARRYMAYBE)
	game_type_selector.add_item("My Merry May with be", MYMARRYWITHBE)
	game_type_selector.add_item("Mystereet: Yasogami Kaoru no Jiken File", MYSTEREET)
	game_type_selector.add_item("Natsuiro: Hoshikuzu no Memory", NATSUIROHOSHI)
	game_type_selector.add_item("Natsuiro Komachi", NATSUIROKOMACHI)
	game_type_selector.add_item("Natsuiro no Sunadokei", NATSUIROSUNADOKEI)
	game_type_selector.add_item("Natsuzora no Monologue", NATSUZORA)
	game_type_selector.add_item("Natural 2: Duo - Sakurairo no Kisetsu", NATURAL2)
	game_type_selector.add_item("Nettai Teikiatsu Shoujo", NETTAITEIKIATSU)
	game_type_selector.add_item("Night Wizard the Video Game - Denial of the World", NIGHTWIZARD)
	game_type_selector.add_item("Nogizaka Haruka no Himitsu: Cosplay, Hajimemashita", NOGIZAKA)
	game_type_selector.add_item("North Wind: Eien no Yakusoku", NORTHWIND)
	game_type_selector.add_item("NUGA-CEL!: Nurture Garment Celebration", NUGA)
	game_type_selector.add_item("Nurse Witch Komugi-chan Maji-Karte", NURSEWITCH)
	game_type_selector.add_item("Ojousama Kumikyoku: Sweet Concert", OJOUSAMAKUMI)
	game_type_selector.add_item("Orange Pocket:  Root", ORANGEPOCKET)
	game_type_selector.add_item("Osouji Sentai Clean Keeper H", OSOUJI)
	game_type_selector.add_item("Otome no Jijou", OTOMENOJIJOU)
	game_type_selector.add_item("Otome wa Boku ni Koishiteru", OTOMEWABOKU)
	game_type_selector.add_item("Ouka: Kokoro Kagayakaseru Sakura", OUKA)
	game_type_selector.add_item("Parfait: Chocolat Second Style", PARFAIT)
	game_type_selector.add_item("Patisserie na Nyanko: Hatsukoi wa Ichigo Aji", PATISSERIE)
	game_type_selector.add_item("Phantom: Phantom of Inferno", PHANTOMINFERNO)
	game_type_selector.add_item("Pia Carrot he Youkoso!! 3: Round Summer", PIA3)
	game_type_selector.add_item("Pia Carrot he Youkoso!! G.O. Summer Fair", PIAGO)
	game_type_selector.add_item("Pizzicato Polka: Suisei Genya", PIZZICATOPOLKA)
	game_type_selector.add_item("Planetarian: Chiisana Hoshi no Yume", PLANETARIAN)
	game_type_selector.add_item("Ppoi! Hito Natsu no Keiken!", PPOI)
	game_type_selector.add_item("Princess Concerto", PRINCESSCONCERTO)
	game_type_selector.add_item("Princess Holiday: Korogaru Ringo Tei Sen'ya Ichiya", PRINCESSHOLIDAY)
	game_type_selector.add_item("Princess Lover! Eternal Love for My Lady", PRINCESSLOVER)
	game_type_selector.add_item("Princess Maker 5", PRINCESSMAKER5)
	game_type_selector.add_item("Princess Nightmare", PRINCESSNIGHTMARE)
	game_type_selector.add_item("Princess Princess: Himetachi no Abunai Houkago", PRINCESSPRINCESS)
	game_type_selector.add_item("Pri-Saga! Princess wo Sagase!", PRISAGA)
	game_type_selector.add_item("Prism Ark: Awake", PRISMARK)
	game_type_selector.add_item("Private Nurse: Maria", PRIVATENURSE)
	game_type_selector.add_item("Pure Pure: Mimi to Shippo no Monogatari", PUREPURE)
	game_type_selector.add_item("Pure x Cure Recovery", PUREXCURE)
	game_type_selector.add_item("Que: Ancient Leaf no Yousei", QUE)
	game_type_selector.add_item("Quilt: Anata to Tsumugu Yume to Koi no Dress", QUILT)
	#game_type_selector.add_item("Regista Games", REGISTA)
	game_type_selector.add_item("Rosario to Vampire Capu 2: Koi to Yume no Rhapsodia", ROSARIO)
	game_type_selector.add_item("Routes PE", ROUTESPE)
	game_type_selector.add_item("Rozen Maiden: duellwalzer", ROZENDUEL)
	game_type_selector.add_item("Rune Princess", RUNEPRINCESS)
	game_type_selector.add_item("Ryuu Koku", RYUUKOKU)
	game_type_selector.add_item("Saishuu Shiken Kujira: Alive", SAISHUUSHIKEN)
	game_type_selector.add_item("Sakura: Setsugekka", SAKURASESTU)
	game_type_selector.add_item("Sangoku Rensenki: Otome no Heihou!", SANGOKURENSEKI)
	game_type_selector.add_item("School Love! Koi to Kibou no Metronome", SCHOOLLOVE)
	game_type_selector.add_item("School Rumble Ni-Gakki", SCHOOLNI)
	game_type_selector.add_item("Seikai no Senki", SEIKAINOSENKI)
	game_type_selector.add_item("Sega Ages 2500 Series Vol. 12: Puyo Puyo Tsuu Perfect Set", SEGAAGESVOL12)
	game_type_selector.add_item("Sengoku-hime 2: En - Hyakka, Senran Tatsukaze no Gotoku")
	game_type_selector.add_item("Sentimental Prelude", SENTIMENTALPRELUDE)
	game_type_selector.add_item("Separate Hearts", SEPARATEHEARTS)
	game_type_selector.add_item("Shakugan no Shana", SHAKUGAN)
	game_type_selector.add_item("Shine: Kotoba wo Tsumui de", SHINE)
	game_type_selector.add_item("Shin Koihime Musou: Otome Ryouran Sangokushi Engi", SHINKOIHIME)
	game_type_selector.add_item("Shin Seiki Evangelion: Battle Orchestra", SHINSEIKIEVABATTLE)
	game_type_selector.add_item("Shoujo Mahou Gaku Littlewitch Romanesque: Aria to Kaya to Kuro no Tou", SHOUJOMAHOU)
	game_type_selector.add_item("Shirogane no Soleil: Contract to the Future - Mirai he no Keiyaku", SHIROGANE)
	game_type_selector.add_item("Shuffle! On the Stage", SHUFFLE)
	game_type_selector.add_item("Shuumatsu Shoujo Gensou Alicematic: Apocalypse", SHUUMATSUSHOUJO)
	game_type_selector.add_item("Skip Beat!", SKIPBEAT)
	game_type_selector.add_item("Sorairo no Fuukin Remix", SORAIROFUUKIN)
	game_type_selector.add_item("Sotsugyou 2nd Generation", SOTSUGYOU)
	game_type_selector.add_item("Soul Link Extension", SOULLINK)
	game_type_selector.add_item("StarTRain: Your Past Makes Your Future", STARTRAIN)
	game_type_selector.add_item("Steady x Study", STEADYXSTUDY)
	game_type_selector.add_item("Strawberry Panic!", STRAWBERRYPANIC)
	game_type_selector.add_item("Strike Witches: Anata to Dekiru Koto - A Little Peaceful Days", STRIKEWITCHES)
	game_type_selector.add_item("Sugar + Spice! Ano Ko no Suteki na Nani mo Kamo", SUGARSPICE)
	game_type_selector.add_item("Suggoi! Arcana Heart 2", SUGGOIARCANAHEART2)
	game_type_selector.add_item("Suigetsu: Mayoi Gokoro", SUIGETSUMAYOI)
	game_type_selector.add_item("Suika A.S+: Eternal Name", SUIKA)
	game_type_selector.add_item("SuiSui Sweet: ~Amai Koi No Mitsukekata~")
	game_type_selector.add_item("Sumomomo Momomo - Chijou Saikyou no Yome", SUMOMOMO)
	game_type_selector.add_item("Suzumiya Haruhi no Tomadoi", SUZUMIYA)
	game_type_selector.add_item("Sweet Legacy: Boku to Kanojo no Na mo Nai Okashi", SWEETLEGACY)
	game_type_selector.add_item("Sweet Season", SWEETSEASON)
	game_type_selector.add_item("Tenohira wo Taiyou ni: Eikyuu no Kizuna", TENHIRO)
	game_type_selector.add_item("Tenkuu Danzai: Skelter Heaven", TENKUU)
	game_type_selector.add_item("Tentama: 1st Sunny Side", TENTAMA1ST)
	game_type_selector.add_item("Tentama 2: Wins", TENTAMA2)
	game_type_selector.add_item("The Magician's Academy", THEMAGICIAN)
	game_type_selector.add_item("Togainu no Chi: True Blood", TOGAINU)
	game_type_selector.add_item("To Heart", TOHEART)
	game_type_selector.add_item("To Heart 2", TOHEART2)
	game_type_selector.add_item("Triggerheart Exelica Enhanced", TRIGGERHEART)
	game_type_selector.add_item("Trouble Fortune Company:  Happy Cure", TROUBLEFORTUNE)
	game_type_selector.add_item("True Love Story 3", TRUELOVESTORY3)
	game_type_selector.add_item("True Love Story: Summer Days, and Yet...", TRUELOVESTORYSUMMER)
	game_type_selector.add_item("True Tears", TRUETEARS)
	game_type_selector.add_item("Tsuki wa Higashi ni Hi wa Nishi ni: Operation Sanctuary", TSUKIWAHIGASHI)
	game_type_selector.add_item("Tsuyo Kiss: Mighty Heart", TSUYOKISS)
	game_type_selector.add_item("Tsuyo Kiss 2 Gakki: Swift Love", TSUYOKISS2)
	game_type_selector.add_item("Umisho", UMISHO)
	game_type_selector.add_item("Under the Moon: Crescent", UNDERTHEMOON)
	game_type_selector.add_item("Utau * Tumbling Dice", UTAU)
	game_type_selector.add_item("WeAre*", WEARE)
	game_type_selector.add_item("White Breath: Kizuna", WHITEBREATH)
	game_type_selector.add_item("White Princess the Second", WHITEPRINCESS)
	game_type_selector.add_item("Yamiyo ni Sasayaku: Tantei Sagara Kyouichirou", YAMIYO)
	game_type_selector.add_item("Yatohime Zankikou", YATOHIME)
	game_type_selector.add_item("Yo-Jin-Bo: Unmei no Freude", YOJINBO)
	game_type_selector.add_item("Yoake Mae Yori Ruriiro na: Brighter than Dawning Blue", YOAKE)
	game_type_selector.add_item("Youkihimeden: Ayakashi Gentoubanashi", YOUKIHIMDEN)
	game_type_selector.add_item("Your Memories Off: Girl's Style", YRMEMORIES)
	game_type_selector.add_item("Yuki Gatari: Renewal Edition", YUKIGATARI)
	game_type_selector.add_item("Yumemi Hakusho: Second Dream", YUMEMI)
	game_type_selector.add_item("Yumemishi", YUMEMISHI)
	game_type_selector.add_item("Zero no Tsukaima: Koakuma to Harukaze no Concerto", ZNTKOAKUMA)
	game_type_selector.add_item("Zero no Tsukaima: Maigo no Period to Ikusen no Symphony", ZNTMAIGO)
	game_type_selector.add_item("Zero no Tsukaima: Muma ga Tsumugu Yokaze no Fantasy", ZNTMUMA)
	#print(game_type_selector.item_count)
	#for i in range(game_type_selector.item_count):
		#print("* %s" % game_type_selector.get_item_text(i))
	return
