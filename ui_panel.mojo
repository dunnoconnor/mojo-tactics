from std.python import Python, PythonObject
from std.collections import List
from constants import GRID_WIDTH, UI_WIDTH, SCREEN_WIDTH, SCREEN_HEIGHT

struct UIManager:
    var pygame: PythonObject
    var screen: PythonObject
    var font: PythonObject
    var big_font: PythonObject

    def __init__(out self, pygame: PythonObject, screen: PythonObject, font: PythonObject, big_font: PythonObject):
        self.pygame = pygame
        self.screen = screen
        self.font = font
        self.big_font = big_font

    def draw_panel(mut self, buttons: List[PythonObject], labels: List[String], enabled: List[Bool], msg_line1: String, msg_line2: String, score_text: String, fastest_text: String, unit_name: String, unit_info: String, unit_power: String) raises:
        var COLOR_TEXT = Python.tuple(255, 255, 255)
        var COLOR_BUTTON = Python.tuple(80, 80, 120)
        var COLOR_BUTTON_HOVER = Python.tuple(100, 100, 150)
        var COLOR_BUTTON_DISABLED = Python.tuple(60, 60, 60)
        var COLOR_UI_BG = Python.tuple(20, 20, 20)

        var ui_rect = self.pygame.Rect(GRID_WIDTH, 0, UI_WIDTH, SCREEN_HEIGHT)
        self.pygame.draw.rect(self.screen, COLOR_UI_BG, ui_rect)

        var mouse_pos = self.pygame.mouse.get_pos()
        var mx = Int(py=mouse_pos[0])
        var my = Int(py=mouse_pos[1])

        for i in range(len(buttons)):
            var rect = buttons[i]
            var rx = Int(py=rect[0])
            var ry = Int(py=rect[1])
            var rw = Int(py=rect[2])
            var rh = Int(py=rect[3])
            var label = labels[i]
            var is_enabled = enabled[i]
            var is_hover = is_enabled and mx >= rx and mx < rx + rw and my >= ry and my < ry + rh
            var btn_color = COLOR_BUTTON_HOVER if is_hover else (COLOR_BUTTON if is_enabled else COLOR_BUTTON_DISABLED)
            self.pygame.draw.rect(self.screen, btn_color, rect, border_radius=4)
            var text_surf = self.font.render(label, True, COLOR_TEXT)
            var center = Python.tuple(rx + rw // 2, ry + rh // 2)
            var text_rect = text_surf.get_rect(center=center)
            self.screen.blit(text_surf, text_rect)

        var msg_surf = self.font.render(msg_line1, True, COLOR_TEXT)
        self.screen.blit(msg_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 60))
        if msg_line2 != "":
            var msg2_surf = self.font.render(msg_line2, True, Python.tuple(200, 200, 200))
            self.screen.blit(msg2_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 36))

        var score_surf = self.font.render(score_text, True, Python.tuple(255, 255, 100))
        self.screen.blit(score_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 90))

        if fastest_text != "":
            var fastest_surf = self.font.render(fastest_text, True, Python.tuple(255, 200, 50))
            self.screen.blit(fastest_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 115))

        if unit_name != "":
            var info_surf = self.font.render(unit_info, True, Python.tuple(255, 255, 200))
            self.screen.blit(info_surf, Python.tuple(GRID_WIDTH + 10, 360))
            if unit_power != "":
                var py_textwrap = Python.import_module("textwrap")
                var wrapped = py_textwrap.wrap(unit_power, width=22)
                var ly = 390
                for i in range(len(wrapped)):
                    var line_surf = self.font.render(String(py=wrapped[i]), True, Python.tuple(255, 200, 100))
                    self.screen.blit(line_surf, Python.tuple(GRID_WIDTH + 10, ly))
                    ly += 22
