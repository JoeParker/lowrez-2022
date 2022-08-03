###################################################################################
# ENEMY PHYSICS
###################################################################################

ENEMY_PROJECTILE_SPEED = 0.06

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