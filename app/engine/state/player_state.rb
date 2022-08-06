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
  dx = 0
  if args.inputs.keyboard.d
    dx += PLAYER_MOVE_SPEED 
    args.state.player.direction = -1
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  if args.inputs.keyboard.a
    dx -= PLAYER_MOVE_SPEED 
    args.state.player.direction = 1
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  dy = 0
  if args.inputs.keyboard.w
    dy += PLAYER_MOVE_SPEED 
    args.state.player.started_moving_at ||= args.state.tick_count
  end
  if args.inputs.keyboard.s
    dy -= PLAYER_MOVE_SPEED 
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
    # Abandoned 4d shooting in favour of shooting based on player direction
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