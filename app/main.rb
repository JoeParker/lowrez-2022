require 'app/lowrez_emulator.rb'
require 'app/renderer.rb'

###################################################################################
# ENTRY POINT
###################################################################################

def tick args
  sprites = []
  labels = []
  mouse = emulate_lowrez_mouse args
  args.state.show_gridlines = false
  game_loop args, sprites, labels, mouse
  render_gridlines_if_needed args
  render_mouse_crosshairs args, mouse
  emulate_lowrez_scene args, sprites, labels, mouse
end

def game_loop args, lowrez_sprites, lowrez_labels, lowrez_mouse
  # args.state.show_gridlines = true
  render_game args, lowrez_sprites
  move_blue_ship args
end