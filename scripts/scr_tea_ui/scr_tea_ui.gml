// =====================================================================
//  TEA SIM - interface (drawn in obj_game's Draw GUI event)
//  Immediate-mode: every button is drawn and checked in the same call.
//  Layer 0 = HUD, layer 1 = whichever window (modal) is open.
// =====================================================================

// ---------- primitives ----------
function ui_rect(_x1, _y1, _x2, _y2, _col, _alpha = 1) {
    draw_set_alpha(_alpha);
    draw_set_colour(_col);
    draw_rectangle(_x1, _y1, _x2, _y2, false);
    draw_set_alpha(1);
}

function ui_text(_x, _y, _s, _col, _ha = fa_left) {
    draw_set_halign(_ha);
    draw_set_colour(_col);
    draw_text(_x, _y, _s);
    draw_set_halign(fa_left);
}

function ui_text_ext(_x, _y, _s, _col, _w) {
    draw_set_colour(_col);
    draw_text_ext(_x, _y, _s, -1, _w);
}

function ui_text_scaled(_x, _y, _s, _col, _sc) {
    draw_set_colour(_col);
    draw_text_transformed(_x, _y, _s, _sc, _sc, 0);
}

function ui_bar(_x, _y, _w, _h, _f, _col) {
    ui_rect(_x, _y, _x + _w, _y + _h, make_color_rgb(20, 18, 16));
    _f = clamp(_f, 0, 1);
    if (_f > 0) ui_rect(_x, _y, _x + _w * _f, _y + _h, _col);
}

function ui_hover(_x1, _y1, _x2, _y2) {
    return point_in_rectangle(global.ui_mx, global.ui_my, _x1, _y1, _x2, _y2);
}

function ui_button(_x1, _y1, _x2, _y2, _label, _enabled = true, _layer = 0, _col = C_PANEL2, _ha = fa_center) {
    var active = _enabled && (_layer == global.ui_active_layer);
    var hover = active && ui_hover(_x1, _y1, _x2, _y2);
    var fill = _enabled ? (hover ? merge_colour(_col, c_white, 0.15) : _col) : make_color_rgb(54, 48, 42);
    draw_set_colour(fill);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, false);
    draw_set_colour(hover ? C_GOLD : C_LINE);
    draw_roundrect_ext(_x1, _y1, _x2, _y2, 8, 8, true);
    draw_set_valign(fa_middle);
    var tx = (_ha == fa_center) ? (_x1 + _x2) / 2 : _x1 + 14;
    ui_text(tx, (_y1 + _y2) / 2, _label, _enabled ? C_TEXT : C_MUTED, _ha);
    draw_set_valign(fa_top);
    if (hover && global.ui_click) {
        global.ui_click = false;
        return true;
    }
    return false;
}

function ui_window(_w, _h, _title, _closable) {
    var x1 = (TEA_GUI_W - _w) div 2;
    var y1 = (TEA_GUI_H - _h) div 2;
    ui_rect(x1, y1, x1 + _w, y1 + _h, C_PANEL);
    draw_set_colour(C_GOLD);
    draw_rectangle(x1, y1, x1 + _w, y1 + _h, true);
    ui_text_scaled(x1 + 24, y1 + 18, _title, C_GOLD, 1.5);
    if (_closable && ui_button(x1 + _w - 44, y1 + 12, x1 + _w - 12, y1 + 44, "X", true, 1)) global.modal = "";
    return [x1, y1];
}

function tea_truncate(_s, _w) {
    if (string_width(_s) <= _w) return _s;
    while (string_length(_s) > 1 && string_width(_s + "...") > _w) _s = string_delete(_s, string_length(_s), 1);
    return _s + "...";
}


