###################################################################################
# PLAYER STATE
###################################################################################

PLAYER_MOVE_SPEED = 0.1
PLAYER_PROJECTILE_SPEED = 0.10

def move_player args
  # Get the currently held direction.
  dx, dy = move_directional_vector args
  # Take the weighted average of the old velocities and the desired velocities. 
  # Since move_directional_vector returns values between -1 and 1, 
  # we can limit the speed here.
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
  adjusted_speed = PLAYER_MOVE_SPEED * (args.state.player[:active_power_up] == :speed ? 1.4 : 1)
  dx = 0
  if args.inputs.keyboard.d
    dx += adjusted_speed 
    args.state.player.direction = -1
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  if args.inputs.keyboard.a
    dx -= adjusted_speed 
    args.state.player.direction = 1
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  dy = 0
  if args.inputs.keyboard.w
    dy += adjusted_speed 
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  if args.inputs.keyboard.s
    dy -= adjusted_speed 
    args.state.player.started_moving_at ||= args.state.tick_count
  end

  # Stop the sprite animation when stationary:
  # (e.g. for flying animations we don't want this, so leave it commented)
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

# Custom function for getting a directional vector just for shooting
def shoot_directional_vector args
    dx = 0
    dy = 0

    # Minigun power-up allows player to shoot by holding space
    if args.state.player[:active_power_up] == :minigun
      dx += PLAYER_PROJECTILE_SPEED if args.inputs.keyboard.key_held.space && args.state.player.direction < 0
      dx -= PLAYER_PROJECTILE_SPEED if args.inputs.keyboard.key_held.space && args.state.player.direction > 0
    else
      dx += PLAYER_PROJECTILE_SPEED if args.inputs.keyboard.key_down.space && args.state.player.direction < 0
      dx -= PLAYER_PROJECTILE_SPEED if args.inputs.keyboard.key_down.space && args.state.player.direction > 0
    end

    if dx != 0 && dy != 0
      dx *= 0.7071
      dy *= 0.7071
    end
    [dx, dy]
  end


def grab_attack_player args
  # The player can only grab one enemy at a time
  return if args.state.player.grabbing

  # 1. Tanks
  args.state.tanks.each do |tank|
    # Check if player and tank are within 4 pixels of each other (i.e. overlapping)
    if 16 > (args.state.player.x - tank.x) ** 2 + (args.state.player.y - tank.y) ** 2
      args.state.player.grabbing = true
      tank.grab_state = :grabbed
    end 
  end
end

def drop_attack_player args
  return unless args.state.player.grabbing

    # Find the currently grabbed enemy
    args.state.tanks.each do |tank|
      
      if args.keyboard.key_down.space || args.keyboard.key_held.space
        # Set the tank to falling
        tank.grab_state = :falling if tank.grab_state == :grabbed
        args.state.player_dropped_vx = args.state.player[:vx]
        
        # The player is now free to grab some more stuff
        args.state.player.grabbing = false
      end
  end
end

def player_is_invulnerable args
  # Player is invulnerable for 1 second after being hit
  (args.state.player[:last_hit_at] + 60 >= args.state.tick_count) ||
  # or while the immunity power up is active
  (args.state.player[:active_power_up] == :immunity)
end

def remaining_power_up_duration args
  # Player is powered up for 10 seconds after collecting a power-up
  args.state.player[:power_up_active_at] + 600 - args.state.tick_count
end