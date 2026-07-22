from std.python import Python, PythonObject
from std.collections import List
from constants import GRID_SIZE, CELL_SIZE, GRID_WIDTH, GRID_HEIGHT, UI_WIDTH, SCREEN_WIDTH, SCREEN_HEIGHT, FPS
from unit import Unit
from sprites import SpriteRenderer
from terrain import Terrain
from ai import find_closest_player, get_live_unit_indices, get_adjacent_enemy_indices, find_best_move, find_path_to

def load_fastest_run() raises -> Int:
    try:
        var builtins = Python.import_module("builtins")
        var f = builtins.open(".fastest", "r")
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
    var turn_count: Int
    var fastest_run: Int
    var title_screen: Bool
    var batteries: List[Int]
    var how_to_play: Bool
    var enemies_spawned: Int
    var max_enemies: Int

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
        self.turn_count = 1
        self.fastest_run = load_fastest_run()
        self.title_screen = True
        self.batteries = List[Int]()
        self.how_to_play = False
        self.enemies_spawned = 0
        self.max_enemies = 6
        self.reset_game()

    def reset_game(mut self) raises:
        self.units = List[Unit]()
        self.units.append(Unit(1, 1, "player", "Mojo"))
        self.units.append(Unit(2, 3, "player", "Max"))
        self.units.append(Unit(3, 1, "player", "Mammoth"))
        self.units.append(Unit(8, 10, "enemy"))
        self.units.append(Unit(9, 8, "enemy"))
        self.units.append(Unit(10, 10, "enemy"))
        self.enemies_spawned = 3
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
        self.turn_count = 1
        self.terrain = Terrain()
        self.batteries = List[Int]()
        self.spawn_battery()

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

    def save_fastest_run(mut self) raises:
        if self.winner == "player":
            if self.fastest_run == 0 or self.turn_count < self.fastest_run:
                self.fastest_run = self.turn_count
                try:
                    var builtins = Python.import_module("builtins")
                    var f = builtins.open(".fastest", "w")
                    f.write(String(self.fastest_run))
                    f.close()
                except:
                    pass

    def spawn_bug(mut self) raises:
        if self.enemies_spawned >= self.max_enemies:
            return
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
            self.enemies_spawned += 1

    def spawn_battery(mut self) raises:
        if len(self.batteries) >= 3:
            return
        var random = Python.import_module("random")
        var candidates = List[Int]()
        for i in range(GRID_SIZE * GRID_SIZE):
            var x = i % GRID_SIZE
            var y = i // GRID_SIZE
            if not self.terrain.is_impassable(x, y) and not self.is_occupied(x, y):
                var has_battery = False
                for j in range(len(self.batteries)):
                    if self.batteries[j] == i:
                        has_battery = True
                        break
                if not has_battery:
                    candidates.append(i)
        if len(candidates) > 0:
            var idx = Int(py=random.randint(0, len(candidates) - 1))
            self.batteries.append(candidates[idx])

    def consume_battery(mut self, unit_idx: Int):
        var unit = self.units[unit_idx]
        var tile_idx = unit.y * GRID_SIZE + unit.x
        for i in range(len(self.batteries)):
            if self.batteries[i] == tile_idx:
                if unit.hp > 0 and not unit.dying and unit.hp < unit.max_hp:
                    unit.hp += 1
                self.units[unit_idx] = unit
                _ = self.batteries.pop(i)
                break

    def animate_move(mut self, unit_idx: Int, path: List[Tuple[Int, Int]]) raises:
        for i in range(1, len(path)):
            self.units[unit_idx].x = path[i][0]
            self.units[unit_idx].y = path[i][1]
            self.draw()
            self.pygame.display.flip()
            self.pygame.time.wait(150)

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

    def is_occupied(self, x: Int, y: Int, exclude_idx: Int = -1, jetpack: Bool = False) -> Bool:
        if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
            return True
        if not jetpack and self.terrain.is_impassable(x, y):
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
                    var tile_cost = 1 if unit.jetpack else self.terrain.get_terrain_cost(nx, ny)
                    var new_cost = ccost + tile_cost
                    if new_cost <= 4 and new_cost < visited[idx] and not self.is_occupied(nx, ny, exclude_idx=unit_idx, jetpack=unit.jetpack):
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
        if not unit.jetpack and self.is_tile_on_fire(unit.x, unit.y):
            self.deal_damage(unit_idx, 1)

    def ai_turn(mut self) raises:
        self.message = "Enemy Turn..."
        self.animating = True

        var player_indices = get_live_unit_indices(self.units, "player")
        if len(player_indices) == 0:
            self.check_win()
            self.animating = False
            return

        for i in range(len(self.units)):
            var unit = self.units[i]
            if unit.team == "enemy" and unit.hp > 0 and not unit.dying:
                var u = self.units[i]
                u.moved = False
                u.attacked = False
                self.units[i] = u

                var closest_idx = find_closest_player(self.units, i, player_indices)
                if closest_idx < 0:
                    self.check_win()
                    self.animating = False
                    return

                if not self.units[i].moved:
                    var best = find_best_move(self.units[i], self.units, self.terrain, self.fire_tiles, self.units[i].jetpack)
                    if best >= 0:
                        var bx = best % GRID_SIZE
                        var by = best // GRID_SIZE
                        if bx != self.units[i].x or by != self.units[i].y:
                            var path = find_path_to(self.units[i], bx, by, self.terrain, self.units, i, self.units[i].jetpack)
                            if len(path) > 0:
                                self.animate_move(i, path)
                            self.units[i].moved = True
                            self.consume_battery(i)
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
        self.spawn_battery()
        self.check_win()
        if not self.game_over:
            self.turn = "player"
            self.turn_count += 1
            self.message = "Your Turn - Select a unit"
            for j in range(len(self.units)):
                if self.units[j].team == "player":
                    self.units[j].reset_turn()
        self.animating = False

    def handle_click(mut self, pos: PythonObject) raises:
        if self.animating:
            return

        var px = Int(py=pos[0])
        var py = Int(py=pos[1])

        if px >= GRID_WIDTH:
            self.handle_ui_click(pos)
            return

        if self.turn != "player" or self.game_over:
            return

        var x = px // CELL_SIZE
        var y = py // CELL_SIZE

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
                if not selected_unit.attacked and not selected_unit.power_used:
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
                self.consume_battery(self.selected_idx)
                self.consume_battery(clicked_idx)
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
        self.units[mammoth_idx].power_used = True
        self.consume_battery(mammoth_idx)
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
                elif label == "How to Play":
                    self.how_to_play = True

    def activate_power(mut self):
        if self.selected_idx < 0:
            return
        var unit = self.units[self.selected_idx]
        if unit.power_used or unit.attacked:
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

    def confirm_move(mut self) raises:
        if self.has_pending and self.selected_idx >= 0:
            var path = find_path_to(self.units[self.selected_idx], self.pending_x, self.pending_y, self.terrain, self.units, self.selected_idx, self.units[self.selected_idx].jetpack)
            if len(path) > 0:
                self.animate_move(self.selected_idx, path)
            self.units[self.selected_idx].moved = True
            self.has_pending = False
            self.consume_battery(self.selected_idx)
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
        elif self.enemies_spawned >= self.max_enemies and len(self.get_live_units("enemy")) == 0:
            self.winner = "player"
            self.game_over = True
            self.save_fastest_run()

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
        by += bh + gap * 2
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
        labels.append("How to Play")
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
            if unit.team == "player" and not unit.power_used and not unit.attacked:
                power_enabled = True
        enabled.append(power_enabled)
        var end_enabled = self.turn == "player" and not self.game_over
        enabled.append(end_enabled)
        if self.game_over:
            enabled.append(True)
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

        for i in range(len(self.batteries)):
            var idx = self.batteries[i]
            var bx = idx % GRID_SIZE
            var by = idx // GRID_SIZE
            var cx = bx * CELL_SIZE + CELL_SIZE // 2
            var cy = by * CELL_SIZE + CELL_SIZE // 2
            var pulse = (tick % 4) * 2
            self.pygame.draw.circle(self.screen, Python.tuple(0, 200, 255), Python.tuple(cx, cy), 8 + pulse, 2)
            self.pygame.draw.circle(self.screen, Python.tuple(0, 200, 255), Python.tuple(cx, cy), 4)

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

        var msg_line1 = self.message
        var msg_line2 = ""
        if self.game_over:
            msg_line1 = self.winner + " wins!"
        elif self.turn == "player" and self.selected_idx >= 0:
            if self.has_pending:
                msg_line1 = "Confirm or Undo move"
            elif self.power_mode != "":
                msg_line1 = self.message
            elif not self.units[self.selected_idx].moved:
                msg_line1 = "Click a tile to move"
                msg_line2 = "or adj. bug to attack"
            elif not self.units[self.selected_idx].attacked and not self.units[self.selected_idx].power_used:
                msg_line1 = "Click adj. bug to attack"
                msg_line2 = "or use Power"
            else:
                msg_line1 = "Click adj. bug to attack"
                msg_line2 = "or press End Turn"
        var msg_surf = self.font.render(msg_line1, True, COLOR_TEXT)
        self.screen.blit(msg_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 60))
        if msg_line2 != "":
            var msg2_surf = self.font.render(msg_line2, True, Python.tuple(200, 200, 200))
            self.screen.blit(msg2_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 36))

        var score_text = "Score: " + String(self.score)
        var score_surf = self.font.render(score_text, True, Python.tuple(255, 255, 100))
        self.screen.blit(score_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 90))

        var fastest_text = "Fastest: " + (String(self.fastest_run) + " turns" if self.fastest_run > 0 else "None")
        var fastest_surf = self.font.render(fastest_text, True, Python.tuple(255, 200, 50))
        self.screen.blit(fastest_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 115))

        if self.selected_idx >= 0 and not self.game_over:
            var sel = self.units[self.selected_idx]
            var name = sel.unit_type
            var power = ""
            if sel.team == "enemy":
                name = "Bug"
                power = "Bite: 1 dmg adjacent"
            elif sel.unit_type == "Mojo":
                power = "Flame: creates a fire tile within 4"
            elif sel.unit_type == "Max":
                power = "Jetpack: ignores terrain & fire. Swap within 4."
            elif sel.unit_type == "Mammoth":
                power = "Charge: rush up to 4 spaces"
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

    def draw_title(mut self) raises:
        var COLOR_BG = Python.tuple(20, 10, 30)
        var COLOR_TITLE = Python.tuple(255, 140, 0)
        var COLOR_SUBTITLE = Python.tuple(255, 255, 255)
        var COLOR_HIGH = Python.tuple(255, 200, 50)

        self.screen.fill(COLOR_BG)

        var title_surf = self.big_font.render("Mojo Tactics", True, COLOR_TITLE)
        var title_rect = title_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 - 40))
        self.screen.blit(title_surf, title_rect)

        var flame_surf = self.big_font.render("🔥", True, Python.tuple(255, 255, 255))
        var flame_rect = flame_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 20))
        self.screen.blit(flame_surf, flame_rect)

        var start_surf = self.font.render("Click to Start", True, COLOR_SUBTITLE)
        var start_rect = start_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 80))
        self.screen.blit(start_surf, start_rect)

        var fastest_text = "Fastest Run: " + (String(self.fastest_run) + " turns" if self.fastest_run > 0 else "None")
        var fastest_surf = self.font.render(fastest_text, True, COLOR_HIGH)
        var fastest_rect = fastest_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 120))
        self.screen.blit(fastest_surf, fastest_rect)

        var htp_surf = self.font.render("How to Play", True, Python.tuple(180, 180, 255))
        var htp_rect = htp_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 160))
        self.screen.blit(htp_surf, htp_rect)

    def draw_how_to_play(mut self) raises:
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

    def run(mut self) raises:
        var running = True
        while running:
            for event in self.pygame.event.get():
                if event.type == self.pygame.QUIT:
                    running = False
                elif event.type == self.pygame.MOUSEBUTTONDOWN:
                    if Int(py=event.button) == 1:
                        if self.how_to_play:
                            self.how_to_play = False
                        elif self.title_screen:
                            var pos = event.pos
                            var px = Int(py=pos[0])
                            var py = Int(py=pos[1])
                            var htp_y = SCREEN_HEIGHT // 2 + 160
                            var htp_rect = self.pygame.Rect(0, htp_y - 15, SCREEN_WIDTH, 30)
                            if px >= Int(py=htp_rect[0]) and px < Int(py=htp_rect[0]) + Int(py=htp_rect[2]) and py >= Int(py=htp_rect[1]) and py < Int(py=htp_rect[1]) + Int(py=htp_rect[3]):
                                self.how_to_play = True
                            else:
                                self.title_screen = False
                        else:
                            self.handle_click(event.pos)
                    elif Int(py=event.button) == 3:
                        if not self.title_screen and not self.how_to_play and self.turn == "player" and self.selected_idx >= 0:
                            self.selected_idx = -1
                            self.has_pending = False
                            self.power_mode = ""

            if self.how_to_play:
                self.draw_how_to_play()
            elif self.title_screen:
                self.draw_title()
            else:
                self.update_death_animations()
                self.draw()

            self.pygame.display.flip()
            self.clock.tick(FPS)

        self.pygame.quit()
