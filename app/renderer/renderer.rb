###################################################################################
# MANAGES UI AND SPRITE ANIMATIONS
###################################################################################

# Render Constants
SCREEN_WIDTH = 64
PLAYER_WIDTH = 6

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
        vx: 0, vy: 0, 
        direction: 1,
        path: "assets/sprites/player-fly.png",
        angle: 0,
        started_moving_at: 0, # This would be set to nil initially if we wanted the sprite to start idle
        health: 5, 
        cooldown: 0, 
        score: 0
      }
  end
end

def animate_player_death player, time_elapsed
  player.angle -= 1 # TODO: Why doesn't this work?

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

def render_game_over args, lowrez_labels
  return unless args.state.scene == :game_over #&& args.state.player.health <= 0

  args.state.player.time_of_death ||= args.state.tick_count
  args.state.player.started_moving_at = nil

  time_elapsed = args.state.tick_count - args.state.player.time_of_death

  animate_player_death args.state.player, time_elapsed

  case args.state.player.score
  when -(1.0 / 0)..-1
    rank = "How?"
  when 0
    rank = "Embarrassing"
  when 1..9
    rank = "Minion"
  else
    rank = "Legendary"
  end

  if time_elapsed > 45 
    lowrez_labels << { x: 0, y: 20, text: "Score: #{args.state.player.score}", alignment_enum: 2 }
    lowrez_labels << { x: 0, y: 10, text: "Rank: #{rank}", alignment_enum: 2, r: 255, g: 255, b: 255 }
  end

  reset_game args.state.player, args if args.keyboard.key_down.space
end

def reset_game player, args
  player.health = 5
  player.score = 0
  player.x = SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2
  player.y = SCREEN_WIDTH / 2 - PLAYER_WIDTH / 2
  player.vx = 0
  player.vy = 0
  player.direction = 1
  player.time_of_death = nil
  args.state.player.started_moving_at = 0
  args.state.player_bullets.clear
  args.state.enemies.clear
  change_to_scene args, :game 
end

def change_to_scene args, scene
    args.state.scene = scene
    args.state.scene_at = args.state.tick_count
    args.inputs.keyboard.clear
    args.inputs.controller_one.clear
end

def render_ui args, lowrez_labels
  if DISPLAY_TICKS
    lowrez_labels << {
      x: 0,
      y: 0,
      text: "#{args.state.tick_count}",
      r: 255,
      g: 0,
      b: 0
  }
  end

  lowrez_labels << {
    x: 1,
    y: 59,
    text: "#{args.state.player.score}",
    r: 0,
    g: 255,
    b: 0
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

def render_game args, lowrez_sprites
  args.state.show_gridlines = DISPLAY_GRID

  args.state.background ||= {
    x: 0, y: 0,
    w: SCREEN_WIDTH, h: SCREEN_WIDTH,
    path: "assets/sprites/bg-64.png"
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

end

def calculate_spawn_point
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
    x, y = calculate_spawn_point
    args.state.enemies << {
      x: x, y: y,
      w: 2, h: 3, 
      path: 'assets/sprites/enemy-missile.png',
      angle: 0
    }
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
        # r:     0, g: 0, b: 0,
        vx:    4 * dx + args.state.player[:vx] / 1.5, vy: 4 * dy + args.state.player[:vy] / 1.5, # Factor in a bit of the player's velocity
        kills: 0
    }
    args.state.player[:cooldown] = 30 # Reset the cooldown
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
    how_many_frames_in_sprite_sheet = 3
    how_many_ticks_to_hold_each_frame = 4
    should_the_index_repeat = true
    tile_index = args.state
                     .player
                     .started_moving_at
                     .frame_index(how_many_frames_in_sprite_sheet,
                                  how_many_ticks_to_hold_each_frame,
                                  should_the_index_repeat)
  end

  {
    x: args.state.player.x,
    y: args.state.player.y,
    w: args.state.player.w,
    h: args.state.player.h,
    path: 'assets/sprites/player-fly.png',
    tile_x: 0 + (tile_index * args.state.player.w),
    tile_y: 0,
    tile_w: args.state.player.w,
    tile_h: args.state.player.h,
    flip_horizontally: args.state.player.direction > 0,
  }
end