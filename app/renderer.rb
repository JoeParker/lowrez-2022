PLAYER_WIDTH = 8
MOVE_SPEED = 0.1

def render_game args, lowrez_sprites
  args.state.player ||= {
    x: 28, y: 28, 
    w: PLAYER_WIDTH, h: PLAYER_WIDTH, 
    vx: 0, vy: 0, 
    direction: 1,
    started_moving_at: nil,
    health: 10, 
    cooldown: 0, 
    score: 0
  }
  args.state.player[:r] = args.state.player[:g] = args.state.player[:b] = (args.state.player[:health] * 25.5).clamp(0, 255)

  if args.state.player.started_moving_at
    lowrez_sprites << [running_sprite(args)]
  else
    lowrez_sprites << [idle_sprite(args)]
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
    path: 'assets/sprites/player-run.png',
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

  if !args.inputs.keyboard.directional_vector
    args.state.player.started_moving_at = nil
  end

  if dx != 0 && dy != 0
    dx *= 0.7071
    dy *= 0.7071
  end
  [dx, dy]
end