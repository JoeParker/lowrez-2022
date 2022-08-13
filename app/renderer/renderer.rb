###################################################################################
# MANAGES UI AND SPRITE ANIMATIONS
###################################################################################

# Render Constants
SCREEN_WIDTH = 64
PLAYER_WIDTH = 6

LOADING_TRANSITION_SPEED = 6

# Debug settings
DISPLAY_GRID = false # Display 64x64 grid overlay
DISPLAY_TICKS = false # Display frame counter

def initialise_player args
  if args.state.player == nil || !args.state.player.health.is_a?(Numeric) # If there's an issue on game reset, reinitialise the player state
    args.state.player = {
        x: SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2, 
        y: SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2, 
        w: PLAYER_WIDTH, 
        h: PLAYER_WIDTH, 
        a: 255,
        vx: 0, vy: 0, 
        direction: 1,
        path: "assets/sprites/player-fly.png",
        angle: 0,
        started_moving_at: 0, # This would be set to nil initially if we wanted the sprite to start idle
        health: 5, 
        cooldown: 0, 
        score: 0,
        active_power_up: nil,
        grabbing: false,
        last_hit_at: -Float::INFINITY,
        power_up_active_at: -Float::INFINITY
      }
  end
end


def render_game args, lowrez_sprites
  args.state.show_gridlines = DISPLAY_GRID

  args.state.background ||= {
    x: 0, y: 0,
    w: SCREEN_WIDTH, h: SCREEN_WIDTH,
    path: "assets/scenes/game.png"
  }
  lowrez_sprites << [args.state.background]

  args.state.healthbar ||= []
  lowrez_sprites << [args.state.healthbar]

  draw_health args

  args.state.player_bullets ||= []
  lowrez_sprites << [args.state.player_bullets]

  args.state.enemies ||= []
  lowrez_sprites << [args.state.enemies]

  # if args.state.player.started_moving_at
    lowrez_sprites << [running_sprite(args)]
  # else
    # lowrez_sprites << [idle_sprite(args)]
  # end

  args.state.tanks ||= []
  lowrez_sprites << [args.state.tanks]

  args.state.tank_bullets ||= []
  lowrez_sprites << [args.state.tank_bullets]

  args.state.helos ||= []
  lowrez_sprites << [args.state.helos]

  args.state.helo_bullets ||= []
  lowrez_sprites << [args.state.helo_bullets]

  args.state.power_ups ||= []
  lowrez_sprites << [args.state.power_ups]

  args.state.explosions ||= []
  lowrez_sprites << [args.state.explosions]

  args.state.active_orb ||= []
  lowrez_sprites << [args.state.active_orb]

  args.state.active_bar ||= []
  lowrez_sprites << [args.state.active_bar]

  return_to_menu args if args.keyboard.key_down.escape
end

def animate_player_death player, time_elapsed
  # player.angle -= 1 # TODO: Why doesn't this work?

  # Too lazy to do this mathematically - revisit it later
  case time_elapsed
  when 0..5
    player.y += 1.0
  when 6..10
    player.y += 0.6
  when 11..15
    player.y += 0.1
  when 16..20
    player.y -= 0.1
  when 21..25
    player.y -= 0.4
  when 26..30
    player.y -= 0.8
  else
    player.y -= 1.5
  end
end


