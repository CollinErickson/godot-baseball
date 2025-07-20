extends Node
class_name Org

# org_id is team_id of MLB team
var org_id:int
# MLB team is first, then AAA, etc
var teams:Array[Team] = []
var n_levels:int = 4

func create_random() -> void:
	for i in range(n_levels):
		var team:Team = Team.new()
		team.create_random()
		teams.push_back(team)

func fix_roster() -> void:
	for team in teams:
		team.fix_roster()
