###################################################################################
# ENEMY STATE
###################################################################################

ENEMY_PROJECTILE_SPEED = 0.06
ENEMY_TANK_SPEED = 0.06

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

def kill_enemies args 
  args.state.enemies.reject! do |enemy|
    # Check if enemy and player are within 3 pixels of each other (i.e. overlapping)
    if 9 > (enemy.x - args.state.player.x) ** 2 + (enemy.y - args.state.player.y) ** 2
      # Enemy is touching player. Kill enemy, and reduce player HP by 1.
      damage_player args
    else
      args.state.player_bullets.any? do |bullet|
        # Check if enemy and bullet are within 2 pixels of each other (i.e. overlapping)
        if 4 > (enemy.x - bullet.x) ** 2 + (enemy.y - bullet.y) ** 2

          # If lifesteal power-up is active, restore player health by one for each enemy killed by a bullet after the first enemy, up to a maximum of 5 HP
          args.state.player[:health] += 1 if args.state.player[:active_power_up] == :lifesteal && args.state.player[:health] < 5 && bullet[:kills] > 0

          # Keep track of how many enemies have been killed by this particular bullet
          bullet[:kills] += 1
          # Earn more points by killing multiple enemies with one shot.
          args.state.player[:score]  += bullet[:kills]
        end
      end
    end
  end
end

def move_tanks args
  args.state.tanks.each do |tank|
    # Skip this tank if its grabbed, or falling
    next unless tank.grab_state == nil
    
    # Is the player left or right of the tank?
    move_left = args.state.player[:x] < tank[:x]
    # Move the tank towards the player
    if move_left
      tank.x -= ENEMY_TANK_SPEED
    else
      tank.x += ENEMY_TANK_SPEED
    end
  end
end

def carry_tanks args
  args.state.tanks.each do |tank|
    if tank.grab_state == :grabbed
      tank.x = args.state.player.x
      tank.y = args.state.player.y - 3
      tank.angle = 25 if args.state.player.direction > 0
      tank.angle = -25 if args.state.player.direction < 0
    end
  end
end

def drop_tanks args
  args.state.tanks.each do |tank|
    if tank.grab_state == :falling
      tank.y -= 0.4
      tank.x += args.state.player_dropped_vx
      tank.angle -= 5
      # Despawn tanks at the ground
      args.state.tanks.reject! do |tank|
        tank.y < 0
      end
    end
  end
end

def move_tank_bullets args
  args.state.tank_bullets.each do |bullet|
    # Move the bullets according to the bullet's velocity
    bullet.y += 0.2
  end
  args.state.tank_bullets.reject! do |bullet|
    # Despawn bullets that are outside the screen area
    bullet.x < 0 || bullet.y < 0 || bullet.x > 70 || bullet.y > 70
  end
end

def destroy_tank_bullets args 
  args.state.tank_bullets.reject! do |enemy|
    # Check if bullet and player are within 4 pixels of each other (i.e. overlapping)
    if 16 > (enemy.x - args.state.player.x) ** 2 + (enemy.y - args.state.player.y) ** 2
      # Bullet is touching player. Destroy bullet, and reduce player HP by 1.
      damage_player args
    end
  end
end

def damage_player args
  args.state.player[:health] -= 1
  args.outputs.sounds << "assets/audio/sfx/player-hit.wav"
end