// ---------- entry point ----------
function tea_draw_ui() {
    global.ui_mx = device_mouse_x_to_gui(0);
    global.ui_my = device_mouse_y_to_gui(0);
    global.ui_click = mouse_check_button_pressed(mb_left);
    global.ui_active_layer = (global.modal == "") ? 0 : 1;
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(1);

    tea_draw_topbar();
    tea_draw_orders_panel();
    tea_draw_bottombar();
    tea_draw_toasts();

    if (global.paused && global.modal == "") {
        ui_rect(TEA_GUI_W / 2 - 150, 60, TEA_GUI_W / 2 + 150, 96, C_PANEL, 0.9);
        ui_text(TEA_GUI_W / 2, 70, "PAUSED - press Space", C_GOLD, fa_center);
    }
    if (global.modal != "") tea_draw_modal();

    draw_set_colour(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}


// ---------- HUD ----------
function tea_draw_topbar() {
    ui_rect(0, 0, TEA_GUI_W, 44, C_PANEL, 0.95);
    ui_text(16, 14, "Day " + string(global.day) + "  " + tea_weekday_name(global.day), C_TEXT);
    var ph = (global.phase == "open") ? "OPEN" : ((global.phase == "closing") ? "CLOSING" : "CLOSED");
    ui_text(140, 14, tea_fmt_time(global.minute) + "  " + ph, (global.phase == "open") ? C_ACCENT : C_MUTED);
    ui_text(320, 14, tea_fmt_money(global.money), (global.money < 0) ? C_BAD : C_GOLD);

    ui_text(440, 14, "Rep", C_MUTED);
    ui_bar(476, 17, 110, 12, global.reputation / 100, C_ACCENT);
    ui_text(594, 14, string(floor(global.reputation)), C_TEXT);

    var fs = "Focus: none (open Focus Paths)";
    if (global.focus != "") {
        var p = tea_get_path(global.focus);
        var nx = tea_next_perk(p);
        fs = "Focus: " + p.name + "  " + string(p.xp) + (is_undefined(nx) ? " XP (complete)" : " / " + string(nx.xp) + " XP");
    }
    ui_text(640, 14, fs, C_TEXT);

    var bx = TEA_GUI_W - 236;
    if (ui_button(bx, 7, bx + 40, 37, "II", true, 0, global.paused ? C_ACCENT : C_PANEL2)) global.paused = !global.paused;
    for (var i = 1; i <= 3; i++) {
        var x1 = bx + 44 * i;
        var on = (!global.paused && global.time_scale == i);
        if (ui_button(x1, 7, x1 + 40, 37, string(i) + "x", true, 0, on ? C_ACCENT : C_PANEL2)) { global.time_scale = i; global.paused = false; }
    }
    if (ui_button(TEA_GUI_W - 52, 7, TEA_GUI_W - 12, 37, "?", true, 0)) global.modal = "help";
}

function tea_draw_bottombar() {
    var y1 = TEA_GUI_H - 48;
    ui_rect(0, y1, TEA_GUI_W, TEA_GUI_H, C_PANEL, 0.95);
    var labels = ["Menu & Prices", "Upgrades & Decor", "Staff", "Focus Paths", "Clubs"];
    var keys = ["menu", "upgrades", "staff", "focus", "clubs"];
    for (var i = 0; i < 5; i++) {
        var x1 = 12 + i * 172;
        if (ui_button(x1, y1 + 8, x1 + 164, y1 + 40, labels[i], true, 0)) global.modal = keys[i];
    }
    ui_text(TEA_GUI_W - 12, y1 + 16, "Space: pause   1/2/3: speed   E: take / brew", C_MUTED, fa_right);
}

function tea_draw_orders_panel() {
    var x1 = TEA_GUI_W - 300, y1 = 52, x2 = TEA_GUI_W - 8, y2 = TEA_GUI_H - 56;
    ui_rect(x1, y1, x2, y2, C_PANEL, 0.92);
    var n = array_length(global.orders);
    ui_text(x1 + 12, y1 + 10, "Orders (" + string(n) + ")", C_GOLD);
    var me = "You: free";
    if (!is_undefined(global.player_task)) me = tea_player_at_station() ? "You: brewing (fast)" : "You: brewing";
    ui_text(x2 - 12, y1 + 10, me, C_MUTED, fa_right);

    var yy = y1 + 36;
    for (var i = 0; i < n; i++) {
        if (yy + 62 > y2 - 8) {
            ui_text(x1 + 12, yy, "+" + string(n - i) + " more waiting...", C_MUTED);
            break;
        }
        tea_draw_ticket(global.orders[i], x1 + 8, yy, x2 - 8, yy + 60);
        yy += 66;
    }
    if (n == 0) {
        var msg = (global.phase == "open") ? "No orders right now. Customers line up at the register." : "All quiet.";
        ui_text_ext(x1 + 12, yy, msg, C_MUTED, x2 - x1 - 24);
    }
}

function tea_draw_ticket(_o, _x1, _y1, _x2, _y2) {
    ui_rect(_x1, _y1, _x2, _y2, C_PANEL2);
    var c = _o.cust;
    var nm = _o.name;
    if (instance_exists(c)) {
        var f = clamp(c.patience / c.patience_max, 0, 1);
        ui_rect(_x1, _y1, _x1 + 4, _y2, merge_colour(C_BAD, C_ACCENT, f));
        if (c.is_regular) nm += " (regular)";
        else if (c.tag == "club") nm += " (club)";
        else if (c.tag == "family") nm += " (family)";
    }
    ui_text(_x1 + 12, _y1 + 6, tea_truncate(nm, _x2 - _x1 - 96), C_TEXT);

    var s = "";
    for (var i = 0; i < array_length(_o.items); i++) s += ((i > 0) ? ", " : "") + _o.items[i].name;
    ui_text(_x1 + 12, _y1 + 24, tea_truncate(s, _x2 - _x1 - 24), C_MUTED);

    var bx1 = _x2 - 74, by1 = _y1 + 6, bx2 = _x2 - 8, by2 = _y1 + 26;
    if (_o.state == "await_take") {
        ui_text(_x1 + 12, _y1 + 42, (_o.taker == "staff") ? "Front of house is taking it..." : "Waiting at the register", (_o.taker == "staff") ? C_MUTED : C_GOLD);
        if (ui_button(bx1, by1, bx2, by2, "Take", true, 0, C_ACCENT)) tea_take_order(_o);
    } else if (_o.state == "queued") {
        ui_text(_x1 + 12, _y1 + 42, "Ready to brew", C_MUTED);
        if (ui_button(bx1, by1, bx2, by2, "Brew", is_undefined(global.player_task), 0, C_ACCENT)) tea_player_brew(_o);
    } else if (_o.state == "brewing") {
        var who = (_o.worker == "player") ? "You" : _o.worker;
        ui_text(_x2 - 10, _y1 + 6, who, C_GOLD, fa_right);
        ui_bar(_x1 + 12, _y1 + 46, _x2 - _x1 - 24, 8, _o.progress / _o.prep_total, C_GOLD);
    }
}

function tea_draw_toasts() {
    var rdt = delta_time / 1000000;
    var yy = TEA_GUI_H - 90;
    for (var i = array_length(global.toasts) - 1; i >= 0; i--) {
        global.toasts[i].t -= rdt;
        if (global.toasts[i].t <= 0) array_delete(global.toasts, i, 1);
    }
    for (var j = 0; j < array_length(global.toasts); j++) {
        var t = global.toasts[j];
        var a = clamp(t.t, 0, 1);
        var w = string_width(t.text) + 24;
        draw_set_alpha(0.85 * a);
        draw_set_colour(C_PANEL);
        draw_rectangle(12, yy, 12 + w, yy + 26, false);
        draw_set_alpha(a);
        draw_set_colour(t.col);
        draw_rectangle(12, yy, 15, yy + 26, false);
        draw_text(24, yy + 5, t.text);
        draw_set_alpha(1);
        yy -= 32;
    }
}


// ---------- windows ----------
function tea_draw_modal() {
    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, TEA_GUI_W, TEA_GUI_H, false);
    draw_set_alpha(1);
    switch (global.modal) {
        case "event":    tea_modal_event();    break;
        case "menu":     tea_modal_menu();     break;
        case "upgrades": tea_modal_upgrades(); break;
        case "staff":    tea_modal_staff();    break;
        case "focus":    tea_modal_focus();    break;
        case "clubs":    tea_modal_clubs();    break;
        case "report":   tea_modal_report();   break;
        case "help":     tea_modal_help();     break;
        default: global.modal = ""; break;
    }
}

