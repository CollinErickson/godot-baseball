teams_df <- readr::read_csv("./data/teams/teams.csv")
teams_df
teams_df$team_id <- as.integer(teams_df$team_id)
teams_df
teams_json <- jsonlite::toJSON(teams_df)
teams_json
# readr::wr
jsonlite::write_json(teams_df, "./data/teams/teams.json")
