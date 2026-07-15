draw_set_color($0A3313);
draw_set_halign(fa_right);   
draw_set_valign(fa_top);

draw_text(display_get_gui_width() - 10, 10, "Funds: " + string(global.player_funds));

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (invOpen) {
    var panel_w = 300;
    var panel_h = 200;
    var px = (display_get_gui_width()  - panel_w) / 2;
    var py = (display_get_gui_height() - panel_h) / 2;

    // Dim the background
    draw_set_color(c_black);
    draw_set_alpha(0.6);
    draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
    draw_set_alpha(1);

    // Panel
    draw_set_color(c_dkgray);
    draw_rectangle(px, py, px + panel_w, py + panel_h, false);
    draw_set_color(c_white);
    draw_rectangle(px, py, px + panel_w, py + panel_h, true);   // border

    // Header
    draw_set_halign(fa_center);
    draw_text(px + panel_w / 2, py + 10, "INVENTORY");
    draw_text(px + panel_w / 2, py + 30, "Held: " + string(curInv) + " / " + string(__invMax));

    // List each item in inv[]
	for (var i = 0; i < array_length(inv); i++) {
	    var item = inv[i];
	    draw_text(px + 40, py + 60 + (i * 20), item.name + ": " + string(item.qty));
	}
    // reset
    draw_set_halign(fa_left);
    draw_set_color(c_white);
    draw_set_alpha(1);
}