function tea_modal_event() {
    var e = global.current_event;
    if (is_undefined(e)) { global.modal = ""; return; }
    var w = 780;
    var tw = w - 48;
    var th = string_height_ext(e.text, -1, tw);
    var nopt = array_length(e.options);
    var h = 72 + th + 24 + nopt * 52 + 12;
    var p = ui_window(w, h, e.title, false);
    var x1 = p[0], y1 = p[1];
    ui_text_ext(x1 + 24, y1 + 64, e.text, C_TEXT, tw);
    var yy = y1 + 64 + th + 24;
    for (var i = 0; i < nopt; i++) {
        var op = e.options[i];
        var cost = variable_struct_exists(op, "cost") ? op.cost : 0;
        var ok = (cost <= 0) || (global.money >= cost);
        var clicked = ui_button(x1 + 24, yy, x1 + w - 24, yy + 44, op.text, ok, 1, C_PANEL2, fa_left);
        if (op.hint != "") {
            draw_set_valign(fa_middle);
            ui_text(x1 + w - 38, yy + 22, ok ? op.hint : "Can't afford", ok ? C_GOLD : C_BAD, fa_right);
            draw_set_valign(fa_top);
        }
        if (clicked) {
            global.modal = "";
            global.current_event = undefined;
            op.fn();
            break;
        }
        yy += 52;
    }
}