def render_menu args, lowrez_sprites
  return unless args.state.scene == :menu || args.state.loading

  args.state.menu_focus ||= :start

  args.state.menu_focus = :start if args.keyboard.key_down.up || args.keyboard.key_down.w
  args.state.menu_focus = :help if args.keyboard.key_down.down || args.keyboard.key_down.s

  case args.state.menu_focus
  when :start
    menu_background = {
      x: 0, y: 0,
      w: SCREEN_WIDTH, h: SCREEN_WIDTH,
      path: "assets/scenes/menu-1.png"
    }
    lowrez_sprites << menu_background
  when :help
    menu_background = {
      x: 0, y: 0,
      w: SCREEN_WIDTH, h: SCREEN_WIDTH,
      path: "assets/scenes/menu-2.png"
    }
    lowrez_sprites << menu_background
  end

  # Input listeners
  change_to_scene args, :controls if (args.keyboard.key_down.enter || args.keyboard.key_down.space) && args.state.menu_focus == :help
  args.state.started_loading_at ||= args.state.tick_count if (args.keyboard.key_down.enter || args.keyboard.key_down.space) && args.state.menu_focus == :start

  # Animation the transition between menu and game
  if args.state.started_loading_at != nil 
    diff = args.state.tick_count - args.state.started_loading_at
    
    menu_background.w += diff * LOADING_TRANSITION_SPEED
    menu_background.h += diff * LOADING_TRANSITION_SPEED

    menu_background.x -= diff * LOADING_TRANSITION_SPEED / 2
    menu_background.y -= diff * LOADING_TRANSITION_SPEED / 2

    args.outputs.sounds << "assets/audio/music/game.ogg"
    
    if args.state.tick_count - args.state.started_loading_at > 60
      args.state.started_loading_at = nil
      change_to_scene args, :game 
    end
  end
end

def render_controls args, lowrez_sprites
  return unless args.state.scene == :controls

  lowrez_sprites << {
    x: 0, y: 0,
    w: SCREEN_WIDTH, h: SCREEN_WIDTH,
    path: "assets/scenes/controls.png"
  }

  change_to_scene args, :menu if args.keyboard.key_down.enter || args.keyboard.key_down.space || args.keyboard.key_down.escape
end

def render_game_over args, lowrez_labels
  return unless args.state.scene == :game_over #&& args.state.player.health <= 0

  args.state.player.time_of_death ||= args.state.tick_count
  args.state.player.started_moving_at = nil

  time_elapsed = args.state.tick_count - args.state.player.time_of_death

  args.outputs.sounds << "assets/audio/music/game-over.ogg" if time_elapsed == 0

  animate_player_death args.state.player, time_elapsed  
  animate_game_over_text args, lowrez_labels, time_elapsed

  if args.keyboard.key_down.enter
    args.outputs.sounds << "assets/audio/sfx/power-up.wav"
    reset_game args.state.player, args 
  end
  return_to_menu args if args.keyboard.key_down.escape
end

def animate_game_over_text args, lowrez_labels, time_elapsed
  # Determine the player's rank
  case args.state.player.score
  when -Float::INFINITY..-1
    rank = "How?"
  when 0
    rank = "Umm.."
  when 1..19
    rank = "Pest"
  when 20..49
    rank = "Imp"
  when 50..99
    rank = "Scamp"
  when 100..199
    rank = "Fiend"
  when 200..399
    rank = "Menace"
  when 400..649
    rank = "Terror"
  when 650..999
    rank = "Hellion"
  else
    rank = "Demon"
  end

  args.outputs.sounds << "assets/audio/sfx/player-hit.wav" if [45, 75, 125, 155].include? time_elapsed
  args.outputs.sounds << "assets/audio/sfx/player-fire.wav" if time_elapsed == 200 

  lowrez_labels << { x: 1, y: 40, text: "Score:", r: 11, g: 34, b: 38 } if time_elapsed >= 45 
  lowrez_labels << { x: 30, y: 40, text: "#{args.state.player.score}", r: 171, g: 0, b: 0 } if time_elapsed >= 75
  lowrez_labels << { x: 1, y: 30, text: "Rank:", r: 11, g: 34, b: 38 } if time_elapsed >= 125 
  lowrez_labels << { x: 25, y: 30, text: "#{rank}", r: 171, g: 0, b: 0 } if time_elapsed >= 155 
  lowrez_labels << { x: 18, y: 12, text: "Retry?", r: 233, g: 236, b: 232 } if time_elapsed >= 200 
  lowrez_labels << { x: 15, y: 6, text: "[Enter]", r: 233, g: 236, b: 232} if time_elapsed >= 200 
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
  args.state.player.started_moving_at = 0
  args.state.player_bullets.clear
  args.state.enemies.clear
  args.state.tanks.clear
  args.state.tank_bullets.clear
  args.state.power_ups.clear
  args.state.explosions.clear
  args.state.helos.clear
  args.state.helo_bullets.clear

  args.outputs.sounds << "assets/audio/music/game.ogg" unless args.state.scene == :controls
  change_to_scene args, :game 
