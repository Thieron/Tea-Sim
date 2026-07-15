draw_self();

if (distance_to_object(Player) < 10) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text(x, bbox_top - 4, "Press E to use");

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}