function tea_modal_menu() {
    var w = 880, h = 600;
    var p = ui_window(w, h, "Menu & Prices", true);
    var x1 = p[0], y1 = p[1];

    ui_text(x1 + 24, y1 + 66, "Pricing:", C_TEXT);
    var names = ["Cheap (-20%)", "Fair", "Premium (+30%)"];
    var desc = ["More customers and happier ones, thinner margins.", "Balanced.", "Fewer, slightly grumpier customers. Fat margins."];
    for (var i = 0; i < 3; i++) {
        var bx = x1 + 100 + i * 150;
        if (ui_button(bx, y1 + 58, bx + 140, y1 + 86, names[i], true, 1, (global.price_mode == i) ? C_ACCENT : C_PANEL2)) global.price_mode = i;
    }
    ui_text(x1 + 560, y1 + 66, desc[global.price_mode], C_MUTED);

    var hy = y1 + 110;
    ui_text(x1 + 24,  hy, "Item", C_GOLD);
    ui_text(x1 + 300, hy, "Type", C_GOLD);
    ui_text(x1 + 400, hy, "Sells for", C_GOLD);
    ui_text(x1 + 500, hy, "Costs you", C_GOLD);
    ui_text(x1 + 620, hy, "Status", C_GOLD);

    var yy = hy + 26;
    for (var j = 0; j < array_length(global.menu_items); j++) {
        var it = global.menu_items[j];
        var sell = it.owned && tea_req_met(it.req);
        var col = sell ? C_TEXT : C_MUTED;
        ui_text(x1 + 24,  yy + 3, it.name, col);
        ui_text(x1 + 300, yy + 3, it.kind, col);
        ui_text(x1 + 400, yy + 3, tea_fmt_cents(tea_item_price(it)), col);
        ui_text(x1 + 500, yy + 3, tea_fmt_cents(it.cost * tea_supply_mult()), col);
        if (sell) {
            ui_text(x1 + 620, yy + 3, "On the menu", C_ACCENT);
        } else if (!tea_req_met(it.req)) {
            ui_text(x1 + 620, yy + 3, "Needs " + tea_req_label(it.req), C_MUTED);
        } else {
            if (ui_button(x1 + 620, yy, x1 + 780, yy + 22, "Learn  " + tea_fmt_money(it.buy), global.money >= it.buy, 1)) {
                global.money -= it.buy;
                it.owned = true;
                tea_toast(it.name + " added to the menu!", C_ACCENT);
                if (it.kind == "tea" && it.req != "") tea_add_xp("innovation", 15);
            }
        }
        yy += 27;
    }
}

