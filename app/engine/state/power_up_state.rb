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
  args.state.power_ups.each do |power_up|
    # If the power up hasn't been collected
    if power_up.path != "assets/sprites/power-up-empty.png"
      # Check if power-up and player are within 7 pixels of each other (i.e. overlapping)
      if 49 > (power_up.x - args.state.player.x) ** 2 + (power_up.y - args.state.player.y) ** 2
        # Power-up is touching player. Change its sprite, and activate its effect
        power_up.path = "assets/sprites/power-up-empty.png"
        args.outputs.sounds << "assets/audio/sfx/power-up.wav"
        activate_power_up args, power_up.effect
      end
    end
  end
  args.state.power_ups.reject! do |power_up|
    if power_up.y < -7
      # Power-up is off screen, remove it.
      true
    else
      args.state.player_bullets.any? do |bullet|
        # Check if power-up and bullet are within 4 pixels of each other (i.e. overlapping)
        if 16 > (power_up.x - bullet.x) ** 2 + (power_up.y - bullet.y) ** 2
          # Power-up was shot down. Destroy it
          draw_explosion args, power_up.x, power_up.y - 2
        end
      end
    end
  end
end

# TODO group the ones that are active for 5 secs under one case
def activate_power_up args, effect
  case effect
  when :health
    args.state.player.health += 1
    args.state.player.health = args.state.player.health.clamp(0, 5)
  when :lifesteal
    args.state.player.power_up_active_at = args.state.tick_count
    args.state.player.active_power_up = :lifesteal
  when :speed
    args.state.player.power_up_active_at = args.state.tick_count
    args.state.player.active_power_up = :speed
  when :slowdown
    args.state.player.power_up_active_at = args.state.tick_count
    args.state.player.active_power_up = :slowdown
  when :rapid_fire
    args.state.player.power_up_active_at = args.state.tick_count
    args.state.player.active_power_up = :rapid_fire
  when :minigun
    args.state.player.power_up_active_at = args.state.tick_count
    args.state.player.active_power_up = :minigun
  when :immunity
    args.state.player.power_up_active_at = args.state.tick_count
    args.state.player.active_power_up = :immunity
  else
    # Undefined power up effect type
  end
end