###################################################################################
# MAIN GAME LOOP
# RUNS 60 TIMES PER SECOND
###################################################################################

require 'app/renderer/renderer.rb'
require 'app/engine/state/player_state.rb'
require 'app/engine/state/enemy_state.rb'

PLAYER_WIDTH = 6

def game_loop args, lowrez_sprites, lowrez_labels, lowrez_mouse

  # Initialise game state
  args.state.tick_count ||= -1
  args.state.scene ||= :game

  initialise_player args

  # Render
  render_game args, lowrez_sprites
  render_ui args, lowrez_labels
  render_game_over args, lowrez_labels

  if args.state.scene == :game
    # Player physics
    move_player args
    move_bullets args
    fire_player args

    # Enemy physics
    spawn_enemies args
    move_enemies args
    kill_enemies args
  end

  # args.state.clear! 
  change_to_scene args, :game_over if args.state.player[:health] <= 0
end
