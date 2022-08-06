###################################################################################
# MAIN GAME LOOP
# RUNS 60 TIMES PER SECOND
###################################################################################

require 'app/renderer/renderer.rb'
require 'app/engine/state/player_state.rb'
require 'app/engine/state/enemy_state.rb'
require 'app/engine/state/power_up_state.rb'

PLAYER_WIDTH = 6

def game_loop args, lowrez_sprites, lowrez_labels, lowrez_mouse

  # Initialise game state
  args.state.tick_count ||= -1
  args.state.scene ||= :menu

  initialise_player args

  # Initialise audio
  args.outputs.sounds << "assets/audio/music/menu.ogg" if args.state.scene == :menu || args.state.scene == :controls

  # Render
  render_game args, lowrez_sprites

  case args.state.scene
  when :menu
    render_menu args, lowrez_sprites
  when :controls
    render_controls args, lowrez_sprites
  when :game
    render_game_ui args, lowrez_labels
    
    # Player physics
    move_player args
    move_bullets args
    fire_player args

    # Enemy physics
    spawn_enemies args
    move_enemies args
    kill_enemies args

    # Power ups
    spawn_power_ups args
    move_power_ups args
    destroy_power_ups args
  when :game_over
    render_game_over args, lowrez_labels
  end

  enable_debug_controls args

  # args.state.clear! 
  game_over args if args.state.player[:health] <= 0
end

def game_over args
  args.gtk.stop_music
  change_to_scene args, :game_over 
end

def enable_debug_controls args
  game_over args if args.keyboard.key_down.g
end
