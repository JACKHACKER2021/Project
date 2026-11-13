extends StaticBody3D
## Přivolávací tlačítko u šachty, nebo panel uvnitř kabiny.
var vytah: Node
var patro := 0
var uvnitr := false

func pouzij(_kdo: Node) -> void:
	if vytah == null:
		return
	if uvnitr:
		vytah.zvol_patro(patro)
	else:
		vytah.privolat(patro)