function tea_modal_upgrades() {
    var w = 900, h = 590;
    var p = ui_window(w, h, "Upgrades & Decor", true);
    var x1 = p[0], y1 = p[1];

    // --- shop upgrades ---
    ui_text(x1 + 24, y1 + 66, "Shop upgrades", C_GOLD);
    var ups = [
        { key: "kitchen",     name: "Kitchen Add-on",   cost: 800,  req: "",          desc: "A small kitchen in the back. Unlocks scones, sandwiches and cake." },
        { key: "coffee",      name: "Espresso Machine", cost: 600,  req: "",          desc: "Start serving coffee: espresso, oat lattes and pour-overs." },
        { key: "second_shop", name: "Second Shop",      cost: 3000, req: "exp_major", desc: "A second location in the next town. Earns $150 + $4 x reputation every night." }
    ];
    var yy = y1 + 94;
    for (var i = 0; i < 3; i++) {
        var u = ups[i];
        ui_rect(x1 + 24, yy, x1 + 430, yy + 128, C_PANEL2);
        ui_text(x1 + 36, yy + 10, u.name, C_TEXT);
        ui_text_ext(x1 + 36, yy + 32, u.desc, C_MUTED, 380);
        var owned = global.upgrades[$ u.key];
        if (owned) {
            ui_text(x1 + 36, yy + 98, "Owned", C_ACCENT);
        } else if (!tea_req_met(u.req)) {
            ui_text(x1 + 36, yy + 98, "Needs " + tea_req_label(u.req), C_MUTED);
        } else if (ui_button(x1 + 36, yy + 90, x1 + 216, yy + 118, "Buy  " + tea_fmt_money(u.cost), global.money >= u.cost, 1, C_ACCENT)) {
            global.money -= u.cost;
            global.upgrades[$ u.key] = true;
            tea_refresh_menu();
            tea_toast(u.name + " installed!", C_ACCENT);
            if (u.key == "second_shop") tea_queue_message("Two Shops", "You hang a second sign, painted to match the first. Your father never dreamed this big. Or maybe he did and never said.\n\nThe second shop now earns money every night, based on your reputation.");
        }
        yy += 140;
    }

    // --- decor ---
    var dx = x1 + 460;
    ui_text(dx, y1 + 66, "Decor   (ambience: " + string(tea_ambience()) + ")", C_GOLD);
    ui_text_ext(dx, y1 + 88, "Ambience brings in more customers, keeps them patient, and makes them happier.", C_MUTED, 410);
    var dy = y1 + 130;
    for (var j = 0; j < array_length(global.decor); j++) {
        var d = global.decor[j];
        ui_rect(dx, dy, dx + 416, dy + 64, C_PANEL2);
        ui_text(dx + 12, dy + 10, d.name, C_TEXT);
        ui_text(dx + 12, dy + 34, "+" + string(d.amb) + " ambience", C_MUTED);
        if (d.owned) {
            ui_text(dx + 400, dy + 22, "Owned", C_ACCENT, fa_right);
        } else if (!tea_req_met(d.req)) {
            ui_text(dx + 400, dy + 22, "Needs " + tea_req_label(d.req), C_MUTED, fa_right);
        } else if (ui_button(dx + 270, dy + 16, dx + 404, dy + 48, "Buy  " + tea_fmt_money(d.cost), global.money >= d.cost, 1, C_ACCENT)) {
            global.money -= d.cost;
            d.owned = true;
            tea_toast(d.name + " makes the place feel special.", C_ACCENT);
            if (d.req != "") tea_add_xp("innovation", 20);
        }
        dy += 74;
    }
}

