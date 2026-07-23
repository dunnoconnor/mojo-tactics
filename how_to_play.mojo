from std.python import Python, PythonObject
from std.collections import List
from constants import SCREEN_WIDTH, SCREEN_HEIGHT

struct HowToPlayScreen:
    var pygame: PythonObject
    var screen: PythonObject
    var font: PythonObject
    var big_font: PythonObject

    def __init__(out self, pygame: PythonObject, screen: PythonObject, font: PythonObject, big_font: PythonObject):
        self.pygame = pygame
        self.screen = screen
        self.font = font
        self.big_font = big_font

    def handle_click(mut self, pos: PythonObject) -> Bool:
        return True

    def draw(mut self) raises:
        var COLOR_BG = Python.tuple(20, 10, 30)
        var COLOR_TITLE = Python.tuple(255, 140, 0)
        var COLOR_TEXT = Python.tuple(255, 255, 255)
        var COLOR_SECTION = Python.tuple(255, 200, 100)
        var COLOR_BACK = Python.tuple(180, 180, 255)

        self.screen.fill(COLOR_BG)

        var title_surf = self.big_font.render("How to Play", True, COLOR_TITLE)
        var title_rect = title_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, 40))
        self.screen.blit(title_surf, title_rect)

        var lines = List[String]()
        lines.append("GOAL")
        lines.append("Defeat all 6 bugs to win.")
        lines.append("Fewest turns to win is saved as your fastest run.")
        lines.append("")
        lines.append("CONTROLS")
        lines.append("Left click: select, move, attack, use powers")
        lines.append("Right click: deselect current unit")
        lines.append("")
        lines.append("MOVEMENT")
        lines.append("Select a unit, then click a green tile to move.")
        lines.append("Movement cost: Grass=1, Water=2, Rocks=blocked.")
        lines.append("Max movement budget is 4 per unit per turn.")
        lines.append("")
        lines.append("ATTACK")
        lines.append("Click an adjacent enemy to deal 1 damage.")
        lines.append("")
        lines.append("POWERS")
        lines.append("All units can move then use their power or attack.")
        lines.append("You cannot attack AND use a power in the same turn.")
        lines.append("Mojo: Flame - creates a fire tile within 4 spaces.")
        lines.append("Max: Swap - swap places with any unit within 4.")
        lines.append("      Max has a jetpack: ignores terrain, hovers over fire.")
        lines.append("Mammoth: Charge - rush up to 4 spaces pushing enemies.")
        lines.append("")
        lines.append("FIRE TILES")
        lines.append("Stepping onto fire deals 1 damage.")
        lines.append("Ending your turn on fire also deals 1 damage.")
        lines.append("")
        lines.append("BATTERIES")
        lines.append("Cyan circles heal 1 HP when stepped on.")
        lines.append("Max 3 batteries on the map at once.")
        lines.append("")
        lines.append("ENEMIES")
        lines.append("3 bugs start on the board. 3 reinforcements spawn over time.")
        lines.append("Defeat all 6 bugs to win! They attack when adjacent.")

        var y = 80
        for i in range(len(lines)):
            var line = lines[i]
            var color = COLOR_SECTION if line == "GOAL" or line == "CONTROLS" or line == "MOVEMENT" or line == "ATTACK" or line == "POWERS" or line == "FIRE TILES" or line == "BATTERIES" or line == "ENEMIES" else COLOR_TEXT
            var surf = self.font.render(line, True, color)
            self.screen.blit(surf, Python.tuple(20, y))
            y += 22

        var back_surf = self.font.render("Click to go back", True, COLOR_BACK)
        var back_rect = back_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 30))
        self.screen.blit(back_surf, back_rect)
