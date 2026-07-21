from std.python import Python, PythonObject
from constants import CELL_SIZE
from unit import Unit

struct SpriteRenderer:
    var pygame: PythonObject
    var screen: PythonObject
    var font: PythonObject

    def __init__(out self, pygame: PythonObject, screen: PythonObject, font: PythonObject):
        self.pygame = pygame
        self.screen = screen
        self.font = font

    def _color(self, r: Int, g: Int, b: Int) raises -> PythonObject:
        return Python.tuple(r, g, b)

    def _draw_pixel(self, cx: Int, cy: Int, r: Int, g: Int, b: Int, sx: Int, sy: Int, scale: Int = 3) raises:
        var pixel_rect = self.pygame.Rect(sx + cx * scale, sy + cy * scale, scale, scale)
        self.pygame.draw.rect(self.screen, self._color(r, g, b), pixel_rect)

    def draw_mojo(self, sx: Int, sy: Int, dim: Bool) raises:
        var s = 3
        var r = 255 if not dim else 150
        var o = 100 if not dim else 60
        self._draw_pixel(5, 0, r, o, 0, sx, sy, s)
        self._draw_pixel(6, 0, r, o, 0, sx, sy, s)
        self._draw_pixel(4, 1, r, 40, 0, sx, sy, s)
        self._draw_pixel(5, 1, r, o, 0, sx, sy, s)
        self._draw_pixel(6, 1, r, o, 0, sx, sy, s)
        self._draw_pixel(7, 1, r, 40, 0, sx, sy, s)
        for j in range(2, 5):
            for i in range(3, 9):
                self._draw_pixel(i, j, r, 140, 0, sx, sy, s)
        self._draw_pixel(4, 2, 255, 230, 0, sx, sy, s)
        self._draw_pixel(5, 2, 255, 230, 0, sx, sy, s)
        self._draw_pixel(6, 2, 255, 230, 0, sx, sy, s)
        self._draw_pixel(7, 2, 255, 230, 0, sx, sy, s)
        self._draw_pixel(4, 3, 255, 230, 0, sx, sy, s)
        self._draw_pixel(5, 3, 255, 240, 80, sx, sy, s)
        self._draw_pixel(6, 3, 255, 240, 80, sx, sy, s)
        self._draw_pixel(7, 3, 255, 230, 0, sx, sy, s)
        self._draw_pixel(5, 4, 255, 230, 0, sx, sy, s)
        self._draw_pixel(6, 4, 255, 230, 0, sx, sy, s)
        for j in range(5, 8):
            for i in range(4, 8):
                self._draw_pixel(i, j, r, 110, 0, sx, sy, s)
        self._draw_pixel(5, 5, 255, 210, 0, sx, sy, s)
        self._draw_pixel(6, 5, 255, 210, 0, sx, sy, s)
        self._draw_pixel(5, 6, 255, 200, 0, sx, sy, s)
        for j in range(8, 11):
            for i in range(5, 7):
                self._draw_pixel(i, j, r, 80, 0, sx, sy, s)
        self._draw_pixel(5, 10, 255, 60, 0, sx, sy, s)
        self._draw_pixel(6, 10, 255, 60, 0, sx, sy, s)

    def draw_max(self, sx: Int, sy: Int, dim: Bool) raises:
        var s = 3
        var w = 240 if not dim else 140
        var g = 180 if not dim else 100
        var b = 200 if not dim else 120
        for j in range(1, 5):
            for i in range(3, 9):
                self._draw_pixel(i, j, w, w, w, sx, sy, s)
        for j in range(2, 4):
            for i in range(4, 8):
                self._draw_pixel(i, j, 30, 60, 120, sx, sy, s)
        self._draw_pixel(5, 2, 80, 120, 200, sx, sy, s)
        self._draw_pixel(6, 2, 80, 120, 200, sx, sy, s)
        for j in range(5, 10):
            for i in range(3, 9):
                self._draw_pixel(i, j, w, w, w, sx, sy, s)
        for j in range(5, 9):
            self._draw_pixel(2, j, g, g, b, sx, sy, s)
            self._draw_pixel(8, j, g, g, b, sx, sy, s)
        self._draw_pixel(5, 6, 60, 80, 180, sx, sy, s)
        self._draw_pixel(6, 6, 60, 80, 180, sx, sy, s)
        self._draw_pixel(5, 7, 60, 80, 180, sx, sy, s)
        self._draw_pixel(6, 7, 60, 80, 180, sx, sy, s)
        for i in range(3, 9):
            self._draw_pixel(i, 9, g, g, b, sx, sy, s)
        for j in range(10, 12):
            for i in range(4, 6):
                self._draw_pixel(i, j, w, w, w, sx, sy, s)
            for i in range(6, 8):
                self._draw_pixel(i, j, w, w, w, sx, sy, s)

    def draw_mammoth(self, sx: Int, sy: Int, dim: Bool) raises:
        var s = 3
        var br = 160 if not dim else 90
        var dr = 100 if not dim else 50
        var w = 240
        for j in range(3, 9):
            for i in range(4, 10):
                self._draw_pixel(i, j, br, 100, 60, sx, sy, s)
        for j in range(3, 7):
            for i in range(2, 5):
                self._draw_pixel(i, j, br, 100, 60, sx, sy, s)
        self._draw_pixel(3, 4, 255, 255, 255, sx, sy, s)
        for j in range(5, 8):
            self._draw_pixel(1, j, w, w, w, sx, sy, s)
            self._draw_pixel(2, j, w, w, w, sx, sy, s)
        self._draw_pixel(2, 8, w, w, w, sx, sy, s)
        self._draw_pixel(3, 8, w, w, w, sx, sy, s)
        for j in range(6, 10):
            self._draw_pixel(3, j, br, 80, 40, sx, sy, s)
            self._draw_pixel(4, j, br, 80, 40, sx, sy, s)
        for j in range(9, 12):
            self._draw_pixel(4, j, dr, 60, 30, sx, sy, s)
            self._draw_pixel(5, j, dr, 60, 30, sx, sy, s)
            self._draw_pixel(6, j, dr, 60, 30, sx, sy, s)
            self._draw_pixel(7, j, dr, 60, 30, sx, sy, s)
            self._draw_pixel(8, j, dr, 60, 30, sx, sy, s)
            self._draw_pixel(9, j, dr, 60, 30, sx, sy, s)
        self._draw_pixel(5, 3, dr, 60, 30, sx, sy, s)

    def draw_enemy(self, sx: Int, sy: Int, dim: Bool) raises:
        var s = 3
        var r = 255 if not dim else 150
        var dr = 150 if not dim else 80
        for j in range(2, 10):
            for i in range(3, 9):
                self._draw_pixel(i, j, dr, 30, 30, sx, sy, s)
        self._draw_pixel(3, 2, r, 50, 50, sx, sy, s)
        self._draw_pixel(8, 2, r, 50, 50, sx, sy, s)
        self._draw_pixel(4, 4, 255, 255, 255, sx, sy, s)
        self._draw_pixel(5, 4, 255, 255, 255, sx, sy, s)
        self._draw_pixel(6, 4, 255, 255, 255, sx, sy, s)
        self._draw_pixel(7, 4, 255, 255, 255, sx, sy, s)
        self._draw_pixel(5, 4, 0, 0, 0, sx, sy, s)
        self._draw_pixel(6, 4, 0, 0, 0, sx, sy, s)
        for j in range(6, 8):
            for i in range(4, 8):
                self._draw_pixel(i, j, 100, 20, 20, sx, sy, s)
        self._draw_pixel(4, 6, 255, 255, 255, sx, sy, s)
        self._draw_pixel(7, 6, 255, 255, 255, sx, sy, s)
        for j in range(7, 10):
            self._draw_pixel(2, j, dr, 30, 30, sx, sy, s)
            self._draw_pixel(9, j, dr, 30, 30, sx, sy, s)
        self._draw_pixel(2, 9, r, 50, 50, sx, sy, s)
        self._draw_pixel(9, 9, r, 50, 50, sx, sy, s)

    def draw_unit(self, unit: Unit, idx: Int, selected_idx: Int, x: Int, y: Int) raises:
        var margin = 8
        var rect = self.pygame.Rect(x * CELL_SIZE + margin, y * CELL_SIZE + margin, CELL_SIZE - margin * 2, CELL_SIZE - margin * 2)
        var sprite_x = x * CELL_SIZE + 7
        var sprite_y = y * CELL_SIZE + 7

        if unit.dying:
            var flash = unit.death_timer % 6 < 3
            var death_color = self._color(255, 50, 50) if flash else self._color(30, 0, 0)
            self.pygame.draw.rect(self.screen, death_color, rect, border_radius=6)
            var skull = self.font.render("X", True, self._color(255, 255, 255))
            var skull_rect = skull.get_rect(center=Python.tuple(x * CELL_SIZE + CELL_SIZE // 2, y * CELL_SIZE + CELL_SIZE // 2))
            self.screen.blit(skull, skull_rect)
        else:
            var dim = (unit.team == "player" and unit.moved) or (unit.team == "enemy" and unit.moved)
            if unit.team == "player":
                if unit.unit_type == "Mojo":
                    self.draw_mojo(sprite_x, sprite_y, dim)
                elif unit.unit_type == "Max":
                    self.draw_max(sprite_x, sprite_y, dim)
                elif unit.unit_type == "Mammoth":
                    self.draw_mammoth(sprite_x, sprite_y, dim)
            else:
                self.draw_enemy(sprite_x, sprite_y, dim)

            if idx == selected_idx:
                self.pygame.draw.rect(self.screen, self._color(255, 255, 100), rect, 3, border_radius=6)

            var sq_size = 8
            var sq_gap = 2
            var total_w = 4 * sq_size + 3 * sq_gap
            var start_x = x * CELL_SIZE + (CELL_SIZE - total_w) // 2
            var start_y = y * CELL_SIZE + CELL_SIZE - 14
            for h in range(4):
                var sq_color = self._color(0, 200, 0) if h < unit.hp else self._color(0, 0, 0)
                var sq_rect = self.pygame.Rect(start_x + h * (sq_size + sq_gap), start_y, sq_size, sq_size)
                self.pygame.draw.rect(self.screen, sq_color, sq_rect)
                self.pygame.draw.rect(self.screen, self._color(40, 40, 40), sq_rect, 1)
