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
    var jetpack: Bool

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
        self.jetpack = (unit_type == "Max")

    def is_adjacent(self, other: Unit) -> Bool:
        return abs(self.x - other.x) + abs(self.y - other.y) == 1

    def reset_turn(mut self):
        self.moved = False
        self.attacked = False
        self.power_used = False
