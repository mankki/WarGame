
class_name UnitData
extends Resource

@export var scene :PackedScene
@export var max_number :int

@export_category("Stats")
@export var health :int
@export var cannot_attack :bool

@export_category("Actions")
@export_group("Move and Scan")
@export var move_range :Vector2i
@export var scan_range :Vector2i
@export var move_cost :int

@export_group("Primary Attack")
@export var primary_attack_damage :int
@export var primary_attack_range :int
@export var primary_attack_hit_chance :float
@export var primary_attack_ammunition :int
@export var primary_attack_cost :int

@export_group("Secondary Attack")
@export var secondary_attack_damage :int
@export var secondary_attack_range :int
@export var secondary_attack_hit_chance :float
@export var secondary_attack_ammunition :int
@export var secondary_attack_cost :int


var preview
var number :int
var string :String

