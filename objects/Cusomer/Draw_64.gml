draw_self();
if (!tea_managed) exit;

// Text above the head. Raise TEXT_SCALE if names look too small.
var TEXT_SCALE = 0.5;
var top = bbox_top - 2;
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);

// Patience bar while they're waiting on you
if (state == "enter" || state == "ordering" || state == "seek_seat" || state == "waiting") {
    var f = clamp(patience / patience_max, 0, 1);
    var w = 24;
    draw_set_colour(c_black);
    draw_rectangle(x - w / 2 - 1, top - 4, x + w / 2 + 1, top, false);
    draw_set_colour(merge_colour(C_BAD, C_ACCENT, f));
    draw_rectangle(x - w / 2, top - 3, x - w / 2 + w * f, top - 1, false);
    top -= 6;
}

// Name
var nm = customer_name;
if (is_regular) nm = "* " + nm;
var col = c_white;
if (tag == "club")   col = C_ACCENT;
if (tag == "family") col = C_GOLD;
draw_set_colour(c_black);
draw_text_transformed(x + 1, top + 1, nm, TEXT_SCALE, TEXT_SCALE, 0);
draw_set_colour(col);
draw_text_transformed(x, top, nm, TEXT_SCALE, TEXT_SCALE, 0);
top -= 10;

// Mood bubble and money pop
if (bubble_timer > 0) {
    draw_set_colour((satisfaction >= 75) ? C_ACCENT : ((satisfaction >= 45) ? C_GOLD : C_BAD));
    draw_text_transformed(x, top, bubble, TEXT_SCALE * 1.4, TEXT_SCALE * 1.4, 0);
    top -= 12;
}
if (money_timer > 0) {
    draw_set_alpha(clamp(money_timer, 0, 1));
    draw_set_colour(C_GOLD);
    draw_text_transformed(x, top - (1.5 - money_timer) * 10, money_text, TEXT_SCALE, TEXT_SCALE, 0);
    draw_set_alpha(1);
}

draw_set_colour(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);