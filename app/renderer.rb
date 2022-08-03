PLAYER_WIDTH = 6
MOVE_SPEED = 0.1

PLAYER_PROJECTILE_SPEED = 0.08
ENEMY_PROJECTILE_SPEED = 0.08

def render_game args, lowrez_sprites
  args.state.background ||= {
    x: 0, y: 0,
    w: 64, h: 64,
    path: "assets/sprites/bg-64.png"
  }
  lowrez_sprites << [args.state.background]

  args.state.player ||= {
    x: 28, y: 28, 
    w: PLAYER_WIDTH, h: PLAYER_WIDTH, 
    vx: 0, vy: 0, 
    direction: 1,
    started_moving_at: 0,#nil, # This would be set to nil initially if we wanted the sprite to start idle
    health: 10, 
    cooldown: 0, 
    score: 0
  }
  args.state.player[:r] = args.state.player[:g] = args.state.player[:b] = (args.state.player[:health] * 25.5).clamp(0, 255)

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

def kill_enemies args 
  args.state.enemies.reject! do |enemy|
    # Check if enemy and player are within 3 pixels of each other (i.e. overlapping)
    if 9 > (enemy.x - args.state.player.x) ** 2 + (enemy.y - args.state.player.y) ** 2
      # Enemy is touching player. Kill enemy, and reduce player HP by 1.
      args.state.player[:health] -= 1
    else
      args.state.player_bullets.any? do |bullet|
        # Check if enemy and bullet are within 2 pixels of each other (i.e. overlapping)
        if 4 > (enemy.x - bullet.x) ** 2 + (enemy.y - bullet.y) ** 2
          # Increase player health by one for each enemy killed by a bullet after the first enemy, up to a maximum of 10 HP
          args.state.player[:health] += 1 if args.state.player[:health] < 10 && bullet[:kills] > 0
          # Keep track of how many enemies have been killed by this particular bullet
          bullet[:kills] += 1
          # Earn more points by killing multiple enemies with one shot.
          args.state.player[:score]  += bullet[:kills]
        end
      end
    end
  end
end

def spawn_enemies args
  # Spawn enemies more frequently as the player's score increases.
  if rand < (100+args.state.player[:score])/(10000 + args.state.player[:score]) || args.state.tick_count.zero?
    theta = rand * Math::PI * 2
    args.state.enemies << {
        x: 32 + Math.cos(theta) * 8, y: 32 + Math.sin(theta) * 8, # TODO calculate random starting point somewhere closely outside the screen bounds
        w: 2, h: 3, 
        path: 'assets/sprites/enemy-missile.png',
        angle: 0
    }
  end
end

def move_enemies args
  args.state.enemies.each do |enemy|
    # Get the angle from the enemy to the player
    theta = Math.atan2(enemy.y - args.state.player.y, enemy.x - args.state.player.x)
    # Convert the angle to a vector pointing at the player
    dx, dy = theta.to_degrees.vector 5
    # Move the enemy towards the player
    enemy.x -= dx * ENEMY_PROJECTILE_SPEED
    enemy.y -= dy * ENEMY_PROJECTILE_SPEED

    # Adjust the angle that the missile sprite should aim at the player
    enemy.angle = theta.to_degrees + 90
  end
end

def move_bullets args
  args.state.player_bullets.each do |bullet|
    # Move the bullets according to the bullet's velocity
    bullet.x += bullet[:vx]
    bullet.y += bullet[:vy]
  end
  args.state.player_bullets.reject! do |bullet|
    # Despawn bullets that are outside the screen area
    bullet.x < 0 || bullet.y < 0 || bullet.x > 70 || bullet.y > 70
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

# Custom function for getting a directional vector just for shooting using the arrow keys
def shoot_directional_vector args
  dx = 0
  # dx += 0.1 if args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_held.right
  # dx -= 0.1 if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_held.left
  dy = 0
  # dy += 0.1 if args.inputs.keyboard.key_down.up || args.inputs.keyboard.key_held.up
  # dy -= 0.1 if args.inputs.keyboard.key_down.down || args.inputs.keyboard.key_held.down

  dx += PLAYER_PROJECTILE_SPEED if args.inputs.keyboard.key_down.space && args.state.player.direction < 0
  dx -= PLAYER_PROJECTILE_SPEED if args.inputs.keyboard.key_down.space && args.state.player.direction > 0

  if dx != 0 && dy != 0
    dx *= 0.7071
    dy *= 0.7071
  end
  [dx, dy]
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
    path: 'assets/sprites/enemy-fly.png',
    tile_x: 0 + (tile_index * args.state.player.w),
    tile_y: 0,
    tile_w: args.state.player.w,
    tile_h: args.state.player.h,
    flip_horizontally: args.state.player.direction > 0,
  }
end

def move_player args
  # Get the currently held direction.
  dx, dy = move_directional_vector args
  # Take the weighted average of the old velocities and the desired velocities. 
  # Since move_directional_vector returns values between -1 and 1, 
  #   and we want to limit the speed to 7.5, we multiply dx and dy by 7.5*0.1 to get 0.75
  args.state.player[:vx] = args.state.player[:vx] * 0.9 + dx * 0.75
  args.state.player[:vy] = args.state.player[:vy] * 0.9 + dy * 0.75
  # Move the player
  args.state.player.x += args.state.player[:vx]
  args.state.player.y += args.state.player[:vy]
  # If the player is about to go out of bounds, put them back in bounds.
  args.state.player.x = args.state.player.x.clamp(0, 64 - PLAYER_WIDTH)
  args.state.player.y = args.state.player.y.clamp(0, 64 - PLAYER_WIDTH)
end

# Custom function for getting a directional vector just for movement using WASD
def move_directional_vector args
  dx = 0
  if args.inputs.keyboard.d
    dx += MOVE_SPEED 
    args.state.player.direction = -1
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  if args.inputs.keyboard.a
    dx -= MOVE_SPEED 
    args.state.player.direction = 1
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  dy = 0
  if args.inputs.keyboard.w
    dy += MOVE_SPEED 
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  if args.inputs.keyboard.s
    dy -= MOVE_SPEED 
    args.state.player.started_moving_at ||= args.state.tick_count
  end

  # Stop the sprite animation when stationary:
  # e.g. for flying animations we don't want this
  #
  # if !args.inputs.keyboard.directional_vector
  #   args.state.player.started_moving_at = nil
  # end

  if dx != 0 && dy != 0
    dx *= 0.7071
    dy *= 0.7071
  end
  [dx, dy]
end