function tea_modal_staff() {
    var w = 900, h = 600;
    var p = ui_window(w, h, "Staff", true);
    var x1 = p[0], y1 = p[1];
    var roles = ["front", "back", "manager"];

    for (var i = 0; i < 3; i++) {
        var rk = roles[i];
        var r = global.staff_roles[$ rk];
        var cx = x1 + 24 + i * 288;
        ui_rect(cx, y1 + 64, cx + 274, y1 + 254, C_PANEL2);
        ui_text(cx + 12, y1 + 74, r.name, C_TEXT);
        ui_text(cx + 12, y1 + 96, tea_fmt_money(tea_wage(rk)) + " / day", C_GOLD);
        ui_text_ext(cx + 12, y1 + 120, r.desc, C_MUTED, 250);
        var cnt = tea_staff_count(rk);
        ui_text(cx + 12, y1 + 222, string(cnt) + " / " + string(r.cap), C_TEXT);
        var can = cnt < r.cap && global.money >= tea_wage(rk);
        if (ui_button(cx + 120, y1 + 214, cx + 262, y1 + 244, "Hire", can, 1, C_ACCENT)) tea_hire(rk);
    }
    ui_text(x1 + 24, y1 + 264, "Hiring costs one day's wage up front. Wages are paid every night.", C_MUTED);

    var total = 0;
    for (var t = 0; t < array_length(global.staff); t++) total += tea_wage(global.staff[t].role);
    ui_text(x1 + 24, y1 + 296, "Your team   (wages: " + tea_fmt_money(total) + " / day)", C_GOLD);

    var yy = y1 + 324;
    if (array_length(global.staff) == 0) ui_text(x1 + 24, yy, "Just you, for now.", C_MUTED);
    for (var j = 0; j < array_length(global.staff); j++) {
        var s = global.staff[j];
        var act = "";
        if (s.role == "front")   act = is_undefined(s.task) ? "Idle at the register" : "Taking " + s.task.name + "'s order";
        if (s.role == "back")    act = is_undefined(s.task) ? "Waiting for orders" : "Brewing for " + s.task.name;
        if (s.role == "manager") act = "Keeping everything running";
        ui_rect(x1 + 24, yy, x1 + w - 24, yy + 30, C_PANEL2);
        ui_text(x1 + 36, yy + 7, s.name, C_TEXT);
        ui_text(x1 + 160, yy + 7, global.staff_roles[$ s.role].name, C_MUTED);
        ui_text(x1 + 360, yy + 7, act, C_MUTED);
        if (ui_button(x1 + w - 110, yy + 3, x1 + w - 32, yy + 27, "Let go", true, 1)) { tea_fire(j); break; }
        yy += 36;
    }
}

