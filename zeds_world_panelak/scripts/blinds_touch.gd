extends StaticBody3D
var zaluzie: Node
func pouzij(_kdo: Node) -> void:
	if zaluzie:
		zaluzie.prepni()

func popis() -> String:
	if zaluzie and zaluzie.zatazeno:
		return "Vytáhnout žaluzie"
	return "Zatáhnout žaluzie"