end

def change_to_scene args, scene
    args.state.scene = scene
    args.state.scene_at = args.state.tick_count
    args.inputs.keyboard.clear
    args.inputs.controller_one.clear
end

def render_game_ui args, lowrez_labels
  if DISPLAY_TICKS
    lowrez_labels << {
      x: 0,
      y: 0,
      text: "#{args.state.tick_count}",
      r: 232,
      g: 236,
      b: 233
  }
  end

  lowrez_labels << {
    x: 1,
    y: 59,
    text: "#{args.state.player.score}",
    r: 232,
    g: 236,
    b: 233
  }
end

def draw_health args
  # If health has changed, re-render the healthbar
  if args.state.healthbar.length() != args.state.player.health
    args.state.healthbar = []
    args.state.player.health.times do |index|
      args.state.healthbar << {
        x: 59 - index * 6, y: 59,
        w: 5, h: 5,
        path: "assets/sprites/heart.png"
      }
    end
  end
  
end

def calculate_enemy_spawn_point
  case rand(3)
  when 0 # Spawn from left
    [-5, rand(70)]
  when 1 # Spawn from right
    [70, rand(70)]
  when 2 # Spawn from above
    [rand(70), 70]
  end
end

def spawn_enemies args
  # Spawn enemies more frequently as the player's score increases.
  if rand < (75+args.state.player[:score])/(10000 + args.state.player[:score]) || args.state.tick_count.zero?
    x, y = calculate_enemy_spawn_point
    args.state.enemies << {
      x: x, y: y,
      w: 2, h: 3, 
      path: 'assets/sprites/enemy-missile.png',
      angle: 0
    }
  end
end

def spawn_tanks args
  # Limit to max 1 tank on screen at once, or 2 if over 100 points scored
  tank_limit = args.state.player.score >= 100 ? 2 : 1
  # And dont spawn tanks until score is at least 20
  return unless (args.state.tanks.length < tank_limit && args.state.player[:score] >= 20) || (args.keyboard.key_down.t && DEV_MODE)

  # Spawn enemies more frequently as the player's score increases.
  if rand < (75+args.state.player[:score])/(30000 + args.state.player[:score]) || (args.keyboard.key_down.t && DEV_MODE)

    # Spawn from bottom left/right only
    case rand(2)
    when 0 # Spawn from left
      x = -5
    when 1 # Spawn from right
      x = 70
    end

    args.state.tanks << {
      x: x, y: 0,
      w: 7, h: 7,
      path: "assets/sprites/enemy-tank.png",
      grab_state: nil,
      angle: 0
    }
  end
end

def spawn_helos args
  # Limit to max 1 helo on screen at once, or 2 if over 200 points scored
  helo_limit = args.state.player.score >= 200 ? 2 : 1
  # And dont spawn helos until score is at least 70
  return unless (args.state.helos.length < helo_limit && args.state.player[:score] >= 70) || (args.keyboard.key_down.h && DEV_MODE)

  # Spawn enemies more frequently as the player's score increases.
  if rand < (75+args.state.player[:score])/(30000 + args.state.player[:score]) || (args.keyboard.key_down.h && DEV_MODE)

    # Spawn from left/right only
    case rand(2)
    when 0 # Spawn from left
      x, flip_horizontally = [-5, false]
    when 1 # Spawn from right
      x, flip_horizontally = [70, true]
    end
    # If there's already a helo on that side, spawn across instead
    x, flip_horizontally = [-5, false] if args.state.helos.any? { |helo| helo.x > 32 && helo.grab_state == nil }
    x, flip_horizontally = [70, true] if args.state.helos.any? { |helo| helo.x < 32 && helo.grab_state == nil }

    args.state.helos << {
      x: x, y: rand(50) + 10,
      w: 8, h: 5,
      path: "assets/sprites/enemy-helo-animated.png",
      tile_x: 0, tile_y: 0,
      tile_w: 8, tile_h: 5,
      tile_index: 0,
      flip_horizontally: flip_horizontally,
      angle: 0,
      grab_state: nil
    }
  end
