###################################################################################
# MAIN GAME LOOP & SCENE MANAGER
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
    grab_attack_player args
    drop_attack_player args
    animate_player_hit args

    # Enemy physics
    spawn_enemies args
    move_enemies args
    kill_enemies args

    spawn_tanks args
    move_tanks args
    move_tank_bullets args
    animate_tank_bullets args
    fire_tank args
    destroy_tank_bullets args
    carry_tanks args
    drop_tanks args

    spawn_helos args
    move_helos args
    animate_helos args
    fire_helo args
    move_helo_bullets args
    animate_helo_bullets args
    destroy_helo_bullets args
    carry_helos args
    drop_helos args

    spawn_bombers args
    move_bombers args
    fire_bomber args
    move_bombs args
    destroy_bombs args

    # Power ups
    spawn_power_ups args
    move_power_ups args
    destroy_power_ups args
    animate_power_up_bar args

    # Effects
    animate_explosions args
  when :game_over
    render_game_over args, lowrez_labels
  end

  enable_debug_controls args if DEV_MODE

  game_over args if args.state.player[:health] <= 0
end

def game_over args
  change_to_scene args, :game_over 
end

def return_to_menu args
  reset_game args.state.player, args
  change_to_scene args, :menu 
end

def reset_game player, args
  player.health = 5
  player.score = 0
  player.x = SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2
  player.y = SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2
  player.vx = 0
  player.vy = 0
  player.direction = 1
  player.active_power_up = nil
  player.time_of_death = nil
  player.grabbing = false
  player.last_hit_at = -Float::INFINITY
  player.power_up_active_at = -Float::INFINITY
  args.state.player.started_moving_at = 0
  args.state.player_bullets.clear
  args.state.enemies.clear
  args.state.tanks.clear
  args.state.tank_bullets.clear
  args.state.power_ups.clear
  args.state.active_orb.clear
  args.state.active_bar.clear
  args.state.explosions.clear
  args.state.helos.clear
  args.state.helo_bullets.clear
  args.state.bombers.clear
  args.state.bombs.clear

  args.outputs.sounds << "assets/audio/music/game.ogg" unless args.state.scene == :controls
  change_to_scene args, :game 
end

# Devtools

def enable_debug_controls args
  # Scenes
  game_over args if args.keyboard.key_down.g
  # Player state
  args.state.player.score += 10 if args.keyboard.key_down.plus
  args.state.player.score -= 10 if args.keyboard.key_down.hyphen
  args.state.player.health = 5 if args.keyboard.key_down.r
  # Power ups
  activate_power_up args, :health if args.keyboard.key_down.zero
  activate_power_up args, :lifesteal if args.keyboard.key_down.one
  activate_power_up args, :speed if args.keyboard.key_down.two
  activate_power_up args, :slowdown if args.keyboard.key_down.three
  activate_power_up args, :rapid_fire if args.keyboard.key_down.four
  activate_power_up args, :minigun if args.keyboard.key_down.five
  activate_power_up args, :immunity if args.keyboard.key_down.six
end
