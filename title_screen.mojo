from std.python import Python, PythonObject
from constants import SCREEN_WIDTH, SCREEN_HEIGHT

struct TitleScreen:
    var pygame: PythonObject
    var screen: PythonObject
    var font: PythonObject
    var big_font: PythonObject

    def __init__(out self, pygame: PythonObject, screen: PythonObject, font: PythonObject, big_font: PythonObject):
        self.pygame = pygame
        self.screen = screen
        self.font = font
        self.big_font = big_font

    def handle_click(mut self, pos: PythonObject) raises -> Int:
        var px = Int(py=pos[0])
        var py = Int(py=pos[1])
        var htp_y = SCREEN_HEIGHT // 2 + 160
        var htp_rect = self.pygame.Rect(0, htp_y - 15, SCREEN_WIDTH, 30)
        if px >= Int(py=htp_rect[0]) and px < Int(py=htp_rect[0]) + Int(py=htp_rect[2]) and py >= Int(py=htp_rect[1]) and py < Int(py=htp_rect[1]) + Int(py=htp_rect[3]):
            return 1
        return 0

    def draw(mut self, fastest_run: Int) raises:
        var COLOR_BG = Python.tuple(20, 10, 30)
        var COLOR_TITLE = Python.tuple(255, 140, 0)
        var COLOR_SUBTITLE = Python.tuple(255, 255, 255)
        var COLOR_HIGH = Python.tuple(255, 200, 50)

        self.screen.fill(COLOR_BG)

        var title_surf = self.big_font.render("Mojo Tactics", True, COLOR_TITLE)
        var title_rect = title_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 - 40))
        self.screen.blit(title_surf, title_rect)

        var flame_surf = self.big_font.render("*", True, Python.tuple(255, 255, 255))
        var flame_rect = flame_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 20))
        self.screen.blit(flame_surf, flame_rect)

        var start_surf = self.font.render("Click to Start", True, COLOR_SUBTITLE)
        var start_rect = start_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 80))
        self.screen.blit(start_surf, start_rect)

        var fastest_text = "Fastest Run: " + (String(fastest_run) + " turns" if fastest_run > 0 else "None")
        var fastest_surf = self.font.render(fastest_text, True, COLOR_HIGH)
        var fastest_rect = fastest_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 120))
        self.screen.blit(fastest_surf, fastest_rect)

        var htp_surf = self.font.render("How to Play", True, Python.tuple(180, 180, 255))
        var htp_rect = htp_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 160))
        self.screen.blit(htp_surf, htp_rect)
