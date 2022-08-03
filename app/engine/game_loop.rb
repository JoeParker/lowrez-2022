###################################################################################
# MAIN GAME LOOP
# RUNS 60 TIMES PER SECOND
###################################################################################

require 'app/renderer.rb'
require 'app/engine/player_physics.rb'
require 'app/engine/enemy_physics.rb'

PLAYER_WIDTH = 6

def game_loop args, lowrez_sprites, lowrez_labels, lowrez_mouse

  # Initialise game state
  args.state.tick_count ||= -1

  initialise_player args

  # Render
  render_game args, lowrez_sprites
  render_ui args, lowrez_labels

  # Player physics
  move_player args
  move_bullets args
  fire_player args

  # Enemy physics
  spawn_enemies args
  move_enemies args
  kill_enemies args

  args.state.clear! if args.state.player[:health] < 0
end
