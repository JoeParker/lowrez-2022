def move_blue_ship args
  args.state.blue_ship_location ||= [0, 0]
  if args.keyboard.right
    args.state.blue_ship_location.x += 0.5
  end
  if args.keyboard.left
    args.state.blue_ship_location.x -= 0.5
  end
  if args.keyboard.up
    args.state.blue_ship_location.y += 0.5
  end
  if args.keyboard.down
    args.state.blue_ship_location.y -= 0.5
  end
end

def render_game args, lowrez_sprites
  args.state.blue_ship_location ||= [0, 0]
  lowrez_sprites << [args.state.blue_ship_location.x,
                     args.state.blue_ship_location.y,
                     5,
                     5,
                     'assets/sprites/ship_blue.png']
end