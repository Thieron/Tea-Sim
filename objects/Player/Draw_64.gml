draw_set_color($0A3313);
draw_set_halign(fa_right);   
draw_set_valign(fa_top);

draw_text(display_get_gui_width() - 10, 10, "Funds: " + string(global.player_funds));

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);