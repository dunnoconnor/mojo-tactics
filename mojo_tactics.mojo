from std.python import Python, PythonObject
from std.collections import List

# Constants
comptime GRID_SIZE = 12
comptime CELL_SIZE = 50
comptime GRID_WIDTH = GRID_SIZE * CELL_SIZE
comptime GRID_HEIGHT = GRID_SIZE * CELL_SIZE
comptime UI_WIDTH = 200
comptime SCREEN_WIDTH = GRID_WIDTH + UI_WIDTH
comptime SCREEN_HEIGHT = GRID_HEIGHT
comptime FPS = 60


struct Unit(ImplicitlyCopyable, Movable):
    var x: Int
    var y: Int
    var team: String
    var unit_type: String
    var hp: Int
    var max_hp: Int
    var moved: Bool
    var attacked: Bool
    var power_used: Bool
    var dying: Bool
    var death_timer: Int

    def __init__(out self, x: Int, y: Int, team: String, unit_type: String = "enemy"):
        self.x = x
        self.y = y
        self.team = team
        self.unit_type = unit_type
        self.hp = 4
        self.max_hp = 4
        self.moved = False
        self.attacked = False
        self.power_used = False
        self.dying = False
        self.death_timer = 0

    def is_adjacent(self, other: Unit) -> Bool:
        return abs(self.x - other.x) + abs(self.y - other.y) == 1

    def reset_turn(mut self):
        self.moved = False
        self.attacked = False
        self.power_used = False


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
    var terrain: List[Int]
    var fire_tiles: List[Int]
    var power_mode: String

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
        self.terrain = List[Int]()
        self.fire_tiles = List[Int]()
        self.power_mode = ""
        self.init_terrain()
        self.reset_game()

    def reset_game(mut self):
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
        self.init_terrain()

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
        if self.terrain[y * GRID_SIZE + x] == 2:
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
                    var tile_cost = self.get_terrain_cost(nx, ny)
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
        if self.is_tile_on_fire(unit.x, unit.y) and unit.hp > 0 and not unit.dying:
            unit.hp -= 1
            if unit.hp <= 0:
                unit.hp = 0
                unit.dying = True
                unit.death_timer = 30
            self.units[unit_idx] = unit

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

                var players = self.get_live_units("player")
                if len(players) == 0:
                    self.winner = "enemy"
                    self.game_over = True
                    return

                var closest_idx = players[0]
                var closest_dist = abs(self.units[closest_idx].x - unit.x) + abs(self.units[closest_idx].y - unit.y)
                for j in range(1, len(players)):
                    var p = self.units[players[j]]
                    var d = abs(p.x - unit.x) + abs(p.y - unit.y)
                    if d < closest_dist:
                        closest_dist = d
                        closest_idx = players[j]

                if not self.units[i].moved:
                    var path = self.find_path_toward(i, closest_idx)
                    if len(path) > 1:
                        var total_cost = 0
                        var steps = 0
                        for s in range(1, len(path)):
                            var tile_cost = self.get_terrain_cost(path[s][0], path[s][1])
                            if total_cost + tile_cost > 4:
                                break
                            total_cost += tile_cost
                            steps = s
                        if steps > 0:
                            var dest = path[steps]
                            if not self.is_occupied(dest[0], dest[1], exclude_idx=i):
                                self.units[i].x = dest[0]
                                self.units[i].y = dest[1]
                                self.units[i].moved = True
                                self.apply_fire_damage(i)

                var adj = self.get_adjacent_enemies(i)
                if len(adj) > 0 and not self.units[i].attacked:
                    var target = self.units[adj[0]]
                    target.hp -= 1
                    self.units[i].attacked = True
                    if target.hp <= 0:
                        target.hp = 0
                        target.dying = True
                        target.death_timer = 30
                    self.units[adj[0]] = target

                # End of enemy unit's action: apply fire damage if on fire
                self.apply_fire_damage(i)

                self.draw()
                self.pygame.display.flip()
                self.pygame.time.wait(300)

        if len(self.get_live_units("player")) == 0:
            self.winner = "enemy"
            self.game_over = True
        else:
            self.turn = "player"
            self.message = "Your Turn - Select a unit"
            for j in range(len(self.units)):
                if self.units[j].team == "player":
                    self.units[j].reset_turn()
        self.animating = False

    def find_path_toward(self, unit_idx: Int, target_idx: Int) -> List[Tuple[Int, Int]]:
        var unit = self.units[unit_idx]
        var target = self.units[target_idx]
        var start = (unit.x, unit.y)
        var goal = (target.x, target.y)

        var queue = List[Tuple[Int, Int]]()
        queue.append(start)

        var parent = List[Tuple[Int, Int]]()
        var visited = List[Bool]()
        var cost = List[Int]()
        for _ in range(GRID_SIZE * GRID_SIZE):
            parent.append((-1, -1))
            visited.append(False)
            cost.append(99)

        visited[start[1] * GRID_SIZE + start[0]] = True
        cost[start[1] * GRID_SIZE + start[0]] = 0

        var q_idx = 0
        while q_idx < len(queue):
            var current = queue[q_idx]
            q_idx += 1
            if current[0] == goal[0] and current[1] == goal[1]:
                break

            var dirs = List[Tuple[Int, Int]]()
            dirs.append((1, 0))
            dirs.append((-1, 0))
            dirs.append((0, 1))
            dirs.append((0, -1))
            for d in range(len(dirs)):
                var nx = current[0] + dirs[d][0]
                var ny = current[1] + dirs[d][1]
                if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
                    var idx = ny * GRID_SIZE + nx
                    var tile_cost = self.get_terrain_cost(nx, ny)
                    var new_cost = cost[current[1] * GRID_SIZE + current[0]] + tile_cost
                    if not visited[idx]:
                        if (nx == goal[0] and ny == goal[1]) or not self.is_occupied(nx, ny, exclude_idx=unit_idx):
                            if new_cost <= 4:
                                visited[idx] = True
                                cost[idx] = new_cost
                                parent[idx] = current
                                queue.append((nx, ny))

        if not visited[goal[1] * GRID_SIZE + goal[0]]:
            var best_dist = 999999
            var best = (-1, -1)
            for x in range(GRID_SIZE):
                for y in range(GRID_SIZE):
                    var idx = y * GRID_SIZE + x
                    if visited[idx]:
                        var dist = abs(x - goal[0]) + abs(y - goal[1])
                        if dist < best_dist:
                            best_dist = dist
                            best = (x, y)
            if best[0] == -1:
                return List[Tuple[Int, Int]]()
            goal = best

        var path = List[Tuple[Int, Int]]()
        var cur = goal
        while cur[0] != -1:
            path.append(cur)
            var idx = cur[1] * GRID_SIZE + cur[0]
            cur = parent[idx]

        var reversed_path = List[Tuple[Int, Int]]()
        for i in range(len(path)):
            reversed_path.append(path[len(path) - 1 - i])
        return reversed_path^

    def handle_click(mut self, pos: PythonObject) raises:
        if self.game_over or self.animating or self.turn != "player":
            return

        var px = Int(py=pos[0])
        var py = Int(py=pos[1])
        var x = px // CELL_SIZE
        var y = py // CELL_SIZE
        if px >= GRID_WIDTH:
            self.handle_ui_click(pos)
            return

        if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
            return

        var clicked_idx = self.get_unit_idx(x, y)

        # Handle power mode clicks
        if self.power_mode != "":
            self.handle_power_click(x, y, clicked_idx)
            return

        if self.selected_idx >= 0:
            if self.has_pending:
                if x == self.pending_x and y == self.pending_y:
                    self.confirm_move()
                return
            if clicked_idx >= 0 and self.units[clicked_idx].team == "enemy" and self.units[self.selected_idx].is_adjacent(self.units[clicked_idx]):
                if not self.units[self.selected_idx].attacked:
                    var target = self.units[clicked_idx]
                    target.hp -= 1
                    self.units[self.selected_idx].attacked = True
                    if target.hp <= 0:
                        target.hp = 0
                        target.dying = True
                        target.death_timer = 30
                    self.units[clicked_idx] = target
                    self.selected_idx = -1
                    self.has_pending = False
                    self.check_win()
                return

            if clicked_idx < 0:
                var reachable = self.get_move_range(self.selected_idx)
                var found = False
                for i in range(len(reachable)):
                    if reachable[i][0] == x and reachable[i][1] == y and not self.units[self.selected_idx].moved:
                        self.pending_x = x
                        self.pending_y = y
                        self.has_pending = True
                        found = True
                        break
                if found:
                    return

            if clicked_idx >= 0 and self.units[clicked_idx].team == "player":
                self.selected_idx = clicked_idx
                self.has_pending = False
                return
        else:
            if clicked_idx >= 0 and self.units[clicked_idx].team == "player":
                self.selected_idx = clicked_idx
                self.has_pending = False

    def handle_power_click(mut self, x: Int, y: Int, clicked_idx: Int):
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

    def execute_mammoth_charge(mut self, dx: Int, dy: Int):
        var mammoth_idx = self.selected_idx
        var mammoth = self.units[mammoth_idx]
        var mx = mammoth.x
        var my = mammoth.y
        var spaces_moved = 0

        for step in range(1, 5):
            var nx = mx + dx * step
            var ny = my + dy * step
            if nx < 0 or nx >= GRID_SIZE or ny < 0 or ny >= GRID_SIZE:
                break
            if self.terrain[ny * GRID_SIZE + nx] == 2:
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
                # Hit a unit - push it back
                var push_x = nx + dx
                var push_y = ny + dy
                var push_valid = True
                if push_x < 0 or push_x >= GRID_SIZE or push_y < 0 or push_y >= GRID_SIZE:
                    push_valid = False
                elif self.terrain[push_y * GRID_SIZE + push_x] == 2:
                    push_valid = False
                else:
                    for j in range(len(self.units)):
                        if j == mammoth_idx or j == hit_unit_idx:
                            continue
                        var u2 = self.units[j]
                        if u2.hp > 0 and not u2.dying and u2.x == push_x and u2.y == push_y:
                            push_valid = False
                            break

                var target = self.units[hit_unit_idx]
                if push_valid:
                    target.x = push_x
                    target.y = push_y
                target.hp -= step
                if target.hp <= 0:
                    target.hp = 0
                    target.dying = True
                    target.death_timer = 30
                self.units[hit_unit_idx] = target
                self.units[mammoth_idx].x = nx
                self.units[mammoth_idx].y = ny
                spaces_moved = step
                break
            else:
                # Move into empty space
                self.units[mammoth_idx].x = nx
                self.units[mammoth_idx].y = ny
                spaces_moved = step

        self.units[mammoth_idx].moved = True
        self.units[mammoth_idx].attacked = True
        self.units[mammoth_idx].power_used = True
        self.apply_fire_damage(mammoth_idx)
        self.power_mode = ""
        self.selected_idx = -1
        if spaces_moved > 0:
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
        # Apply end-of-turn fire damage to all units
        for i in range(len(self.units)):
            self.apply_fire_damage(i)
        self.check_win()

        self.selected_idx = -1
        self.has_pending = False
        self.power_mode = ""
        self.turn = "enemy"
        self.ai_turn()

    def check_win(mut self):
        if len(self.get_live_units("player")) == 0:
            self.winner = "enemy"
            self.game_over = True
        elif len(self.get_live_units("enemy")) == 0:
            self.winner = "player"
            self.game_over = True

    def init_terrain(mut self):
        self.terrain = List[Int]()
        for _ in range(GRID_SIZE * GRID_SIZE):
            self.terrain.append(0)

        # Winding blue band
        self.set_terrain(2, 0, 1)
        self.set_terrain(2, 1, 1)
        self.set_terrain(2, 2, 1)
        self.set_terrain(2, 3, 1)
        self.set_terrain(3, 3, 1)
        self.set_terrain(4, 3, 1)
        self.set_terrain(5, 3, 1)
        self.set_terrain(5, 4, 1)
        self.set_terrain(5, 5, 1)
        self.set_terrain(5, 6, 1)
        self.set_terrain(5, 7, 1)
        self.set_terrain(6, 7, 1)
        self.set_terrain(7, 7, 1)
        self.set_terrain(8, 7, 1)
        self.set_terrain(8, 8, 1)
        self.set_terrain(8, 9, 1)
        self.set_terrain(8, 10, 1)
        self.set_terrain(8, 11, 1)

        # Brown obstacles
        self.set_terrain(4, 4, 2)
        self.set_terrain(7, 2, 2)
        self.set_terrain(9, 5, 2)
        self.set_terrain(3, 9, 2)
        self.set_terrain(10, 4, 2)

    def set_terrain(mut self, x: Int, y: Int, t: Int):
        if x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE:
            self.terrain[y * GRID_SIZE + x] = t

    def get_terrain_cost(self, x: Int, y: Int) -> Int:
        if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
            return 99
        var t = self.terrain[y * GRID_SIZE + x]
        if t == 2:
            return 99
        elif t == 1:
            return 2
        else:
            return 1

    def _color(self, r: Int, g: Int, b: Int) raises -> PythonObject:
        return Python.tuple(r, g, b)

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
        var COLOR_BG = self._color(30, 30, 30)
        var COLOR_GRID = self._color(50, 50, 50)
        var COLOR_GRID_LINE = self._color(80, 80, 80)
        var COLOR_PLAYER = self._color(50, 150, 255)
        var COLOR_PLAYER_MOVED = self._color(30, 90, 150)
        var COLOR_ENEMY = self._color(255, 80, 80)
        var COLOR_ENEMY_MOVED = self._color(150, 50, 50)
        var COLOR_SELECTED = self._color(255, 255, 100)
        var COLOR_MOVE_RANGE = self._color(100, 200, 100)
        var COLOR_MOVE_PREVIEW = self._color(150, 255, 150)
        var COLOR_ATTACK_RANGE = self._color(255, 150, 100)
        var COLOR_TEXT = self._color(255, 255, 255)
        var COLOR_BUTTON = self._color(80, 80, 120)
        var COLOR_BUTTON_HOVER = self._color(100, 100, 150)
        var COLOR_BUTTON_DISABLED = self._color(60, 60, 60)
        var COLOR_UI_BG = self._color(20, 20, 20)

        self.screen.fill(COLOR_BG)

        # Draw grid
        for x in range(GRID_SIZE):
            for y in range(GRID_SIZE):
                var rect = self.pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                var t = self.terrain[y * GRID_SIZE + x]
                var tile_color: PythonObject
                if t == 1:
                    tile_color = self._color(60, 90, 150)
                elif t == 2:
                    tile_color = self._color(120, 80, 40)
                else:
                    tile_color = self._color(60, 120, 60)
                self.pygame.draw.rect(self.screen, tile_color, rect)
                self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)

        # Draw fire tiles
        for i in range(len(self.fire_tiles)):
            var idx = self.fire_tiles[i]
            var fx = idx % GRID_SIZE
            var fy = idx // GRID_SIZE
            var fire_rect = self.pygame.Rect(fx * CELL_SIZE + 4, fy * CELL_SIZE + 4, CELL_SIZE - 8, CELL_SIZE - 8)
            var fire_color = self._color(255, 100, 0)
            self.pygame.draw.rect(self.screen, fire_color, fire_rect, border_radius=4)

        # Draw move range, pending move, and power ranges
        if self.selected_idx >= 0 and self.turn == "player" and not self.game_over:
            if self.power_mode == "flame":
                var unit = self.units[self.selected_idx]
                for x in range(GRID_SIZE):
                    for y in range(GRID_SIZE):
                        var dist = abs(x - unit.x) + abs(y - unit.y)
                        if dist <= 4 and dist > 0:
                            var rect = self.pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                            self.pygame.draw.rect(self.screen, self._color(255, 80, 0), rect)
                            self.pygame.draw.rect(self.screen, COLOR_GRID_LINE, rect, 1)
            elif self.power_mode == "swap":
                var unit = self.units[self.selected_idx]
                for x in range(GRID_SIZE):
                    for y in range(GRID_SIZE):
                        var dist = abs(x - unit.x) + abs(y - unit.y)
                        if dist <= 4:
                            var rect = self.pygame.Rect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
                            self.pygame.draw.rect(self.screen, self._color(180, 180, 255), rect)
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
                        self.pygame.draw.rect(self.screen, self._color(200, 150, 100), rect)
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

        # Draw units
        for i in range(len(self.units)):
            var unit = self.units[i]
            if unit.hp <= 0 and not unit.dying:
                continue

            var color: PythonObject
            if unit.team == "player":
                if unit.unit_type == "Mojo":
                    color = self._color(255, 120, 0)
                elif unit.unit_type == "Max":
                    color = self._color(220, 220, 240)
                elif unit.unit_type == "Mammoth":
                    color = self._color(160, 120, 80)
                else:
                    color = COLOR_PLAYER
            else:
                color = COLOR_ENEMY

            if (unit.team == "player" and unit.moved) or (unit.team == "enemy" and unit.moved):
                if unit.team == "player":
                    if unit.unit_type == "Mojo":
                        color = self._color(150, 70, 0)
                    elif unit.unit_type == "Max":
                        color = self._color(140, 140, 160)
                    elif unit.unit_type == "Mammoth":
                        color = self._color(100, 70, 40)
                    else:
                        color = COLOR_PLAYER_MOVED
                else:
                    color = COLOR_ENEMY_MOVED

            var margin = 8
            var rect = self.pygame.Rect(unit.x * CELL_SIZE + margin, unit.y * CELL_SIZE + margin, CELL_SIZE - margin * 2, CELL_SIZE - margin * 2)

            if unit.dying:
                var flash = unit.death_timer % 6 < 3
                var death_color = self._color(255, 50, 50) if flash else self._color(30, 0, 0)
                self.pygame.draw.rect(self.screen, death_color, rect, border_radius=6)
                var skull = self.font.render("X", True, self._color(255, 255, 255))
                var skull_rect = skull.get_rect(center=Python.tuple(unit.x * CELL_SIZE + CELL_SIZE // 2, unit.y * CELL_SIZE + CELL_SIZE // 2))
                self.screen.blit(skull, skull_rect)
            else:
                self.pygame.draw.rect(self.screen, color, rect, border_radius=6)
                if i == self.selected_idx:
                    self.pygame.draw.rect(self.screen, COLOR_SELECTED, rect, 3, border_radius=6)

                # Unit label
                var label_text = "E"
                if unit.team == "player":
                    if unit.unit_type == "Mojo":
                        label_text = "M"
                    elif unit.unit_type == "Max":
                        label_text = "A"
                    elif unit.unit_type == "Mammoth":
                        label_text = "W"
                var label = self.font.render(label_text, True, self._color(0, 0, 0))
                var label_rect = label.get_rect(center=Python.tuple(unit.x * CELL_SIZE + CELL_SIZE // 2, unit.y * CELL_SIZE + CELL_SIZE // 2 - 4))
                self.screen.blit(label, label_rect)

                # HP squares (4 squares, green for HP, black for lost)
                var sq_size = 8
                var sq_gap = 2
                var total_w = 4 * sq_size + 3 * sq_gap
                var start_x = unit.x * CELL_SIZE + (CELL_SIZE - total_w) // 2
                var start_y = unit.y * CELL_SIZE + CELL_SIZE - 14
                for h in range(4):
                    var sq_color = self._color(0, 200, 0) if h < unit.hp else self._color(0, 0, 0)
                    var sq_rect = self.pygame.Rect(start_x + h * (sq_size + sq_gap), start_y, sq_size, sq_size)
                    self.pygame.draw.rect(self.screen, sq_color, sq_rect)
                    self.pygame.draw.rect(self.screen, self._color(40, 40, 40), sq_rect, 1)

        # UI panel
        var ui_rect = self.pygame.Rect(GRID_WIDTH, 0, UI_WIDTH, SCREEN_HEIGHT)
        self.pygame.draw.rect(self.screen, COLOR_UI_BG, ui_rect)

        # Buttons
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

        # Message
        var msg = self.message
        if self.game_over:
            msg = self.winner + " wins!"
        elif self.turn == "player" and self.selected_idx >= 0:
            if self.has_pending:
                msg = "Confirm or Undo move"
            elif self.power_mode != "":
                msg = self.message
            elif not self.units[self.selected_idx].moved:
                msg = "Click a tile to move or an adjacent enemy to attack"
            else:
                msg = "Unit moved. Click adjacent enemy to attack or End Turn"
        var msg_surf = self.font.render(msg, True, COLOR_TEXT)
        self.screen.blit(msg_surf, Python.tuple(GRID_WIDTH + 10, SCREEN_HEIGHT - 60))

        # Instructions
        var instructions = List[String]()
        instructions.append("Green=1, Blue=2, Brown=block")
        instructions.append("M=Mojo, A=Max, W=Mammoth")
        instructions.append("Select unit, Move, Attack")
        instructions.append("Power: Flame/Swap/Charge")
        instructions.append("End Turn when done")
        var iy = 250
        for i in range(len(instructions)):
            var surf = self.font.render(instructions[i], True, self._color(180, 180, 180))
            self.screen.blit(surf, Python.tuple(GRID_WIDTH + 10, iy))
            iy += 20

        # Unit info panel
        if self.selected_idx >= 0 and not self.game_over:
            var sel = self.units[self.selected_idx]
            var info = sel.unit_type + " HP:" + String(sel.hp) + "/4"
            if sel.moved:
                info += " [Moved]"
            if sel.attacked:
                info += " [Attacked]"
            if sel.power_used:
                info += " [Power]"
            var info_surf = self.font.render(info, True, self._color(255, 255, 200))
            self.screen.blit(info_surf, Python.tuple(GRID_WIDTH + 10, 400))

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


def main() raises:
    var game = Game()
    game.run()