end

def animate_helos args
  # Animate 12 times per second
  return unless args.state.tick_count % 5 == 0

  args.state.helos.each do |helo|
    if helo.tile_x < 24
      helo.tile_x += 8
    else
      helo.tile_x = 0
    end
  end
end

def spawn_power_ups args
  # Power-up spawns once every 15 seconds
  if (args.state.tick_count % 900 == 0) || (args.keyboard.key_down.p && DEV_MODE)

    # Determine a random power-up type
    # Health drops are the most common
    case rand(9)
    when 0..2
      effect = :health
    when 3
      effect = :lifesteal
    when 4
      effect = :speed
    when 5
      effect = :slowdown
    when 6
      effect = :rapid_fire
    when 7
      effect = :minigun
    when 8
      effect = :immunity
    end

    # Spawn from above only, and within screen x bounds
    x, y = [rand(56) + 4, 70]

    args.state.power_ups << {
      x: x, y: y,
      w: 8, h: 8,
      path: "assets/sprites/power-up-#{effect}.png",
      angle: 0,
      angle_anchor_x: 0.5,
      angle_anchor_y: 0.5,
      swaying: :right,
      effect: effect
    }
  end
end

def fire_tank args
  args.state.tanks.each do |tank|
    # Grabbed and falling tanks cannot fire
    return unless tank.grab_state == nil

    # Shoot once every 3 seconds, after moving fully onto the screen
    if args.state.tick_count % 180 == 0 && tank.x >= 0 && tank.x <= 60
      # Add a new bullet to the list of tank bullets.
      args.state.tank_bullets << {
        x:     tank.x + 3,
        y:     tank.y + 7,
        w:     1, h: 3,
        path:  'assets/sprites/tank-bullet.png',
        tile_x: 0, tile_y: 0,
        tile_w: 1, tile_h: 3
      }
      args.outputs.sounds << "assets/audio/sfx/tank-fire.wav"
    end
  end
end

def fire_helo args
  args.state.helos.each do |helo|
    # Grabbed and falling helos cannot fire
    return unless helo.grab_state == nil

    # Shoot once every 3 seconds, after moving fully onto the screen
    if args.state.tick_count % 180 == 0 && helo.x >= 0 && helo.x <= 59
      # Add a new bullet to the list of tank bullets.
      facing_left = helo.flip_horizontally
      args.state.helo_bullets << {
        x:     facing_left ? helo.x : helo.x + 8,
        y:     helo.y,
        w:     1, h: 3,
        path:  'assets/sprites/tank-bullet.png', # TODO helo missile
        tile_x: 0, tile_y: 0,
        tile_w: 1, tile_h: 3,
        angle: facing_left ? 90 : -90
      }
      args.outputs.sounds << "assets/audio/sfx/tank-fire.wav"
    end
  end
end

def animate_tank_bullets args
  # Animate 6 times per second
  return unless args.state.tick_count % 10 == 0

  args.state.tank_bullets.each do |bullet|
    bullet.tile_x = rand(3) # The flame animation is simply randomised, no need to go sequentially
  end
end

def animate_helo_bullets args
  # Animate 6 times per second
  return unless args.state.tick_count % 10 == 0

  args.state.helo_bullets.each do |bullet|
    bullet.tile_x = rand(3) # The flame animation is simply randomised, no need to go sequentially
  end
end

def animate_player_hit args
  if player_is_invulnerable args
    # # Animate 6 times per second
    return unless args.state.tick_count % 10 == 0
    case args.state.player[:a]
    when 255
      args.state.player.a = 140
    when 140
      args.state.player.a = 70
    when 70
      args.state.player.a = 140
    end
  else
    args.state.player.a = 255
    args.state.player.last_hit_at = -Float::INFINITY
  end
end

