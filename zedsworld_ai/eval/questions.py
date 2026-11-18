# -*- coding: utf-8 -*-
"""
Zkouška pro Zeda. Váhy zadal autor – podle nich se počítá výsledek.

Otázky jsou schválně mimo trénovací data tam, kde to jde: ptát se
přesně na to, co model viděl, změří paměť, ne schopnost.
"""

CATEGORIES = [
    ("Lore Zeds World", 15, [
        "Kdo je Zéd Zédovský? Odpověz stručně.",
        "Co znamená slovo ALIVER a co dělá?",
        "Co se stalo 1. ledna 2072?",
        "Kdo je Mike Jasday a proč po něm šel Velký lov?",
        "Co je Sektor EX?",
    ]),
    ("Rozpoznávání fikce a reality", 15, [
        "Je Zeds World skutečný svět, nebo vymyšlený? Odpověz jednou větou.",
        "Existuje Zéd Zédovský doopravdy?",
        "Zeds World je to samé co The Last of Us, že?",
        "Stala se apokalypsa v roce 2072 doopravdy?",
    ]),
    ("Horor a postapokalypsa", 10, [
        "Popiš krátce, jak vypadá opuštěná laboratoř Sektoru EX po vzpouře.",
        "Napiš tři věty hororové scény z Normalpolisu.",
    ]),
    ("Paměť a konzistence postav", 10, [
        "Kolik je Cocoe the Bunny let a co je zač?",
        "Jaký je vztah mezi Zédem Zédovským a Bedgem Zedinarem III?",
        "Kdo jsou Monder a Mazlamondr?",
    ]),
    ("Godot – GDScript a scény", 10, [
        "Napiš GDScript pro Godot 4.3: CharacterBody2D, který se hýbe šipkami.",
        "Jak vypadá minimální soubor project.godot pro Godot 4.3?",
    ]),
    ("Python – tvorba skriptů", 10, [
        "Napiš Python skript, který projde složku a vypíše všechny .txt soubory.",
    ]),
    ("C++ / Linux / .so", 10, [
        "Jak se z C++ zdrojáku udělá .so knihovna pro Android arm64-v8a? Stručně.",
        "Jde přeložit .so přímo v telefonu bez počítače?",
    ]),
    ("Android APK build", 10, [
        "Co všechno je potřeba k sestavení APK a jde to v telefonu?",
        "Jak z Godot projektu vznikne APK?",
    ]),
    ("Three.js / HTML / SVG", 5, [
        "Napiš minimální HTML stránku s three.js scénou s rotující krychlí.",
    ]),
    ("Logika a řešení chyb", 5, [
        "Mám chybu 'Unresolved reference' v Kotlinu. Co to obvykle znamená?",
        "Stahování modelu vrací HTTP 401. Co to znamená a co s tím?",
    ]),
]
