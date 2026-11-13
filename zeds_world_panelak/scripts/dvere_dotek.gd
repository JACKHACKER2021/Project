extends StaticBody3D
var dvere: Node
func pouzij(kdo: Node) -> void:
	if dvere:
		dvere.pouzij(kdo)
func popis() -> String:
	if dvere == null:
		return "Dveře"
	if dvere.zamceno:
		return "Dveře bytu %d – %s (zamčeno)" % [dvere.cislo, dvere.jmeno]
	return "%s dveře bytu %d – %s" % ["Zavřít" if dvere.otevreno else "Otevřít",
		dvere.cislo, dvere.jmeno]

func zasah_sekerou(_kolik: float) -> void:
	if dvere:
		dvere.zamceno = false
		dvere.pouzij(null)
