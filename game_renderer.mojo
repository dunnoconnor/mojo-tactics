from std.python import Python, PythonObject
from std.collections import List
from constants import GRID_SIZE, CELL_SIZE
from unit import Unit
from sprites import SpriteRenderer
from terrain import Terrain

struct GameRenderer:
    var pygame: PythonObject
    var screen: PythonObject
    var font: PythonObject

    def __init__(out self, pygame: PythonObject, screen: PythonObject, font: PythonObject):
        self.pygame = pygame
        self.screen = screen
        self.font = font

    def draw_board(mut self, terrain: Terrain, fire_tiles: List[Int], batteries: List[Int], units: List[Unit], selected_idx: Int, turn: String, game_over: Bool, power_mode: String, has_power_preview: Bool, power_preview_x: Int, power_preview_y: Int, power_preview_target_idx: Int, has_pending: Bool, pending_x: Int, pending_y: Int, move_range: List[Tuple[Int, Int]], adjacent_enemies: List[Int]) raises:
        var renderer = SpriteRenderer(self.pygame, self.screen, self.font)

        var COLOR_BG = Python.tuple(30, 30, 30)
        var COLOR_GRID_LINE = Python.tuple(80, 80, 80)
        var COLOR_MOVE_RANGE = Python.tuple(100, 200, 100)
        var COLOR_MOVE_PREVIEW = Python.tuple(150, 255, 150)
        var COLOR_ATTACK_RANGE = Python.tuple(255, 150, 100)

        self.screen.fill(COLOR_BG)
        var tick = Int(py=self.pygame.time.get_ticks()) // 100

        terrain.draw(self.pygame, self.screen, tick)
        terrain.draw_fire_tiles(self.pygame, self.screen, fire_tiles, tick)

        for i in range(len(batteries)):
            var idx = batteries[i]
            var bx = idx % GRID_SIZE
            var by = idx // GRID_SIZE
            var cx = bx * CELL_SIZE + CELL_SIZE // 2
            var cy = by * CELL_SIZE + CELL_SIZE // 2
            var pulse = (tick % 4) * 2
            self.pygame.draw.circle(self.screen, Python.tuple(0, 200, 255), Python.tuple(cx, cy), 8 + pulse, 2)
            self.pygame.draw.circle(self.screen, Python.tuple(0, 200, 255), Python.tuple(cx, cy), 4)

        if selected_idx >= 0 and turn == "player" and not game_over:
            if power_mode == "flame":
                var unit = units[selected_idx]
                for x in range(GRID_SIZE):
                    for y in range(GRID_SIZE):
                        var dist = abs(x - unit.x) + abs(y - unit.y)
                        if dist <= 4 and dist > 0:
                            var rect = self.pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                            self.pygame.draw.rect(self.screen, Python.tuple(255, 80, 0), rect)
                            self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)
            elif power_mode == "swap":
                var unit = units[selected_idx]
                for x in range(GRID_SIZE):
                    for y in range(GRID_SIZE):
                        var dist = abs(x - unit.x) + abs(y - unit.y)
                        if dist <= 4:
                            var rect = self.pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                            self.pygame.draw.rect(self.screen, Python.tuple(180, 180, 255), rect)
                            self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)
            elif power_mode == "charge":
                var unit = units[selected_idx]
                var dirs = List[Tuple[Int, Int]]()
                dirs.append((1, 0))
                dirs.append((-1, 0))
                dirs.append((0, 1))
                dirs.append((0, -1))
                for d in range(len(dirs)):
                    var nx = unit.x + dirs[d][0]
                    var ny = unit.y + dirs[d][1]
                    if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
                        var rect = self.pygame.Rect(nx * CELL_SIZE, ny * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                        self.pygame.draw.rect(self.screen, Python.tuple(200, 150, 100), rect)
                        self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

            # Power preview overlays
            if has_power_preview and power_mode == "flame":
                var rect = self.pygame.Rect(power_preview_x * CELL_SIZE, power_preview_y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                self.pygame.draw.rect(self.screen, Python.tuple(255, 220, 0), rect)
                self.pygame.draw.rect(self.screen, Python.tuple(255, 100, 0), rect, 3)
                self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

            if has_power_preview and power_mode == "swap":
                var target = units[power_preview_target_idx]
                var rect = self.pygame.Rect(target.x * CELL_SIZE, target.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                self.pygame.draw.rect(self.screen, Python.tuple(255, 255, 150), rect)
                self.pygame.draw.rect(self.screen, Python.tuple(255, 255, 100), rect, 3)
                var unit = units[selected_idx]
                var start = Python.tuple(unit.x * CELL_SIZE + CELL_SIZE // 2, unit.y * CELL_SIZE + CELL_SIZE // 2)
                var end = Python.tuple(target.x * CELL_SIZE + CELL_SIZE // 2, target.y * CELL_SIZE + CELL_SIZE // 2)
                self.pygame.draw.line(self.screen, Python.tuple(255, 255, 100), start, end, 3)

            if has_power_preview and power_mode == "charge":
                var unit = units[selected_idx]
                var dx = power_preview_x - unit.x
                var dy = power_preview_y - unit.y
                for step in range(1, 5):
                    var nx = unit.x + dx * step
                    var ny = unit.y + dy * step
                    if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
                        var rect = self.pygame.Rect(nx * CELL_SIZE, ny * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                        self.pygame.draw.rect(self.screen, Python.tuple(255, 200, 100), rect)
                        self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

            elif not has_pending and not units[selected_idx].moved:
                for i in range(len(move_range)):
                    var mx = move_range[i][0]
                    var my = move_range[i][1]
                    var rect = self.pygame.Rect(mx * CELL_SIZE, my * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    self.pygame.draw.rect(self.screen, COLOR_MOVE_RANGE, rect)
                    self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)
            elif has_pending:
                var rect = self.pygame.Rect(pending_x * CELL_SIZE, pending_y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                self.pygame.draw.rect(self.screen, COLOR_MOVE_PREVIEW, rect)
                self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

            if power_mode == "" and not units[selected_idx].attacked:
                for i in range(len(adjacent_enemies)):
                    var e = units[adjacent_enemies[i]]
                    var rect = self.pygame.Rect(e.x * CELL_SIZE, e.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    self.pygame.draw.rect(self.screen, COLOR_ATTACK_RANGE, rect)
                    self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

        for i in range(len(units)):
            var unit = units[i]
            if unit.hp <= 0 and not unit.dying:
                continue
            renderer.draw_unit(unit, i, selected_idx, unit.x, unit.y)
