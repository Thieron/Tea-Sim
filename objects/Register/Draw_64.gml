if (!regOpen) exit;

var gw = display_get_gui_width();
var gh = display_get_gui_height();

// Dim background
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(0, 0, gw, gh, false);
draw_set_alpha(1);

// Panel
var pw = 500, ph = 400;
var px = (gw - pw) / 2;
var py = (gh - ph) / 2;
draw_set_color(c_dkgray);
draw_rectangle(px, py, px + pw, py + ph, false);
draw_set_color(c_white);
draw_rectangle(px, py, px + pw, py + ph, true);

draw_set_halign(fa_center);
draw_set_valign(fa_middle);

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

if (regPage == "main") {
    draw_text(px + pw/2, py + 30, "REGISTER");

    // Draw each button, detect hover + click
    var bw = 200, bh = 40, gap = 12;
    var startY = py + 80;
    for (var i = 0; i < array_length(regButtons); i++) {
        var bx = px + (pw - bw)/2;
        var by = startY + i * (bh + gap);

        var hover = (mx >= bx && mx <= bx + bw && my >= by && my <= by + bh);

        draw_set_color(hover ? c_ltgray : c_gray);
        draw_rectangle(bx, by, bx + bw, by + bh, false);
        draw_set_color(c_white);
        draw_rectangle(bx, by, bx + bw, by + bh, true);
        draw_text(bx + bw/2, by + bh/2, regButtons[i].label);

        if (hover && mouse_check_button_pressed(mb_left)) {
            regPage = regButtons[i].page;
        }
    }

    draw_text(px + pw/2, py + ph - 20, "Press ESC to close");

} else {
    draw_text(px + pw/2, py + 30, string_upper(regPage));

    // Back button
    var backW = 100, backH = 30;
    var backX = px + 20;
    var backY = py + ph - backH - 20;
    var backHover = (mx >= backX && mx <= backX + backW && my >= backY && my <= backY + backH);

    draw_set_color(backHover ? c_ltgray : c_gray);
    draw_rectangle(backX, backY, backX + backW, backY + backH, false);
    draw_set_color(c_white);
    draw_rectangle(backX, backY, backX + backW, backY + backH, true);
    draw_set_halign(fa_center);
    draw_text(backX + backW/2, backY + backH/2, "Back");

    if (backHover && mouse_check_button_pressed(mb_left)) {
        regPage = "main";
    }

}

// reset draw state
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);