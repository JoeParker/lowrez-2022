def move_blue_ship args
  # args.state.blue_ship_location ||= [0, 0]
  # if args.keyboard.right
  #   args.state.blue_ship_location.x += 0.5
  # end
  # if args.keyboard.left
  #   args.state.blue_ship_location.x -= 0.5
  # end
  # if args.keyboard.up
  #   args.state.blue_ship_location.y += 0.5
  # end
  # if args.keyboard.down
  #   args.state.blue_ship_location.y -= 0.5
  # end
end

def render_game args, lowrez_sprites
  # args.state.blue_ship_location ||= [0, 0]
  # # lowrez_sprites << [args.state.blue_ship_location.x,
  # #                    args.state.blue_ship_location.y,
  # #                    5,
  # #                    5,
  # #                    'assets/sprites/ship_blue.png']
  # lowrez_sprites << {
  #   x: args.state.blue_ship_location.x,
  #                    y: args.state.blue_ship_location.y,
  #                    w: 5,
  #                    h: 5,
  #                    path: 'assets/sprites/ship_blue.png'
  # }

  args.state.player         ||= {x: 0, y: 0, w: 5, h: 5, path: 'assets/sprites/ship_blue.png', vx: 0, vy: 0, health: 10, cooldown: 0, score: 0}
  args.state.player[:r] = args.state.player[:g] = args.state.player[:b] = (args.state.player[:health] * 25.5).clamp(0, 255)
  lowrez_sprites << [args.state.player]
end

def move_player args
  # Get the currently held direction.
  dx, dy                 = move_directional_vector args
  # Take the weighted average of the old velocities and the desired velocities. 
  # Since move_directional_vector returns values between -1 and 1, 
  #   and we want to limit the speed to 7.5, we multiply dx and dy by 7.5*0.1 to get 0.75
  args.state.player[:vx] = args.state.player[:vx] * 0.9 + dx * 0.75
  args.state.player[:vy] = args.state.player[:vy] * 0.9 + dy * 0.75
  # Move the player
  args.state.player.x    += args.state.player[:vx]
  args.state.player.y    += args.state.player[:vy]
  # If the player is about to go out of bounds, put them back in bounds.
  args.state.player.x    = args.state.player.x.clamp(0, 59)
  args.state.player.y    = args.state.player.y.clamp(0, 59)
end

MOVE_SPEED = 0.1

# Custom function for getting a directional vector just for movement using WASD
def move_directional_vector args
  dx = 0
  dx += MOVE_SPEED if args.inputs.keyboard.d
  dx -= MOVE_SPEED if args.inputs.keyboard.a
  dy = 0
  dy += MOVE_SPEED if args.inputs.keyboard.w
  dy -= MOVE_SPEED if args.inputs.keyboard.s
  if dx != 0 && dy != 0
    dx *= 0.7071
    dy *= 0.7071
  end
  [dx, dy]
end