function tea_modal_focus() {
    var w = 1000, h = 640;
    var p = ui_window(w, h, "Focus Paths", true);
    var x1 = p[0], y1 = p[1];
    ui_text(x1 + 260, y1 + 26, "Your focus earns " + string(TEA_PASSIVE_XP) + " XP every night, plus XP from happy customers and events.", C_MUTED);

    for (var i = 0; i < array_length(global.paths); i++) {
        var pa = global.paths[i];
        var cx = x1 + 24 + i * 324;
        var cw = 304;
        var is_focus = (global.focus == pa.key);
        ui_rect(cx, y1 + 60, cx + cw, y1 + 560, C_PANEL2);
        if (is_focus) { draw_set_colour(pa.col); draw_rectangle(cx, y1 + 60, cx + cw, y1 + 560, true); }
        ui_text_scaled(cx + 12, y1 + 70, pa.name, pa.col, 1.3);
        ui_text_ext(cx + 12, y1 + 100, pa.blurb, C_MUTED, cw - 24);

        var nx = tea_next_perk(pa);
        var goal = is_undefined(nx) ? pa.perks[2].xp : nx.xp;
        ui_bar(cx + 12, y1 + 146, cw - 24, 10, pa.xp / goal, pa.col);
        ui_text(cx + 12, y1 + 160, string(pa.xp) + " XP" + (is_undefined(nx) ? "  (all perks unlocked)" : "  /  next at " + string(nx.xp)), C_TEXT);

        var py = y1 + 188;
        for (var k = 0; k < array_length(pa.perks); k++) {
            var pk = pa.perks[k];
            var have = tea_has_perk(pk.key);
            ui_rect(cx + 8, py, cx + cw - 8, py + 104, have ? merge_colour(C_PANEL2, pa.col, 0.25) : C_PANEL);
            var tag = have ? "[UNLOCKED] " : "[" + string(pk.xp) + " XP] ";
            ui_text(cx + 16, py + 8, tag + pk.name, have ? C_TEXT : C_MUTED);
            ui_text_ext(cx + 16, py + 30, pk.desc, have ? C_TEXT : C_MUTED, cw - 40);
            py += 112;
        }
        if (ui_button(cx + 12, y1 + 520, cx + cw - 12, y1 + 550, is_focus ? "Current focus" : "Set as focus", !is_focus, 1, C_ACCENT)) {
            global.focus = pa.key;
            tea_toast("Focus set to " + pa.name + ".", pa.col);
        }
    }

    // the goal
    var major = tea_has_perk("exp_major") || tea_has_perk("com_major") || tea_has_perk("inn_major");
    var g = "Your father's wish, a shop you're content with:   Reputation " + string(floor(global.reputation)) + "/" + string(TEA_GOAL_REP)
          + "    Savings " + tea_fmt_money(global.money) + "/" + tea_fmt_money(TEA_GOAL_MONEY)
          + "    Major perk: " + (major ? "yes" : "not yet");
    ui_text(x1 + 24, y1 + 590, g, global.content_reached ? C_ACCENT : C_GOLD);
}

function tea_modal_clubs() {
    var w = 720, h = 500;
    var p = ui_window(w, h, "Clubs", true);
    var x1 = p[0], y1 = p[1];
    if (!tea_has_perk("com_major")) {
        ui_text_ext(x1 + 24, y1 + 70, "Clubs unlock with the Community major perk (500 Community XP).\n\nOnce unlocked, each club you found meets here once a week at 5 PM, bringing a group of members, $60 in dues and a little reputation.", C_MUTED, w - 48);
        return;
    }
    var all_clubs = ["Book Club", "Mahjong Night", "Knitting Circle", "Poetry Open Mic", "Chess Club"];
    ui_text(x1 + 24, y1 + 66, "Your clubs (" + string(array_length(global.clubs)) + " / 3)", C_GOLD);
    var yy = y1 + 92;
    var days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    for (var i = 0; i < array_length(global.clubs); i++) {
        var c = global.clubs[i];
        ui_rect(x1 + 24, yy, x1 + w - 24, yy + 30, C_PANEL2);
        ui_text(x1 + 36, yy + 7, c.name, C_TEXT);
        ui_text(x1 + w - 36, yy + 7, "Meets " + days[c.weekday] + "s at 5 PM", C_MUTED, fa_right);
        yy += 36;
    }
    yy += 16;
    ui_text(x1 + 24, yy, "Found a new club ($250)", C_GOLD);
    yy += 26;
    for (var j = 0; j < array_length(all_clubs); j++) {
        var nm = all_clubs[j];
        var found = false;
        for (var k = 0; k < array_length(global.clubs); k++) if (global.clubs[k].name == nm) found = true;
        if (found) continue;
        var ok = array_length(global.clubs) < 3 && global.money >= 250;
        if (ui_button(x1 + 24, yy, x1 + 300, yy + 30, nm, ok, 1, C_ACCENT)) {
            global.money -= 250;
            var wd = (tea_weekday(global.day) + 1 + array_length(global.clubs) * 2) mod 7;
            array_push(global.clubs, { name: nm, weekday: wd });
            tea_add_rep(2);
            tea_add_xp("community", 30);
            tea_toast("The " + nm + " is born! First meeting on " + days[wd] + ".", C_ACCENT);
        }
        yy += 36;
    }
}

