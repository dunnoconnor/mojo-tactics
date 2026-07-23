from std.python import Python, PythonObject
from constants import SCREEN_WIDTH, SCREEN_HEIGHT

struct VictoryScreen:
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
        self.screen.fill(COLOR_BG)

        var title_surf = self.big_font.render("Victory!", True, Python.tuple(255, 200, 0))
        var title_rect = title_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 - 60))
        self.screen.blit(title_surf, title_rect)

        var sub_surf = self.font.render("All missions completed. The island is safe!", True, Python.tuple(255, 255, 255))
        var sub_rect = sub_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2))
        self.screen.blit(sub_surf, sub_rect)

        var back_surf = self.font.render("Click to return to title", True, Python.tuple(180, 180, 255))
        var back_rect = back_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 50))
        self.screen.blit(back_surf, back_rect)
