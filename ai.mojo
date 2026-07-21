from std.collections import List
from constants import GRID_SIZE
from unit import Unit
from terrain import Terrain


def is_tile_occupied(x: Int, y: Int, units: List[Unit], terrain: Terrain, exclude_idx: Int = -1) -> Bool:
    if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
        return True
    if terrain.is_impassable(x, y):
        return True
    for i in range(len(units)):
        if i == exclude_idx:
            continue
        var u = units[i]
        if u.hp > 0 and not u.dying and u.x == x and u.y == y:
            return True
    return False


def get_live_unit_indices(units: List[Unit], team: String) -> List[Int]:
    var result = List[Int]()
    for i in range(len(units)):
        if units[i].team == team and units[i].hp > 0 and not units[i].dying:
            result.append(i)
    return result^


def get_adjacent_enemy_indices(units: List[Unit], unit_idx: Int) -> List[Int]:
    var enemies = List[Int]()
    var unit = units[unit_idx]
    for i in range(len(units)):
        var other = units[i]
        if other.hp > 0 and not other.dying and other.team != unit.team and unit.is_adjacent(other):
            enemies.append(i)
    return enemies^


def find_closest_player(units: List[Unit], enemy_idx: Int) -> Int:
    var enemy = units[enemy_idx]
    var players = get_live_unit_indices(units, "player")
    if len(players) == 0:
        return -1
    var closest_idx = players[0]
    var closest_dist = abs(units[closest_idx].x - enemy.x) + abs(units[closest_idx].y - enemy.y)
    for j in range(1, len(players)):
        var p = units[players[j]]
        var d = abs(p.x - enemy.x) + abs(p.y - enemy.y)
        if d < closest_dist:
            closest_dist = d
            closest_idx = players[j]
    return closest_idx


def is_tile_on_fire(x: Int, y: Int, fire_tiles: List[Int]) -> Bool:
    var idx = y * GRID_SIZE + x
    for i in range(len(fire_tiles)):
        if fire_tiles[i] == idx:
            return True
    return False


def find_best_move(unit: Unit, units: List[Unit], terrain: Terrain, fire_tiles: List[Int]) -> Int:
    var best_idx = -1
    var best_cost = 99
    var best_score = -1

    var visited = List[Int]()
    for _ in range(GRID_SIZE * GRID_SIZE):
        visited.append(99)

    var queue = List[Int]()
    queue.append(unit.y * GRID_SIZE + unit.x)
    var cost = List[Int]()
    cost.append(0)
    visited[unit.y * GRID_SIZE + unit.x] = 0

    var q_idx = 0
    while q_idx < len(queue):
        var cidx = queue[q_idx]
        var cx = cidx % GRID_SIZE
        var cy = cidx // GRID_SIZE
        var ccost = cost[q_idx]
        q_idx += 1

        if ccost > 0 and ccost <= 4:
            var is_adjacent_to_player = False
            var closest_player_dist = 999
            for i in range(len(units)):
                var other = units[i]
                if other.hp > 0 and not other.dying and other.team == "player":
                    var dist = abs(cx - other.x) + abs(cy - other.y)
                    if dist < closest_player_dist:
                        closest_player_dist = dist
                    if dist == 1:
                        is_adjacent_to_player = True

            var score = 100 if is_adjacent_to_player else 50 - closest_player_dist

            var in_fire = 0 if is_tile_on_fire(cx, cy, fire_tiles) else 1

            if score > best_score or (score == best_score and ccost < best_cost) or (score == best_score and ccost == best_cost and in_fire > 0):
                best_score = score
                best_cost = ccost
                best_idx = cidx

        if ccost >= 4:
            continue

        var dirs = List[Int]()
        dirs.append(1)
        dirs.append(-1)
        dirs.append(GRID_SIZE)
        dirs.append(-GRID_SIZE)
        for d in range(len(dirs)):
            var nidx = cidx + dirs[d]
            var nx = nidx % GRID_SIZE
            var ny = nidx // GRID_SIZE
            if nx >= 0 and nx < GRID_SIZE and ny >= 0 and ny < GRID_SIZE:
                var tile_cost = terrain.get_terrain_cost(nx, ny)
                var new_cost = ccost + tile_cost
                if new_cost <= 4 and new_cost < visited[nidx] and not is_tile_occupied(nx, ny, units, terrain, exclude_idx=-1):
                    visited[nidx] = new_cost
                    queue.append(nidx)
                    cost.append(new_cost)

    return best_idx
