from std.python import Python, PythonObject
from std.collections import List
from constants import SCREEN_WIDTH, SCREEN_HEIGHT, CELL_SIZE

struct LevelSelect:
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

        var back_y = SCREEN_HEIGHT - 30
        if py >= back_y - 15 and py <= back_y + 15:
            return -1

        var node_positions = List[Tuple[Int, Int]]()
        node_positions.append((300, 150))
        node_positions.append((500, 300))
        node_positions.append((300, 450))

        for i in range(3):
            var nx = node_positions[i][0]
            var ny = node_positions[i][1]
            var dx = px - nx
            var dy = py - ny
            if dx * dx + dy * dy <= 40 * 40:
                return i

        return -2

    def draw(mut self, levels_completed: List[Bool]) raises:
        var tick = Int(py=self.pygame.time.get_ticks()) // 100
        var COLOR_OCEAN = Python.tuple(20, 40, 80)
        var COLOR_WAVE = Python.tuple(200, 220, 255)
        self.screen.fill(COLOR_OCEAN)

        # Draw waves in the ocean — horizontal shimmering lines that move over time
        for wy in range(0, SCREEN_HEIGHT, 18):
            var wave_offset = (tick + wy * 3) % (SCREEN_WIDTH + 40)
            var wave_alpha = 60 + ((wy + tick) % 40)
            var wave_color = Python.tuple(wave_alpha + 140, min(wave_alpha + 180, 255), 255)
            var wx_start = wave_offset - 20
            var wx_end = wx_start + 30 + ((wy + tick) % 20)
            if wx_start < 0:
                wx_start = 0
            if wx_end > SCREEN_WIDTH:
                wx_end = SCREEN_WIDTH
            self.pygame.draw.line(self.screen, wave_color, Python.tuple(wx_start, wy), Python.tuple(wx_end, wy), 2)

        # Track island edge tiles for later wave drawing
        var island_tiles = List[Tuple[Int, Int, Bool]]()

        for x in range(16):
            for y in range(12):
                var cx = Float64(x) - 7.5
                var cy = Float64(y) - 5.5
                var dx = cx / 6.0
                var dy = cy / 4.5
                var dist_sq = dx * dx + dy * dy
                var is_island = False
                if dist_sq < 1.0:
                    if dist_sq > 0.72 and ((x + y * 3) % 5 == 0):
                        pass
                    else:
                        is_island = True
                        var bx = x * CELL_SIZE
                        var by = y * CELL_SIZE
                        var h = ((x * 73856093) ^ (y * 19349663)) & 0x7FFFFFFF
                        var base_g = 120 + (h % 40)
                        self.pygame.draw.rect(self.screen, Python.tuple(40, base_g, 40), self.pygame.Rect(bx, by, CELL_SIZE, CELL_SIZE))
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
                            self.pygame.draw.rect(self.screen, Python.tuple(c[0], c[1], c[2]), self.pygame.Rect(sx, sy + 4, 2, hh2))

                # Check if this is a water tile adjacent to land (coastline)
                if not is_island:
                    var is_adjacent = False
                    for nx in range(x - 1, x + 2):
                        for ny in range(y - 1, y + 2):
                            if nx == x and ny == y:
                                continue
                            var ncx = Float64(nx) - 7.5
                            var ncy = Float64(ny) - 5.5
                            var ndx = ncx / 6.0
                            var ndy = ncy / 4.5
                            var ndist_sq = ndx * ndx + ndy * ndy
                            if ndist_sq < 1.0:
                                if not (ndist_sq > 0.72 and ((nx + ny * 3) % 5 == 0)):
                                    is_adjacent = True
                    if is_adjacent:
                        island_tiles.append((x, y, True))

        # Draw white foam waves on the coastline tiles
        for i in range(len(island_tiles)):
            var x = island_tiles[i][0]
            var y = island_tiles[i][1]
            var bx = x * CELL_SIZE
            var by = y * CELL_SIZE
            var h = ((x * 73856093) ^ (y * 19349663)) & 0x7FFFFFFF
            var wave_phase = (tick + h) % 20
            var foam_alpha = 120 + abs(10 - wave_phase) * 8
            var foam_color = Python.tuple(foam_alpha, foam_alpha, foam_alpha + 40)
            # Draw a foam line along the edge facing land
            for fx in range(3):
                for fy in range(3):
                    var draw_fx = 6 + fx * 14 + ((h + fx) % 8)
                    var draw_fy = 6 + fy * 14 + ((h + fy * 3) % 8)
                    var size = 2 + ((h + fx + fy + wave_phase) % 3)
                    self.pygame.draw.rect(self.screen, foam_color, self.pygame.Rect(bx + draw_fx, by + draw_fy, size, size))

        var rock_positions = List[Tuple[Int, Int]]()
        rock_positions.append((3, 4))
        rock_positions.append((12, 3))
        rock_positions.append((11, 7))
        rock_positions.append((2, 8))
        for r in range(len(rock_positions)):
            var rx = rock_positions[r][0]
            var ry = rock_positions[r][1]
            var bx = rx * CELL_SIZE
            var by = ry * CELL_SIZE
            var h = ((rx * 73856093) ^ (ry * 19349663)) & 0x7FFFFFFF
            self.pygame.draw.rect(self.screen, Python.tuple(110, 75, 35), self.pygame.Rect(bx, by, CELL_SIZE, CELL_SIZE))
            var crags = List[Tuple[Int, Int, Int, Int]]()
            crags.append((4, 6, 8, 6))
            crags.append((18, 2, 10, 8))
            crags.append((10, 14, 12, 6))
            crags.append((2, 24, 14, 8))
            crags.append((22, 20, 10, 10))
            crags.append((30, 8, 8, 12))
            crags.append((14, 30, 10, 6))
            for j in range(len(crags)):
                var cx = bx + crags[j][0]
                var cy = by + crags[j][1]
                var cw = crags[j][2]
                var ch = crags[j][3]
                var shade = 80 + ((h + j * 29) % 40)
                self.pygame.draw.rect(self.screen, Python.tuple(shade, shade - 20, shade - 40), self.pygame.Rect(cx, cy, cw, ch), border_radius=2)

        var path_color = Python.tuple(180, 160, 100)
        var path_width = 4
        self.pygame.draw.line(self.screen, path_color, Python.tuple(300, 150), Python.tuple(500, 300), path_width)
        self.pygame.draw.line(self.screen, path_color, Python.tuple(500, 300), Python.tuple(300, 450), path_width)

        var node_positions = List[Tuple[Int, Int]]()
        node_positions.append((300, 150))
        node_positions.append((500, 300))
        node_positions.append((300, 450))

        var node_labels = List[String]()
        node_labels.append("Survive")
        node_labels.append("Destroy")
        node_labels.append("Collect")

        var node_subtitles = List[String]()
        node_subtitles.append("6 turns")
        node_subtitles.append("6 bugs")
        node_subtitles.append("6 batteries")

        var mouse_pos = self.pygame.mouse.get_pos()
        var mx = Int(py=mouse_pos[0])
        var my = Int(py=mouse_pos[1])

        for i in range(3):
            var nx = node_positions[i][0]
            var ny = node_positions[i][1]
            var completed = levels_completed[i]
            var dx = mx - nx
            var dy = my - ny
            var is_hover = dx * dx + dy * dy <= 40 * 40

            var pulse = (tick % 10)
            var radius = 25 + pulse if not completed else 25
            var node_color = Python.tuple(255, 200, 50) if completed else (Python.tuple(100, 200, 255) if is_hover else Python.tuple(80, 150, 220))
            var glow_color = Python.tuple(255, 220, 100) if completed else Python.tuple(150, 220, 255)

            self.pygame.draw.circle(self.screen, glow_color, Python.tuple(nx, ny), radius + 8, 3)
            self.pygame.draw.circle(self.screen, node_color, Python.tuple(nx, ny), radius)
            self.pygame.draw.circle(self.screen, Python.tuple(255, 255, 255), Python.tuple(nx, ny), radius, 2)

            if completed:
                var check = self.big_font.render("V", True, Python.tuple(0, 200, 0))
                var check_rect = check.get_rect(center=Python.tuple(nx, ny))
                self.screen.blit(check, check_rect)
            else:
                var num = self.big_font.render(String(i + 1), True, Python.tuple(255, 255, 255))
                var num_rect = num.get_rect(center=Python.tuple(nx, ny))
                self.screen.blit(num, num_rect)

            var label = self.font.render(node_labels[i], True, Python.tuple(255, 255, 255))
            var label_rect = label.get_rect(center=Python.tuple(nx, ny + 40))
            self.screen.blit(label, label_rect)

            var sub = self.font.render(node_subtitles[i], True, Python.tuple(200, 200, 200))
            var sub_rect = sub.get_rect(center=Python.tuple(nx, ny + 58))
            self.screen.blit(sub, sub_rect)

        var title_surf = self.big_font.render("Select a Mission", True, Python.tuple(255, 140, 0))
        var title_rect = title_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, 40))
        self.screen.blit(title_surf, title_rect)

        var back_surf = self.font.render("Click here to return to title", True, Python.tuple(180, 180, 255))
        var back_rect = back_surf.get_rect(center=Python.tuple(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 30))
        self.screen.blit(back_surf, back_rect)
