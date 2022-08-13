###################################################################################
# ENEMY STATE
###################################################################################

ENEMY_PROJECTILE_SPEED = 0.06
ENEMY_TANK_SPEED = 0.06
ENEMY_HELO_SPEED = 0.06

def move_enemies args
  args.state.enemies.each do |enemy|
    # Get the angle from the enemy to the player
    theta = Math.atan2(enemy.y - args.state.player.y, enemy.x - args.state.player.x)
    # Convert the angle to a vector pointing at the player
    dx, dy = theta.to_degrees.vector 5
    # Move the enemy towards the player
    adjusted_speed = ENEMY_PROJECTILE_SPEED * (args.state.player[:active_power_up] == :slowdown ? 0.5 : 1)
    enemy.x -= dx * adjusted_speed
    enemy.y -= dy * adjusted_speed

    # Adjust the angle that the missile sprite should aim at the player
    enemy.angle = theta.to_degrees + 90
  end
end

def kill_enemies args 
  args.state.enemies.reject! do |enemy|
    # Check if enemy and player are within 3 pixels of each other (i.e. overlapping)
    if 9 > (enemy.x - args.state.player.x) ** 2 + (enemy.y - args.state.player.y) ** 2
      # Enemy is touching player. Kill enemy, and reduce player HP by 1.
      unless player_is_invulnerable args
        damage_player args
        draw_explosion args, enemy.x, enemy.y # TODO add screen shake or red flash 
      end
      true
    else
      args.state.player_bullets.any? do |bullet|
        # Check if enemy and bullet are within 2 pixels of each other (i.e. overlapping)
        if 4 > (enemy.x - bullet.x) ** 2 + (enemy.y - bullet.y) ** 2
          draw_explosion args, enemy.x, enemy.y, 0.5

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
        if tank.y < 0
          draw_explosion args, tank.x, tank.y - 3
          args.state.player.score += 10
        end
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
      unless player_is_invulnerable args 
        damage_player args
        draw_explosion args, enemy.x, enemy.y
      end
    end
  end
end

def damage_player args, amount = 1
  args.state.player[:health] -= amount
  args.state.player[:last_hit_at] = args.state.tick_count
  args.outputs.sounds << "assets/audio/sfx/player-hit.wav"
end

def move_helos args
  args.state.helos.each do |helo|
    # Skip this helo if its grabbed, or falling
    next unless helo.grab_state == nil

    # First, move the helo onto the screen
    helo.x += 0.1 if helo.x < 1
    helo.x -= 0.1 if helo.x > 55

    # Is the player above or below the helo?
    move_down = args.state.player[:y] < helo[:y]
    # Move the tank towards the player
    if move_down
      helo.y -= ENEMY_HELO_SPEED
    else
      helo.y += ENEMY_HELO_SPEED
    end
  end
end

def move_helo_bullets args
  args.state.helo_bullets.each do |bullet|
    # Move the bullets according to the bullet's velocity
    bullet.x += (bullet.angle < 0 ? 0.2 : -0.2) # Direction depends on helo direction, which we can determine by the sprite angle
  end
  args.state.helo_bullets.reject! do |bullet|
    # Despawn bullets that are outside the screen area
    bullet.x < 0 || bullet.y < 0 || bullet.x > 70 || bullet.y > 70
  end
end

def destroy_helo_bullets args 
  args.state.helo_bullets.reject! do |enemy|
    # Check if bullet and player are within 4 pixels of each other (i.e. overlapping)
    if 16 > (enemy.x - args.state.player.x) ** 2 + (enemy.y - args.state.player.y) ** 2
      # Bullet is touching player. Destroy bullet, and reduce player HP by 1.
      unless player_is_invulnerable args 
        damage_player args
        draw_explosion args, enemy.x, enemy.y
      end
    end
  end
end

def carry_helos args
  args.state.helos.each do |helo|
    if helo.grab_state == :grabbed
      helo.x = args.state.player.x
      helo.y = args.state.player.y - 3
      helo.angle = 25 if helo.flip_horizontally
      helo.angle = -25 if !helo.flip_horizontally
      helo.flip_horizontally = args.state.player.direction > 0
    end
  end
end

def drop_helos args
  args.state.helos.each do |helo|
    if helo.grab_state == :falling
      helo.y -= 0.4
      helo.x += args.state.player_dropped_vx
      helo.angle -= 5
      # Despawn helos at the ground
      args.state.helos.reject! do |helo|
        if helo.y < 0
          draw_explosion args, helo.x, helo.y - 3
          args.state.player.score += 10
        end
      end
    end
  end
end

def move_bombers args
  args.state.bombers.each do |bomber|
    # Bombers move across the x axis in a single direction
    bomber.x += bomber.flip_horizontally ? 0.5 : -0.5
  end
  args.state.bombers.reject! do |bomber|
    # Remove bombers that have fully left the screen
    bomber.x < -20 || bomber.x > 84
  end
end

def move_bombs args
  args.state.bombs.each do |bomb|
    bomb.y -= 0.4
  end
end

def destroy_bombs args 
  args.state.bombs.reject! do |bomb|
    # Check if bomb and player are within 5 pixels of each other (i.e. overlapping)
    if 25 > (bomb.x - args.state.player.x) ** 2 + (bomb.y - args.state.player.y) ** 2
      # Bomb is touching player. Destroy bomb, and reduce player HP by 2
      unless player_is_invulnerable args 
        damage_player args, 2
        draw_explosion args, bomb.x - 3, bomb.y, 1.3
      end
    elsif bomb.y < 0
      # Bomb has hit the ground, destroy it
      draw_explosion args, bomb.x - 3, bomb.y - 3, 1.3
    end
  end
end