extends StaticBody3D
## Jeden ovladatelný kus výtahu: dveře, mříž, tlačítko.
var vytah: Node
var akce: Array = []

func pouzij(_kdo: Node) -> void:
	if vytah:
		vytah.akce(akce)
