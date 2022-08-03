###################################################################################
# MAIN GAME LOOP
# RUNS 60 TIMES PER SECOND
###################################################################################

require 'app/renderer.rb'

def game_loop args, lowrez_sprites, lowrez_labels, lowrez_mouse
    # args.state.show_gridlines = true
    # lowrez_labels << [0, 0, "#{args.state.tick_count}", 255, 0, 0]
    lowrez_labels << {
        x: 0,
        y: 0,
        text: "#{args.state.tick_count}",
        r: 255,
        g: 0,
        b: 0
    }
    
    render_game args, lowrez_sprites
    move_player args
  end