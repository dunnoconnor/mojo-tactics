from std.python import Python, PythonObject
from std.collections import List
from constants import GRID_SIZE, CELL_SIZE

struct Terrain(Movable):
    var terrain: List[Int]

    def __init__(out self) raises:
        self.terrain = List[Int]()
        self.init_terrain()

    def init_terrain(mut self) raises:
        self.terrain = List[Int]()
        for _ in range(GRID_SIZE * GRID_SIZE):
            self.terrain.append(0)

        self._generate_river()
        self._generate_rocks()

    def _generate_river(mut self) raises:
        var random = Python.import_module("random")
        var start_edge = Int(py=random.randint(0, 3))
        var x: Int
        var y: Int
        var target_edge: Int

        if start_edge == 0:
            x = Int(py=random.randint(0, GRID_SIZE - 1))
            y = 0
            target_edge = 2
        elif start_edge == 1:
            x = GRID_SIZE - 1
            y = Int(py=random.randint(0, GRID_SIZE - 1))
            target_edge = 3
        elif start_edge == 2:
            x = Int(py=random.randint(0, GRID_SIZE - 1))
            y = GRID_SIZE - 1
            target_edge = 0
        else:
            x = 0
            y = Int(py=random.randint(0, GRID_SIZE - 1))
            target_edge = 1

        var river = List[Int]()
        river.append(y * GRID_SIZE + x)
        self.terrain[y * GRID_SIZE + x] = 1

        var reached = False
        var steps = 0
        while not reached and steps < 200:
            steps += 1
            var dx = 0
            var dy = 0
            if target_edge == 0:
                dy = -1
            elif target_edge == 1:
                dx = 1
            elif target_edge == 2:
                dy = 1
            else:
                dx = -1

            var r = Float64(py=random.random())
            if r < 0.3:
                var dir = Int(py=random.randint(0, 3))
                if dir == 0:
                    dx = 0
                    dy = -1
                elif dir == 1:
                    dx = 1
                    dy = 0
                elif dir == 2:
                    dx = 0
                    dy = 1
                else:
                    dx = -1
                    dy = 0
            elif r < 0.7:
                var perp = Int(py=random.randint(0, 1))
                if target_edge == 0 or target_edge == 2:
                    dx = 1 if perp == 0 else -1
                    dy = 0
                else:
                    dx = 0
                    dy = 1 if perp == 0 else -1

            var nx = x + dx
            var ny = y + dy
            if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
                x = nx
                y = ny
                river.append(y * GRID_SIZE + x)
                self.terrain[y * GRID_SIZE + x] = 1

            if target_edge == 0 and y == 0:
                reached = True
            elif target_edge == 1 and x == GRID_SIZE - 1:
                reached = True
            elif target_edge == 2 and y == GRID_SIZE - 1:
                reached = True
            elif target_edge == 3 and x == 0:
                reached = True

        var extra = Int(py=random.randint(1, 3))
        for _ in range(extra):
            var i = Int(py=random.randint(0, len(river) - 1))
            var rx = river[i] % GRID_SIZE
            var ry = river[i] // GRID_SIZE
            var d = Int(py=random.randint(0, 3))
            var nx = rx
            var ny = ry
            if d == 0:
                ny = ry - 1
            elif d == 1:
                nx = rx + 1
            elif d == 2:
                ny = ry + 1
            else:
                nx = rx - 1
            if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
                if self.terrain[ny * GRID_SIZE + nx] == 0:
                    self.terrain[ny * GRID_SIZE + nx] = 1
                    river.append(ny * GRID_SIZE + nx)

    def _generate_rocks(mut self) raises:
        var random = Python.import_module("random")
        var positions = Python.list()
        for i in range(GRID_SIZE * GRID_SIZE):
            if self.terrain[i] == 0:
                positions.append(i)
        random.shuffle(positions)

        var blocked = List[Int]()
        blocked.append(1 * GRID_SIZE + 1)
        blocked.append(3 * GRID_SIZE + 2)
        blocked.append(1 * GRID_SIZE + 3)
        blocked.append(10 * GRID_SIZE + 8)
        blocked.append(8 * GRID_SIZE + 9)
        blocked.append(10 * GRID_SIZE + 10)

        var rocks = 0
        for i in range(len(positions)):
            var idx = Int(py=positions[i])
            var is_blocked = False
            for j in range(len(blocked)):
                if blocked[j] == idx:
                    is_blocked = True
                    break
            if not is_blocked and rocks < 5:
                self.terrain[idx] = 2
                rocks += 1

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

    def is_impassable(self, x: Int, y: Int) -> Bool:
        if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
            return True
        return self.terrain[y * GRID_SIZE + x] == 2

    def _hash(self, x: Int, y: Int) -> Int:
        return ((x * 73856093) ^ (y * 19349663)) & 0x7FFFFFFF

    def draw(self, pygame: PythonObject, screen: PythonObject, tick: Int) raises:
        for x in range(GRID_SIZE):
            for y in range(GRID_SIZE):
                var t = self.terrain[y * GRID_SIZE + x]
                if t == 1:
                    self._draw_water_tile(pygame, screen, x, y)
                elif t == 2:
                    self._draw_rock_tile(pygame, screen, x, y)
                else:
                    self._draw_grass_tile(pygame, screen, x, y)

    def draw_fire_tiles(self, pygame: PythonObject, screen: PythonObject, fire_tiles: List[Int], tick: Int) raises:
        for i in range(len(fire_tiles)):
            var idx = fire_tiles[i]
            var fx = idx % GRID_SIZE
            var fy = idx // GRID_SIZE
            self._draw_fire_tile(pygame, screen, fx, fy, tick)

    def _draw_grass_tile(self, pygame: PythonObject, screen: PythonObject, x: Int, y: Int) raises:
        var bx = x * CELL_SIZE
        var by = y * CELL_SIZE
        var h = self._hash(x, y)
        var base_g = 120 + (h % 40)
        pygame.draw.rect(screen, Python.tuple(40, base_g, 40), pygame.Rect(bx, by, CELL_SIZE, CELL_SIZE))
        var blade_colors = List[Tuple[Int, Int, Int]]()
        blade_colors.append((50, 160, 50))
        blade_colors.append((60, 180, 60))
        blade_colors.append((80, 200, 80))
        blade_colors.append((40, 140, 40))
        for i in range(6 + (h % 5)):
            var sx = bx + 4 + ((h + i * 37) % (CELL_SIZE - 8))
            var sy = by + 4 + ((h + i * 53) % (CELL_SIZE - 12))
            var hh = (h + i * 17) % 4
            var c = blade_colors[hh]
            var hh2 = (h + i * 19) % 3 + 2
            pygame.draw.rect(screen, Python.tuple(c[0], c[1], c[2]), pygame.Rect(sx, sy + 4, 2, hh2))

    def _draw_rock_tile(self, pygame: PythonObject, screen: PythonObject, x: Int, y: Int) raises:
        var bx = x * CELL_SIZE
        var by = y * CELL_SIZE
        var h = self._hash(x, y)
        pygame.draw.rect(screen, Python.tuple(110, 75, 35), pygame.Rect(bx, by, CELL_SIZE, CELL_SIZE))
        var crags = List[Tuple[Int, Int, Int, Int]]()
        crags.append((4, 6, 8, 6))
        crags.append((18, 2, 10, 8))
        crags.append((10, 14, 12, 6))
        crags.append((2, 24, 14, 8))
        crags.append((22, 20, 10, 10))
        crags.append((30, 8, 8, 12))
        crags.append((14, 30, 10, 6))
        for i in range(len(crags)):
            var cx = bx + crags[i][0]
            var cy = by + crags[i][1]
            var cw = crags[i][2]
            var ch = crags[i][3]
            var shade = 80 + ((h + i * 29) % 40)
            pygame.draw.rect(screen, Python.tuple(shade, shade - 20, shade - 40), pygame.Rect(cx, cy, cw, ch), border_radius=2)

    def _draw_water_tile(self, pygame: PythonObject, screen: PythonObject, x: Int, y: Int) raises:
        var bx = x * CELL_SIZE
        var by = y * CELL_SIZE
        var h = self._hash(x, y)
        var base_b = 140 + (h % 30)
        pygame.draw.rect(screen, Python.tuple(40, 70, base_b), pygame.Rect(bx, by, CELL_SIZE, CELL_SIZE))
        for i in range(3 + (h % 3)):
            var ry = by + 6 + ((h + i * 41) % (CELL_SIZE - 12))
            var rx = bx + 2 + ((h + i * 23) % (CELL_SIZE - 16))
            var rw = 8 + ((h + i * 31) % 12)
            pygame.draw.rect(screen, Python.tuple(180, 220, 255), pygame.Rect(rx, ry, rw, 2), border_radius=1)

    def _draw_fire_tile(self, pygame: PythonObject, screen: PythonObject, x: Int, y: Int, tick: Int) raises:
        var bx = x * CELL_SIZE
        var by = y * CELL_SIZE
        var h = self._hash(x, y)
        pygame.draw.rect(screen, Python.tuple(60, 20, 0), pygame.Rect(bx + 1, by + 1, CELL_SIZE - 2, CELL_SIZE - 2))
        var flicker = (tick + h) % 8
        var colors = List[Tuple[Int, Int, Int]]()
        colors.append((255, 80, 0))
        colors.append((255, 140, 0))
        colors.append((255, 200, 0))
        colors.append((255, 60, 0))
        colors.append((200, 40, 0))
        colors.append((255, 100, 20))
        colors.append((255, 180, 40))
        colors.append((220, 60, 10))
        for i in range(10):
            var fx = bx + 2 + ((h + i * 13 + flicker * 3) % (CELL_SIZE - 6))
            var fy = by + 2 + ((h + i * 17 + flicker * 2) % (CELL_SIZE - 8))
            var fw = 2 + ((h + i * 11 + flicker) % 4)
            var fh = 3 + ((h + i * 7 + flicker) % 8)
            var ci = (h + i + flicker) % 8
            var c = colors[ci]
            pygame.draw.rect(screen, Python.tuple(c[0], c[1], c[2]), pygame.Rect(fx, fy, fw, fh), border_radius=1)
