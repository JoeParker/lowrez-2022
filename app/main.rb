###################################################################################
# APPLICATION ENTRY POINT
###################################################################################

require 'app/engine/game_loop.rb'
require 'app/engine/lowrez_emulator.rb'

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
