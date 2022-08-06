###################################################################################
# POWER-UP STATE
###################################################################################

def move_power_ups args
  args.state.power_ups.each do |power_up|
    # Parachute animation state
    power_up.swaying = :right if power_up.angle == -90
    power_up.swaying = :left if power_up.angle == 90

    power_up.angle += 1 if power_up[:swaying] == :right
    power_up.angle -= 1 if power_up[:swaying] == :left

    power_up.y -= 0.2
  end
end

def destroy_power_ups args 
  args.state.power_ups.reject! do |power_up|
    # Check if power-up and player are within 7 pixels of each other (i.e. overlapping)
    if 49 > (power_up.x - args.state.player.x) ** 2 + (power_up.y - args.state.player.y) ** 2
      # Power-up is touching player. Remove it, and activate its effect
      activate_power_up args, power_up.effect
    else
      args.state.player_bullets.any? do |bullet|
        # Check if power-up and bullet are within 4 pixels of each other (i.e. overlapping)
        if 16 > (power_up.x - bullet.x) ** 2 + (power_up.y - bullet.y) ** 2
          # Power-up was shot down. Destroy it (TODO: animation)
          true
        end
      end
    end
  end
end

def activate_power_up args, effect
  case effect
  when :health
    args.state.player.health += 1
    args.state.player.health = 5 if args.state.player[:health] > 5
  else
    # Undefined power up effect type
  end
end