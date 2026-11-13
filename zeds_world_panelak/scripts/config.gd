class_name ZWConfig
extends RefCounted
## Sdílené rozměry domu. Musí sedět s generátorem modelu (build.py).

const VERZE := "v0.3.0 build 2026-11-13 16:00"

const HX := 36.0          # půlka délky domu
const HZ := 12.0          # půlka hloubky domu
const WALL := 0.30
const COR_HZ := 2.2       # půlka šířky chodby
const FLOOR_H := 3.0      # výška podlaží
const FLOOR0_Y := 1.4     # podlaha prvního obytného podlaží
const FLOORS := 99        # počet obytných podlaží

# šachta výtahu
const SH_X0 := -2.4
const SH_X1 := 2.4
const SH_Z0 := 2.6
const SH_Z1 := 7.4
# schodiště
const ST_X0 := 4.4
const ST_X1 := 15.0
const ST_Z0 := 2.6
const ST_Z1 := 11.4

# jádro domu: výtah a schodiště mají vlastní prostor, byty tam nejsou
const JADRO_X0 := -3.4
const JADRO_X1 := 16.0

# sklep
const CELLAR_H := 14.0
const CELLARS := 3

# byty: 8 dveří na každé straně chodby, rozteč 8.6 m
const APT_COUNT := 8
const APT_X0 := -32.0
const APT_DX := 8.6

static func floor_y(f: int) -> float:
	if f >= 0:
		return FLOOR0_Y + f * FLOOR_H
	return -CELLAR_H * float(-f)

static func y_to_floor(y: float) -> int:
	if y >= 0.0:
		return int(round((y - FLOOR0_Y) / FLOOR_H))
	return -int(ceil(-y / CELLAR_H))

static func apt_x(i: int) -> float:
	return APT_X0 + i * APT_DX
