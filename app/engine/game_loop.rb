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
  args.state.scene ||= :menu

  initialise_player args

  # Render
  render_game args, lowrez_sprites
  render_ui args, lowrez_labels

  case args.state.scene
  when :menu
    render_menu args, lowrez_sprites
  when :controls
    render_controls args, lowrez_sprites
  when :game
    # Player physics
    move_player args
    move_bullets args
    fire_player args

    # Enemy physics
    spawn_enemies args
    move_enemies args
    kill_enemies args
  when :game_over
    render_game_over args, lowrez_labels
  end

  enable_debug_controls args

  # args.state.clear! 
  change_to_scene args, :game_over if args.state.player[:health] <= 0
end

def enable_debug_controls args
  change_to_scene args, :game_over if args.keyboard.key_down.g
end