function tea_modal_report() {
    var r = global.report;
    if (is_undefined(r)) { global.modal = ""; return; }
    var w = 540, h = 560;
    var p = ui_window(w, h, "End of Day " + string(r.day), false);
    var x1 = p[0], y1 = p[1];
    var lx = x1 + 32, rx = x1 + w - 32;
    var yy = y1 + 70;

    ui_text(lx, yy, "Customers served", C_TEXT);    ui_text(rx, yy, string(r.served), C_TEXT, fa_right); yy += 24;
    ui_text(lx, yy, "Walked out", C_TEXT);          ui_text(rx, yy, string(r.angry), (r.angry > 0) ? C_BAD : C_TEXT, fa_right); yy += 24;
    ui_text(lx, yy, "Average satisfaction", C_TEXT); ui_text(rx, yy, string(round(r.avg_sat)) + "%", C_TEXT, fa_right); yy += 36;

    var rows = [
        ["Sales", r.revenue], ["Tips", r.tips], ["Supplies", -r.supplies],
        ["Wages", -r.wages], ["Rent", -r.rent], ["Second shop", r.shop2], ["Events & purchases", r.other]
    ];
    for (var i = 0; i < array_length(rows); i++) {
        var v = rows[i][1];
        ui_text(lx, yy, rows[i][0], C_MUTED);
        ui_text(rx, yy, ((v >= 0) ? "+" : "") + tea_fmt_money(v), (v >= 0) ? C_TEXT : C_BAD, fa_right);
        yy += 24;
    }
    draw_set_colour(C_LINE);
    draw_line(lx, yy + 4, rx, yy + 4);
    yy += 12;
    ui_text(lx, yy, "Net today", C_GOLD);
    ui_text(rx, yy, ((r.net >= 0) ? "+" : "") + tea_fmt_money(r.net), (r.net >= 0) ? C_ACCENT : C_BAD, fa_right);
    yy += 24;
    ui_text(lx, yy, "Bank balance", C_GOLD);
    ui_text(rx, yy, tea_fmt_money(global.money), (global.money >= 0) ? C_TEXT : C_BAD, fa_right);
    yy += 24;
    ui_text(lx, yy, "Focus XP earned", C_MUTED);
    ui_text(rx, yy, "+" + string(r.xp), C_TEXT, fa_right);
    yy += 30;

    if (global.debt_days > 0 && global.debt_days < 3) {
        ui_text_ext(lx, yy, "You're in the red. " + string(3 - global.debt_days) + " more night(s) below $0 and the bank takes the shop.", C_BAD, w - 64);
    }

    if (ui_button(x1 + 120, y1 + h - 56, x1 + w - 120, y1 + h - 18, "Open Day " + string(r.day + 1), true, 1, C_ACCENT)) {
        global.modal = "";
        tea_start_day();
    }
}

function tea_modal_help() {
    var w = 760, h = 540;
    var p = ui_window(w, h, "How to Play", true);
    var x1 = p[0], y1 = p[1];
    var s = "SERVING\n"
          + "Customers line up at the register. Click TAKE on their ticket, then BREW. Or walk to the register / tea station and press E. Brewing is 50% faster while you stand at a station. Customers who wait too long walk out and hurt your reputation.\n\n"
          + "GROWING\n"
          + "Learn recipes in Menu & Prices. Buy a Kitchen (food) or Espresso Machine (coffee) in Upgrades. Decor raises ambience, which brings more and happier customers. Hire Front of House to take orders and Baristas to brew.\n\n"
          + "FOCUS PATHS\n"
          + "Pick Expansion, Community or Innovation. Your focus earns XP every night and from events. Each path has two minor perks and one major perk.\n\n"
          + "THE GOAL\n"
          + "Reach " + string(TEA_GOAL_REP) + " reputation, save " + tea_fmt_money(TEA_GOAL_MONEY) + ", and unlock any major perk. Don't spend three nights in a row below $0.\n\n"
          + "Space: pause    1 / 2 / 3: game speed    E: take / brew";
    ui_text_ext(x1 + 24, y1 + 66, s, C_TEXT, w - 48);
}