from std.python import Python, PythonObject
from std.collections import List
from constants import GRID_SIZE, CELL_SIZE, GRID_WIDTH, GRID_HEIGHT, UI_WIDTH, SCREEN_WIDTH, SCREEN_HEIGHT, FPS
from unit import Unit
from sprites import SpriteRenderer
from terrain import Terrain
from ai import find_closest_player, get_live_unit_indices, get_adjacent_enemy_indices, find_best_move

def load_high_score() raises -> Int:
    try:
        var builtins = Python.import_module("builtins")
        var f = builtins.open(".highscore", "r")
        var content = f.read()
        f.close()
        return Int(py=builtins.int(content.strip()))
    except:
        return 0

struct Game:
    var pygame: PythonObject
    var screen: PythonObject
    var clock: PythonObject
    var font: PythonObject
    var big_font: PythonObject
    var units: List[Unit]
    var selected_idx: Int
    var has_pending: Bool
    var pending_x: Int
    var pending_y: Int
    var turn: String
    var message: String
    var game_over: Bool
    var winner: String
    var animating: Bool
    var terrain: Terrain
    var fire_tiles: List[Int]
    var power_mode: String
    var score: Int
    var high_score: Int

    def __init__(out self) raises:
        self.pygame = Python.import_module("pygame")
        self.pygame.init()
        self.screen = self.pygame.display.set_mode(Python.tuple(SCREEN_WIDTH, SCREEN_HEIGHT))
        self.pygame.display.set_caption("Mojo Tactics")
        self.clock = self.pygame.time.Clock()
        self.font = self.pygame.font.SysFont(PythonObject(None), 24)
        self.big_font = self.pygame.font.SysFont(PythonObject(None), 36)
        self.units = List[Unit]()
        self.selected_idx = -1
        self.has_pending = False
        self.pending_x = -1
        self.pending_y = -1
        self.turn = "player"
        self.message = "Your Turn - Select a unit"
        self.game_over = False
        self.winner = ""
        self.animating = False
        self.terrain = Terrain()
        self.fire_tiles = List[Int]()
        self.power_mode = ""
        self.score = 0
        self.high_score = load_high_score()
        self.reset_game()

    def reset_game(mut self) raises:
        self.units = List[Unit]()
        self.units.append(Unit(1, 1, "player", "Mojo"))
        self.units.append(Unit(2, 3, "player", "Max"))
        self.units.append(Unit(3, 1, "player", "Mammoth"))
        self.units.append(Unit(8, 10, "enemy"))
        self.units.append(Unit(9, 8, "enemy"))
        self.units.append(Unit(10, 10, "enemy"))
        self.selected_idx = -1
        self.has_pending = False
        self.pending_x = -1
        self.pending_y = -1
        self.turn = "player"
        self.message = "Your Turn - Select a unit"
        self.game_over = False
        self.winner = ""
        self.animating = False
        self.fire_tiles = List[Int]()
        self.power_mode = ""
        self.score = 0
        self.terrain = Terrain()

    def deal_damage(mut self, unit_idx: Int, amount: Int):
        var unit = self.units[unit_idx]
        if unit.hp <= 0 or unit.dying:
            return
        unit.hp -= amount
        if unit.hp <= 0:
            unit.hp = 0
            unit.dying = True
            unit.death_timer = 30
            if unit.team == "enemy":
                self.score += 1
        self.units[unit_idx] = unit

    def save_high_score(mut self) raises:
        if self.score > self.high_score:
            self.high_score = self.score
            try:
                var builtins = Python.import_module("builtins")
                var f = builtins.open(".highscore", "w")
                f.write(String(self.high_score))
                f.close()
            except:
                pass

    def spawn_bug(mut self) raises:
        var random = Python.import_module("random")
        var candidates = List[Int]()

        for x in range(GRID_SIZE):
            var y = GRID_SIZE - 1
            if not self.terrain.is_impassable(x, y) and not self.is_occupied(x, y):
                candidates.append(y * GRID_SIZE + x)

        for y in range(GRID_SIZE):
            var x = GRID_SIZE - 1
            if not self.terrain.is_impassable(x, y) and not self.is_occupied(x, y):
                candidates.append(y * GRID_SIZE + x)

        if len(candidates) > 0:
            var idx = Int(py=random.randint(0, len(candidates) - 1))
            var spawn_idx = candidates[idx]
            var sx = spawn_idx % GRID_SIZE
            var sy = spawn_idx // GRID_SIZE
            self.units.append(Unit(sx, sy, "enemy"))

    def get_unit_idx(self, x: Int, y: Int) -> Int:
        for i in range(len(self.units)):
            var u = self.units[i]
            if u.x == x and u.y == y and u.hp > 0 and not u.dying:
                return i
        return -1

    def get_live_units(self, team: String) -> List[Int]:
        var result = List[Int]()
        for i in range(len(self.units)):
            if self.units[i].team == team and self.units[i].hp > 0 and not self.units[i].dying:
                result.append(i)
        return result^

    def is_occupied(self, x: Int, y: Int, exclude_idx: Int = -1) -> Bool:
        if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
            return True
        if self.terrain.is_impassable(x, y):
            return True
        for i in range(len(self.units)):
            if i == exclude_idx:
                continue
            var u = self.units[i]
            if u.hp > 0 and not u.dying and u.x == x and u.y == y:
                return True
        return False

    def get_move_range(self, unit_idx: Int) -> List[Tuple[Int, Int]]:
        var unit = self.units[unit_idx]
        var reachable = List[Tuple[Int, Int]]()
        var visited = List[Int]()
        for _ in range(GRID_SIZE * GRID_SIZE):
            visited.append(99)

        var queue = List[Tuple[Int, Int]]()
        queue.append((unit.x, unit.y))

        var cost = List[Int]()
        cost.append(0)

        visited[unit.y * GRID_SIZE + unit.x] = 0

        var q_idx = 0
        while q_idx < len(queue):
            var cx = queue[q_idx][0]
            var cy = queue[q_idx][1]
            var ccost = cost[q_idx]
            q_idx += 1

            if ccost > 0:
                reachable.append((cx, cy))
            if ccost >= 4:
                continue

            var dirs = List[Tuple[Int, Int]]()
            dirs.append((1, 0))
            dirs.append((-1, 0))
            dirs.append((0, 1))
            dirs.append((0, -1))
            for i in range(len(dirs)):
                var nx = cx + dirs[i][0]
                var ny = cy + dirs[i][1]
                if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
                    var idx = ny * GRID_SIZE + nx
                    var tile_cost = self.terrain.get_terrain_cost(nx, ny)
                    var new_cost = ccost + tile_cost
                    if new_cost <= 4 and new_cost < visited[idx] and not self.is_occupied(nx, ny, exclude_idx=unit_idx):
                        visited[idx] = new_cost
                        queue.append((nx, ny))
                        cost.append(new_cost)
        return reachable^

    def get_adjacent_enemies(self, unit_idx: Int) -> List[Int]:
        var enemies = List[Int]()
        var unit = self.units[unit_idx]
        for i in range(len(self.units)):
            var other = self.units[i]
            if other.hp > 0 and not other.dying and other.team != unit.team and unit.is_adjacent(other):
                enemies.append(i)
        return enemies^

    def is_tile_on_fire(self, x: Int, y: Int) -> Bool:
        var idx = y * GRID_SIZE + x
        for i in range(len(self.fire_tiles)):
            if self.fire_tiles[i] == idx:
                return True
        return False

    def add_fire_tile(mut self, x: Int, y: Int):
        if not self.is_tile_on_fire(x, y):
            self.fire_tiles.append(y * GRID_SIZE + x)

    def apply_fire_damage(mut self, unit_idx: Int):
        var unit = self.units[unit_idx]
        if self.is_tile_on_fire(unit.x, unit.y):
            self.deal_damage(unit_idx, 1)

    def ai_turn(mut self) raises:
        self.message = "Enemy Turn..."
        self.animating = True

        for i in range(len(self.units)):
            var unit = self.units[i]
            if unit.team == "enemy" and unit.hp > 0 and not unit.dying:
                var u = self.units[i]
                u.moved = False
                u.attacked = False
                self.units[i] = u

                var closest_idx = find_closest_player(self.units, i)
                if closest_idx < 0:
                    self.check_win()
                    self.animating = False
                    return

                if not self.units[i].moved:
                    var best = find_best_move(self.units[i], self.units, self.terrain, self.fire_tiles)
                    if best >= 0:
                        var bx = best % GRID_SIZE
                        var by = best // GRID_SIZE
                        if bx != self.units[i].x or by != self.units[i].y:
                            self.units[i].x = bx
                            self.units[i].y = by
                            self.units[i].moved = True
                            self.apply_fire_damage(i)

                var adj = get_adjacent_enemy_indices(self.units, i)
                if len(adj) > 0 and not self.units[i].attacked:
                    self.deal_damage(adj[0], 1)
                    self.units[i].attacked = True

                self.apply_fire_damage(i)

                self.draw()
                self.pygame.display.flip()
                self.pygame.time.wait(300)

        self.spawn_bug()
        self.check_win()
        if not self.game_over:
            self.turn = "player"
            self.message = "Your Turn - Select a unit"
            for j in range(len(self.units)):
                if self.units[j].team == "player":
                    self.units[j].reset_turn()
        self.animating = False

    def handle_click(mut self, pos: PythonObject) raises:
        if self.animating or self.turn != "player":
            return

        var px = Int(py=pos[0])
        var py = Int(py=pos[1])
        var x = px // CELL_SIZE
        var y = py // CELL_SIZE
        if px >= GRID_WIDTH:
            self.handle_ui_click(pos)
            return

        if self.game_over:
            return

        if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
            return

        var clicked_idx = self.get_unit_idx(x, y)

        if self.power_mode != "":
            self.handle_power_click(x, y, clicked_idx)
            return

        if self.selected_idx >= 0:
            var selected_unit = self.units[self.selected_idx]

            # If viewing an enemy unit, just switch selection or deselect
            if selected_unit.team == "enemy":
                if clicked_idx >= 0:
                    self.selected_idx = clicked_idx
                    self.has_pending = False
                else:
                    self.selected_idx = -1
                    self.has_pending = False
                return

            if self.has_pending:
                if x == self.pending_x and y == self.pending_y:
                    self.confirm_move()
                return
            if clicked_idx >= 0 and self.units[clicked_idx].team == "enemy" and selected_unit.is_adjacent(self.units[clicked_idx]):
                if not selected_unit.attacked:
                    self.deal_damage(clicked_idx, 1)
                    self.units[self.selected_idx].attacked = True
                    self.selected_idx = -1
                    self.has_pending = False
                    self.check_win()
                return

            if clicked_idx < 0:
                var reachable = self.get_move_range(self.selected_idx)
                var found = False
                for i in range(len(reachable)):
                    if reachable[i][0] == x and reachable[i][1] == y and not selected_unit.moved:
                        self.pending_x = x
                        self.pending_y = y
                        self.has_pending = True
                        found = True
                        break
                if found:
                    return

            if clicked_idx >= 0:
                self.selected_idx = clicked_idx
                self.has_pending = False
                return
        else:
            if clicked_idx >= 0:
                self.selected_idx = clicked_idx
                self.has_pending = False

    def handle_power_click(mut self, x: Int, y: Int, clicked_idx: Int) raises:
        var unit = self.units[self.selected_idx]
        var dist = abs(x - unit.x) + abs(y - unit.y)

        if self.power_mode == "flame":
            if dist <= 4 and dist > 0:
                self.add_fire_tile(x, y)
                self.units[self.selected_idx].power_used = True
                self.units[self.selected_idx].moved = True
                self.units[self.selected_idx].attacked = True
                self.power_mode = ""
                self.selected_idx = -1
                self.message = "Flame thrown!"
            else:
                self.power_mode = ""
                self.message = "Invalid flame target"

        elif self.power_mode == "swap":
            if clicked_idx >= 0 and clicked_idx != self.selected_idx and dist <= 4:
                var target = self.units[clicked_idx]
                var tmp_x = unit.x
                var tmp_y = unit.y
                self.units[self.selected_idx].x = target.x
                self.units[self.selected_idx].y = target.y
                target.x = tmp_x
                target.y = tmp_y
                self.units[clicked_idx] = target
                self.units[self.selected_idx].power_used = True
                self.units[self.selected_idx].moved = True
                self.units[self.selected_idx].attacked = True
                self.power_mode = ""
                self.selected_idx = -1
                self.message = "Swap complete!"
            else:
                self.power_mode = ""
                self.message = "Invalid swap target"

        elif self.power_mode == "charge":
            var dx = x - unit.x
            var dy = y - unit.y
            if abs(dx) + abs(dy) == 1:
                self.execute_mammoth_charge(dx, dy)
            else:
                self.power_mode = ""
                self.message = "Invalid charge direction"

    def execute_mammoth_charge(mut self, dx: Int, dy: Int) raises:
        var mammoth_idx = self.selected_idx
        var mammoth = self.units[mammoth_idx]
        var mx = mammoth.x
        var my = mammoth.y
        var spaces_moved = 0
        var hit_something = False
        var hit_step = 0

        for step in range(1, 5):
            var nx = mx + dx * step
            var ny = my + dy * step
            if nx < 0 or nx >= GRID_SIZE or ny < 0 or ny >= GRID_SIZE:
                break
            if self.terrain.is_impassable(nx, ny):
                break

            var hit_unit_idx = -1
            for i in range(len(self.units)):
                if i == mammoth_idx:
                    continue
                var u = self.units[i]
                if u.hp > 0 and not u.dying and u.x == nx and u.y == ny:
                    hit_unit_idx = i
                    break

            if hit_unit_idx >= 0:
                var push_x = nx + dx
                var push_y = ny + dy
                var push_valid = True
                var blocking_unit_idx = -1

                if push_x < 0 or push_x >= GRID_SIZE or push_y < 0 or push_y >= GRID_SIZE:
                    push_valid = False
                elif self.terrain.is_impassable(push_x, push_y):
                    push_valid = False
                else:
                    for j in range(len(self.units)):
                        if j == mammoth_idx or j == hit_unit_idx:
                            continue
                        var u2 = self.units[j]
                        if u2.hp > 0 and not u2.dying and u2.x == push_x and u2.y == push_y:
                            push_valid = False
                            blocking_unit_idx = j
                            break

                if push_valid:
                    var target = self.units[hit_unit_idx]
                    target.x = push_x
                    target.y = push_y
                    self.units[hit_unit_idx] = target
                    self.units[mammoth_idx].x = nx
                    self.units[mammoth_idx].y = ny
                    spaces_moved = step
                else:
                    # Mammoth stops short — already at (nx-dx, ny-dy) from previous iterations
                    spaces_moved = step - 1
                    hit_something = True
                    hit_step = step

                self.deal_damage(hit_unit_idx, step)

                if blocking_unit_idx >= 0:
                    self.deal_damage(blocking_unit_idx, 1)

                break
            else:
                self.units[mammoth_idx].x = nx
                self.units[mammoth_idx].y = ny
                spaces_moved = step

        self.units[mammoth_idx].moved = True
        self.units[mammoth_idx].attacked = True
        self.units[mammoth_idx].power_used = True
        self.apply_fire_damage(mammoth_idx)
        self.power_mode = ""
        self.selected_idx = -1
        if hit_something:
            self.message = "Mammoth hit for " + String(hit_step) + " damage!"
        elif spaces_moved > 0:
            self.message = "Mammoth charged " + String(spaces_moved) + " spaces!"
        else:
            self.message = "Charge blocked!"
        self.check_win()

    def handle_ui_click(mut self, pos: PythonObject) raises:
        var px = Int(py=pos[0])
        var py = Int(py=pos[1])
        var buttons = self.get_button_rects()
        var labels = self.get_button_labels()
        var enabled = self.get_button_enabled()
        for i in range(len(buttons)):
            var rect = buttons[i]
            var rx = Int(py=rect[0])
            var ry = Int(py=rect[1])
            var rw = Int(py=rect[2])
            var rh = Int(py=rect[3])
            var is_enabled = enabled[i]
            if is_enabled and px >= rx and px < rx + rw and py >= ry and py < ry + rh:
                var label = labels[i]
                if label == "Confirm":
                    self.confirm_move()
                elif label == "Undo":
                    self.undo_move()
                elif label == "End Turn":
                    self.end_turn()
                elif label == "Restart":
                    self.reset_game()
                elif label == "Power":
                    self.activate_power()

    def activate_power(mut self):
        if self.selected_idx < 0:
            return
        var unit = self.units[self.selected_idx]
        if unit.power_used or unit.moved:
            return

        var unit_type = unit.unit_type
        if unit_type == "Mojo":
            self.power_mode = "flame"
            self.message = "Flame: click a tile within 4 spaces"
        elif unit_type == "Max":
            self.power_mode = "swap"
            self.message = "Swap: click a unit within 4 spaces"
        elif unit_type == "Mammoth":
            self.power_mode = "charge"
            self.message = "Charge: click an adjacent tile for direction"

    def confirm_move(mut self):
        if self.has_pending and self.selected_idx >= 0:
            self.units[self.selected_idx].x = self.pending_x
            self.units[self.selected_idx].y = self.pending_y
            self.units[self.selected_idx].moved = True
            self.has_pending = False
            self.apply_fire_damage(self.selected_idx)

    def undo_move(mut self):
        self.has_pending = False
        self.power_mode = ""

    def end_turn(mut self) raises:
        for i in range(len(self.units)):
            self.apply_fire_damage(i)
        self.check_win()

        self.selected_idx = -1
        self.has_pending = False
        self.power_mode = ""
        self.turn = "enemy"
        self.ai_turn()

    def check_win(mut self) raises:
        if len(self.get_live_units("player")) == 0:
            self.winner = "enemy"
            self.game_over = True
            self.save_high_score()

    def get_button_rects(self) raises -> List[PythonObject]:
        var buttons = List[PythonObject]()
        var bx = GRID_WIDTH + 20
        var by = 20
        var bw = UI_WIDTH - 40
        var bh = 40
        var gap = 10

        buttons.append(self.pygame.Rect(bx, by, bw, bh))
        by += bh + gap
        buttons.append(self.pygame.Rect(bx, by, bw, bh))
        by += bh + gap
        buttons.append(self.pygame.Rect(bx, by, bw, bh))
        by += bh + gap
        buttons.append(self.pygame.Rect(bx, by, bw, bh))
        by += bh + gap * 2

        if self.game_over:
            buttons.append(self.pygame.Rect(bx, by, bw, bh))
        return buttons^

    def get_button_labels(self) -> List[String]:
        var labels = List[String]()
        labels.append("Confirm")
        labels.append("Undo")
        labels.append("Power")
        labels.append("End Turn")
        if self.game_over:
            labels.append("Restart")
        return labels^

    def get_button_enabled(self) -> List[Bool]:
        var enabled = List[Bool]()
        var confirm_enabled = self.has_pending and self.turn == "player" and not self.game_over
        enabled.append(confirm_enabled)
        var undo_enabled = (self.has_pending or self.power_mode != "") and self.turn == "player" and not self.game_over
        enabled.append(undo_enabled)
        var power_enabled = False
        if self.selected_idx >= 0 and self.turn == "player" and not self.game_over:
            var unit = self.units[self.selected_idx]
            if unit.team == "player" and not unit.power_used and not unit.moved:
                power_enabled = True
        enabled.append(power_enabled)
        var end_enabled = self.turn == "player" and not self.game_over
        enabled.append(end_enabled)
        if self.game_over:
            enabled.append(True)
        return enabled^

    def draw(self) raises:
        var renderer = SpriteRenderer(self.pygame, self.screen, self.font)

        var COLOR_BG = Python.tuple(30, 30, 30)
        var COLOR_GRID = Python.tuple(50, 50, 50)
        var COLOR_GRID_LINE = Python.tuple(80, 80, 80)
        var COLOR_MOVE_RANGE = Python.tuple(100, 200, 100)
        var COLOR_MOVE_PREVIEW = Python.tuple(150, 255, 150)
        var COLOR_ATTACK_RANGE = Python.tuple(255, 150, 100)
        var COLOR_TEXT = Python.tuple(255, 255, 255)
        var COLOR_BUTTON = Python.tuple(80, 80, 120)
        var COLOR_BUTTON_HOVER = Python.tuple(100, 100, 150)
        var COLOR_BUTTON_DISABLED = Python.tuple(60, 60, 60)
        var COLOR_UI_BG = Python.tuple(20, 20, 20)

        self.screen.fill(COLOR_BG)
        var tick = Int(py=self.pygame.time.get_ticks()) // 100

        self.terrain.draw(self.pygame, self.screen, tick)
        self.terrain.draw_fire_tiles(self.pygame, self.screen, self.fire_tiles, tick)

        if self.selected_idx >= 0 and self.turn == "player" and not self.game_over:
            if self.power_mode == "flame":
                var unit = self.units[self.selected_idx]
                for x in range(GRID_SIZE):
                    for y in range(GRID_SIZE):
                        var dist = abs(x - unit.x) + abs(y - unit.y)
                        if dist <= 4 and dist > 0:
                            var rect = self.pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                            self.pygame.draw.rect(self.screen, Python.tuple(255, 80, 0), rect)
                            self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)
            elif self.power_mode == "swap":
                var unit = self.units[self.selected_idx]
                for x in range(GRID_SIZE):
                    for y in range(GRID_SIZE):
                        var dist = abs(x - unit.x) + abs(y - unit.y)
                        if dist <= 4:
                            var rect = self.pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                            self.pygame.draw.rect(self.screen, Python.tuple(180, 180, 255), rect)
                            self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)
            elif self.power_mode == "charge":
                var unit = self.units[self.selected_idx]
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
            elif not self.has_pending and not self.units[self.selected_idx].moved:
                var reachable = self.get_move_range(self.selected_idx)
                for i in range(len(reachable)):
                    var mx = reachable[i][0]
                    var my = reachable[i][1]
                    var rect = self.pygame.Rect(mx * CELL_SIZE, my * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    self.pygame.draw.rect(self.screen, COLOR_MOVE_RANGE, rect)
                    self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)
            elif self.has_pending:
                var rect = self.pygame.Rect(self.pending_x * CELL_SIZE, self.pending_y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                self.pygame.draw.rect(self.screen, COLOR_MOVE_PREVIEW, rect)
                self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

            if self.power_mode == "" and not self.units[self.selected_idx].attacked:
                var enemies = self.get_adjacent_enemies(self.selected_idx)
                for i in range(len(enemies)):
                    var e = self.units[enemies[i]]
                    var rect = self.pygame.Rect(e.x * CELL_SIZE, e.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    self.pygame.draw.rect(self.screen, COLOR_ATTACK_RANGE, rect)
                    self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

        for i in range(len(self.units)):
            var unit = self.units[i]
            if unit.hp <= 0 and not unit.dying:
                continue
            renderer.draw_unit(unit, i, self.selected_idx, unit.x, unit.y)

        var ui_rect = self.pygame.Rect(GRID_WIDTH, 0, UI_WIDTH, SCREEN_HEIGHT)
        self.pygame.draw.rect(self.screen, COLOR_UI_BG, ui_rect)

        var mouse_pos = self.pygame.mouse.get_pos()
        var mx = Int(py=mouse_pos[0])
        var my = Int(py=mouse_pos[1])
        var buttons = self.get_button_rects()
        var labels = self.get_button_labels()
        var enabled = self.get_button_enabled()
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

        var msg = self.message
        if self.game_over:
            msg = self.winner + " wins!"
        elif self.turn == "player" and self.selected_idx >= 0:
            if self.has_pending:
                msg = "Confirm or Undo move"
            elif self.power_mode != "":
                msg = self.message
            elif not self.units[self.selected_idx].moved:
                msg = "Click a tile to move or an adjacent bug to attack"
            else:
                msg = "Unit moved. Click adjacent bug to attack or End Turn"
        var msg_surf = self.font.render(msg, True, COLOR_TEXT)
        self.screen.blit(msg_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 60))

        var score_text = "Score: " + String(self.score)
        var score_surf = self.font.render(score_text, True, Python.tuple(255, 255, 100))
        self.screen.blit(score_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 90))

        var high_text = "High: " + String(self.high_score)
        var high_surf = self.font.render(high_text, True, Python.tuple(255, 200, 50))
        self.screen.blit(high_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 115))

        var instructions = List[String]()
        instructions.append("Select unit to see info")
        instructions.append("Move, Attack, Power")
        instructions.append("End Turn when done")
        var iy = 250
        for i in range(len(instructions)):
            var surf = self.font.render(instructions[i], True, Python.tuple(180, 180, 180))
            self.screen.blit(surf, Python.tuple(GRID_WIDTH + 10, iy))
            iy += 20

        if self.selected_idx >= 0 and not self.game_over:
            var sel = self.units[self.selected_idx]
            var name = sel.unit_type
            var power = ""
            if sel.team == "enemy":
                name = "Bug"
                power = "Bite: 1 dmg adjacent"
            elif sel.unit_type == "Mojo":
                power = "Flame: Fire tile within 4"
            elif sel.unit_type == "Max":
                power = "Swap places with any unit within 4"
            elif sel.unit_type == "Mammoth":
                power = "Charge: Rush up to 4 spaces"
            var info = name + "  HP:" + String(sel.hp) + "/4"
            var info_surf = self.font.render(info, True, Python.tuple(255, 255, 200))
            self.screen.blit(info_surf, Python.tuple(GRID_WIDTH + 10, 360))
            if power != "":
                var py_textwrap = Python.import_module("textwrap")
                var wrapped = py_textwrap.wrap(power, width=22)
                var ly = 390
                for i in range(len(wrapped)):
                    var line_surf = self.font.render(String(py=wrapped[i]), True, Python.tuple(255, 200, 100))
                    self.screen.blit(line_surf, Python.tuple(GRID_WIDTH + 10, ly))
                    ly += 22

    def update_death_animations(mut self):
        for i in range(len(self.units)):
            var unit = self.units[i]
            if unit.dying:
                unit.death_timer -= 1
                if unit.death_timer <= 0:
                    unit.dying = False
                    unit.hp = -1
                    unit.x = -1
                    unit.y = -1
                self.units[i] = unit

    def run(mut self) raises:
        var running = True
        while running:
            for event in self.pygame.event.get():
                if event.type == self.pygame.QUIT:
                    running = False
                elif event.type == self.pygame.MOUSEBUTTONDOWN:
                    if Int(py=event.button) == 1:
                        self.handle_click(event.pos)

            self.update_death_animations()
            self.draw()
            self.pygame.display.flip()
            self.clock.tick(FPS)

        self.pygame.quit()
