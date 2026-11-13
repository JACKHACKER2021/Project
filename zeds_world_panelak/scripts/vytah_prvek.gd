extends StaticBody3D
## Jeden ovladatelný kus výtahu: dveře, mříž, tlačítko.
var vytah: Node
var akce: Array = []

func pouzij(_kdo: Node) -> void:
	if vytah:
		vytah.akce(akce)

func popis() -> String:
	if akce.is_empty():
		return "Výtah"
	match akce[0]:
		"dvere": return "Šachetní dveře – %d. patro" % akce[1]
		"mriz": return "Shrnovací mříž kabiny"
		"volat": return "Přivolat výtah (%d. patro)" % akce[1]
		"jed": return "Jet do %d. patra" % akce[1]
		"stop": return "STOP"
	return "Výtah"