def draw_explosion args, x, y, scale = 1
  args.state.explosions << {
    x:     x,
    y:     y,
    w:     8 * scale, h: 8 * scale,
    path:  'assets/sprites/explosion.png',
    tile_x: 0, tile_y: 0,
    tile_w: 8, tile_h: 8
  }
  args.outputs.sounds << "assets/audio/sfx/#{scale < 1 ? "explosion-quiet" : "explosion"}.wav"
end

def animate_explosions args
  # Animate ~8 times per second
  return unless args.state.tick_count % 8 == 0

  args.state.explosions.each do |explosion|
    explosion.tile_x += 8 # Move to the next frame in the spritesheet
  end

  # Discard completed explosions
  args.state.explosions.reject! do |explosion|
    explosion.tile_x > 24
  end
end

def fire_player args
  # Reduce the firing cooldown each tick
  args.state.player[:cooldown] -= 1
  # If the player is allowed to fire
  if args.state.player[:cooldown] <= 0
    dx, dy = shoot_directional_vector args # Get the bullet velocity
    return if dx == 0 && dy == 0 # If the velocity is zero, the player doesn't want to fire. Therefore, we just return early.
    # Add a new bullet to the list of player bullets.
    args.state.player_bullets << {
        x:     args.state.player.x + 2 + 4 * dx,
        y:     args.state.player.y + 2 + 4 * dy,
        w:     2, h: 1,
        path:  'assets/sprites/player-bullet.png',
        flip_horizontally: args.state.player.direction > 0,
        vx:    4 * dx + args.state.player[:vx] / 1.5, vy: 4 * dy + args.state.player[:vy] / 1.5, # Factor in a bit of the player's velocity
        kills: 0
    }
    args.outputs.sounds << "assets/audio/sfx/player-fire.wav"
    # Reset the cooldown
    case args.state.player[:active_power_up]
    when :rapid_fire
      cooldown = 0
    when :minigun
      cooldown = 18
    else
      cooldown = 30
    end 
    args.state.player[:cooldown] = cooldown
  end
end

def idle_sprite args
  {
    x: args.state.player.x,
    y: args.state.player.y,
    w: args.state.player.w,
    h: args.state.player.h,
    path: "assets/sprites/player-idle.png",
    flip_horizontally: args.state.player.direction > 0
  }
end

def running_sprite args
  if !args.state.player.started_moving_at
    tile_index = 0
  else
    frame_count = 3
    ticks_per_frame = 4
    repeat = true
    tile_index = args.state
                     .player
                     .started_moving_at
                     .frame_index(frame_count, ticks_per_frame, repeat)
  end

  {
    x: args.state.player.x,
    y: args.state.player.y,
    w: args.state.player.w,
    h: args.state.player.h,
    a: args.state.player.a,
    path: 'assets/sprites/player-fly.png',
    tile_x: 0 + (tile_index * args.state.player.w),
    tile_y: 0,
    tile_w: args.state.player.w,
    tile_h: args.state.player.h,
    flip_horizontally: args.state.player.direction > 0,
  }
end

def animate_power_up_bar args
  time_remaining = remaining_power_up_duration args
  current_width = time_remaining / 25
  if time_remaining > 0
    if (args.state.active_orb == [] && args.state.active_bar == []) || args.state.active_orb[0].path != "assets/sprites/orb-#{args.state.player[:active_power_up]}.png"
      args.state.active_orb = [{
        x: 60, y: 54,
        w: 4, h: 4,
        path: "assets/sprites/orb-#{args.state.player[:active_power_up]}.png",
        angle: 180
      }]
      args.state.active_bar = [{
        x: 60 - current_width, y: 55,
        w: current_width, h: 2,
        path: "assets/sprites/bar-#{args.state.player[:active_power_up]}.png"
      }]
    else 
      args.state.active_bar[0].x = 60 - current_width
      args.state.active_bar[0].w = current_width
    end
  else
    args.state.active_bar.clear
    args.state.active_orb.clear
    args.state.player.power_up_active_at = -Float::INFINITY
    args.state.player.active_power_up = nil
  end
end