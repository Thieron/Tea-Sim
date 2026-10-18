// =====================================================================
//  TEA SIM - core state, data, economy and day flow
//  Every tuning number lives in the macros right below.
//  NOTE: the default font only has plain ASCII, so in-game text avoids
//  em dashes, curly quotes, emoji, etc.
// =====================================================================

#macro TEA_SHOP_NAME      "The Willow Kettle"
#macro TEA_GUI_W          1280
#macro TEA_GUI_H          720
#macro TEA_START_MONEY    2000
#macro TEA_OPEN_HOUR      8
#macro TEA_CLOSE_HOUR     20
#macro TEA_DAY_SECONDS    240
#macro TEA_RENT           80
#macro TEA_PASSIVE_XP     30
#macro TEA_GOAL_MONEY     8000
#macro TEA_GOAL_REP       75
#macro TEA_MAX_CUSTOMERS  16

// Where customers stand relative to the Register (pixels).
// If your counter faces up instead of down, use a negative Y.
#macro TEA_COUNTER_OFFSET_X 0
#macro TEA_COUNTER_OFFSET_Y 40
#macro TEA_QUEUE_GAP        22

// Where customers enter / leave. -1 = automatic (bottom-centre of Room1).
#macro TEA_DOOR_X -1
#macro TEA_DOOR_Y -1

// Colours
#macro C_PANEL  make_color_rgb(38, 32, 28)
#macro C_PANEL2 make_color_rgb(62, 52, 44)
#macro C_LINE   make_color_rgb(96, 82, 68)
#macro C_ACCENT make_color_rgb(110, 160, 98)
#macro C_GOLD   make_color_rgb(232, 192, 112)
#macro C_TEXT   make_color_rgb(244, 236, 220)
#macro C_MUTED  make_color_rgb(168, 156, 138)
#macro C_BAD    make_color_rgb(214, 96, 84)


// ---------------------------------------------------------------------
//  NEW GAME
// ---------------------------------------------------------------------
function tea_new_game() {
    global.money          = TEA_START_MONEY;
    global.day            = 0;
    global.minute         = TEA_OPEN_HOUR * 60;
    global.reputation     = 30;
    global.paused         = false;
    global.time_scale     = 1;
    global.dt             = 0;
    global.phase          = "open";
    global.force_close    = false;
    global.closing_at     = 0;
    global.modal          = "";
    global.current_event  = undefined;
    global.event_queue    = [];
    global.event_last     = {};
    global.toasts         = [];
    global.orders         = [];
    global.player_task    = undefined;
    global.staff          = [];
    global.price_mode     = 1;
    global.upgrades       = { kitchen: false, coffee: false, second_shop: false };
    global.perks          = {};
    global.focus          = "";
    global.regulars       = 0;
    global.clubs          = [];
    global.scheduled      = [];
    global.spawn_queue    = [];
    global.spawn_timer    = 3;
    global.queue_timer    = 0;
    global.arrival_counter = 0;
    global.debt_days      = 0;
    global.content_reached = false;
    global.supply_deal_until = 0;
    global.report         = undefined;

    global.staff_roles = {
        front:   { name: "Front of House",    wage: 55,  cap: 3, desc: "Takes orders at the register automatically." },
        back:    { name: "Barista / Kitchen", wage: 65,  cap: 3, desc: "Prepares queued orders automatically." },
        manager: { name: "Manager",           wage: 110, cap: 1, desc: "+10% staff speed, +25% focus XP, +20% reputation gains, and helps you pass inspections." }
    };
    global.staff_names = ["Mei", "Theo", "Priya", "Sam", "Rosa", "Eli", "Noor", "Jules", "Hana", "Marcus", "Ivy", "Omar", "Bea", "Kofi"];

    tea_init_menu();
    tea_init_paths();
    tea_init_decor();
    global.events = tea_build_events();
    tea_find_door();

    global.tea_ready = true;
    tea_start_day();
}


// ---------------------------------------------------------------------
//  MENU ITEMS
// ---------------------------------------------------------------------
function tea_item(_key, _name, _kind, _price, _cost, _prep, _buy, _req, _owned) {
    return { key: _key, name: _name, kind: _kind, price: _price, cost: _cost, prep: _prep, buy: _buy, req: _req, owned: _owned };
}

function tea_init_menu() {
    global.menu_items = [
        tea_item("green",     "Sencha Green",             "tea",     5.0, 0.9, 4, 0,   "",            true),
        tea_item("black",     "English Breakfast",        "tea",     4.5, 0.8, 4, 0,   "",            true),
        tea_item("chamomile", "Honey Chamomile",          "tea",     5.0, 1.0, 4, 120, "",            false),
        tea_item("jasmine",   "Jasmine Pearl",            "tea",     6.0, 1.3, 5, 180, "",            false),
        tea_item("chai",      "Spiced Chai",              "tea",     6.0, 1.4, 5, 200, "",            false),
        tea_item("matcha",    "Ceremonial Matcha",        "tea",     7.0, 2.0, 6, 300, "",            false),
        tea_item("espresso",  "Espresso",                 "coffee",  4.0, 0.7, 3, 0,   "coffee",      false),
        tea_item("latte",     "Oat Latte",                "coffee",  6.0, 1.4, 5, 0,   "coffee",      false),
        tea_item("pourover",  "Pour-Over",                "coffee",  6.5, 1.5, 6, 150, "coffee",      false),
        tea_item("scone",     "Butter Scone",             "food",    4.5, 1.0, 5, 0,   "kitchen",     false),
        tea_item("sandwich",  "Cucumber Sandwiches",      "food",    7.5, 2.2, 7, 0,   "kitchen",     false),
        tea_item("cake",      "Lemon Drizzle Cake",       "food",    6.0, 1.6, 6, 150, "kitchen",     false),
        tea_item("blue",      "Butterfly Pea Blue Tea",   "tea",     7.5, 1.8, 5, 200, "inn_recipes", false),
        tea_item("hibiscus",  "Hibiscus Rooibos",         "tea",     6.5, 1.5, 5, 150, "inn_recipes", false),
        tea_item("yerba",     "Yerba Mate Gourd",         "tea",     6.5, 1.5, 5, 150, "inn_recipes", false),
        tea_item("signature", "Dad's Signature Blend",    "special", 9.0, 1.6, 6, 0,   "inn_major",   false)
    ];
    tea_refresh_menu();
}

function tea_req_met(_req) {
    if (_req == "") return true;
    if (_req == "coffee")  return global.upgrades.coffee;
    if (_req == "kitchen") return global.upgrades.kitchen;
    return tea_has_perk(_req);
}

function tea_req_label(_req) {
    if (_req == "coffee")  return "Espresso Machine";
    if (_req == "kitchen") return "Kitchen Add-on";
    var pk = tea_find_perk(_req);
    if (!is_undefined(pk)) return "perk: " + pk.name;
    return _req;
}

function tea_refresh_menu() {
    for (var i = 0; i < array_length(global.menu_items); i++) {
        var it = global.menu_items[i];
        if (!it.owned && it.buy <= 0 && tea_req_met(it.req)) it.owned = true;
    }
}

function tea_sellable_items() {
    var out = [];
    for (var i = 0; i < array_length(global.menu_items); i++) {
        var it = global.menu_items[i];
        if (it.owned && tea_req_met(it.req)) array_push(out, it);
    }
    return out;
}

function tea_item_price(_it) {
    var m = [0.8, 1.0, 1.3];
    return _it.price * m[global.price_mode];
}

function tea_supply_mult() {
    var m = 1;
    if (tea_has_perk("exp_supply")) m *= 0.8;
    if (global.day <= global.supply_deal_until) m *= 0.7;
    return m;
}


// ---------------------------------------------------------------------
//  FOCUS PATHS
// ---------------------------------------------------------------------
function tea_init_paths() {
    global.paths = [
        { key: "expansion", name: "Expansion", xp: 0, col: make_color_rgb(214, 150, 84),
          blurb: "EXPAND like Napoleon. Grow beyond these four walls.",
          perks: [
            { key: "exp_hire",   name: "Recruiting Network", xp: 100, major: false, desc: "Hire people at a cheaper rate: all staff wages -25%." },
            { key: "exp_supply", name: "Bulk Suppliers",     xp: 250, major: false, desc: "Supplies at a cheaper rate: ingredient costs -20%." },
            { key: "exp_major",  name: "A Second Shop",      xp: 500, major: true,  desc: "MAJOR: Open a second shop ($3,000 in Upgrades). It earns $150 + $4 x reputation every day." }
          ] },
        { key: "community", name: "Community", xp: 0, col: make_color_rgb(110, 160, 98),
          blurb: "Create a sense of belonging. Make it everyone's second home.",
          perks: [
            { key: "com_regulars", name: "Familiar Faces", xp: 100, major: false, desc: "Happy customers may become regulars who come back every single morning." },
            { key: "com_tips",     name: "A Second Home",  xp: 250, major: false, desc: "Customers are more patient (+15s) and tip three times as generously." },
            { key: "com_major",    name: "Clubs",          xp: 500, major: true,  desc: "MAJOR: Found clubs (book club, mahjong night...) that meet weekly, bringing members, dues and reputation." }
          ] },
        { key: "innovation", name: "Innovation", xp: 0, col: make_color_rgb(120, 140, 214),
          blurb: "Be something unique. No other shop in the county is like this one.",
          perks: [
            { key: "inn_decor",   name: "Curator's Eye",       xp: 100, major: false, desc: "Unlocks unique decor. Better ambience means more customers, and happier ones." },
            { key: "inn_recipes", name: "World Recipes",       xp: 250, major: false, desc: "Learn teas from unique places: Butterfly Pea blue tea, Hibiscus Rooibos, Yerba Mate." },
            { key: "inn_major",   name: "The Signature Blend", xp: 500, major: true,  desc: "MAJOR: Recreate your father's lost recipe. A premium drink that draws people from out of town (+15% traffic)." }
          ] }
    ];
}

function tea_get_path(_key) {
    for (var i = 0; i < array_length(global.paths); i++) if (global.paths[i].key == _key) return global.paths[i];
    return undefined;
}

function tea_find_perk(_key) {
    for (var i = 0; i < array_length(global.paths); i++) {
        var ps = global.paths[i].perks;
        for (var j = 0; j < array_length(ps); j++) if (ps[j].key == _key) return ps[j];
    }
    return undefined;
}

function tea_has_perk(_key) {
    return variable_struct_exists(global.perks, _key);
}

function tea_next_perk(_path) {
    for (var i = 0; i < array_length(_path.perks); i++) if (!tea_has_perk(_path.perks[i].key)) return _path.perks[i];
    return undefined;
}

function tea_add_xp(_key, _amt) {
    var p = tea_get_path(_key);
    if (is_undefined(p)) return;
    if (tea_staff_count("manager") > 0) _amt *= 1.25;
    _amt = round(_amt);
    p.xp += _amt;
    global.today.xp += _amt;
    for (var i = 0; i < array_length(p.perks); i++) {
        var pk = p.perks[i];
        if (!tea_has_perk(pk.key) && p.xp >= pk.xp) {
            global.perks[$ pk.key] = true;
            tea_refresh_menu();
            tea_toast("Perk unlocked: " + pk.name, p.col);
            tea_queue_message((pk.major ? "Major Perk: " : "New Perk: ") + pk.name, p.name + " path\n\n" + pk.desc);
        }
    }
}


// ---------------------------------------------------------------------
//  DECOR / AMBIENCE
// ---------------------------------------------------------------------
function tea_init_decor() {
    global.decor = [
        { key: "plants",  name: "Potted Plants",            cost: 150, amb: 4,  req: "",          owned: false },
        { key: "paint",   name: "Fresh Coat of Paint",      cost: 250, amb: 5,  req: "",          owned: false },
        { key: "lantern", name: "Paper Lanterns",           cost: 350, amb: 8,  req: "inn_decor", owned: false },
        { key: "teaset",  name: "Antique Tea Ceremony Set", cost: 500, amb: 10, req: "inn_decor", owned: false },
        { key: "mural",   name: "Koi Pond Mural",           cost: 650, amb: 12, req: "inn_decor", owned: false }
    ];
}

function tea_ambience() {
    var a = 0;
    for (var i = 0; i < array_length(global.decor); i++) if (global.decor[i].owned) a += global.decor[i].amb;
    a += global.today.music;
    return a;
}


// ---------------------------------------------------------------------
//  STAFF
// ---------------------------------------------------------------------
function tea_wage(_role) {
    var w = global.staff_roles[$ _role].wage;
    if (tea_has_perk("exp_hire")) w *= 0.75;
    return round(w);
}

function tea_staff_count(_role) {
    var n = 0;
    for (var i = 0; i < array_length(global.staff); i++) if (global.staff[i].role == _role) n++;
    return n;
}

function tea_hire(_role) {
    var r = global.staff_roles[$ _role];
    var fee = tea_wage(_role);
    if (global.money < fee || tea_staff_count(_role) >= r.cap) return;
    global.money -= fee;
    var nm = global.staff_names[irandom(array_length(global.staff_names) - 1)];
    array_push(global.staff, { name: nm, role: _role, task: undefined, t: 0 });
    tea_toast("Hired " + nm + " as " + r.name + ".", C_ACCENT);
}

function tea_fire(_index) {
    var s = global.staff[_index];
    if (!is_undefined(s.task)) {
        if (s.task.state == "brewing") { s.task.state = "queued"; s.task.worker = ""; }
        if (s.task.state == "await_take") s.task.taker = "";
    }
    array_delete(global.staff, _index, 1);
    tea_toast(s.name + " has left the shop.", C_MUTED);
}


// ---------------------------------------------------------------------
//  REPUTATION / MONEY / FORMAT HELPERS
// ---------------------------------------------------------------------
function tea_add_rep(_amt) {
    if (_amt > 0 && tea_staff_count("manager") > 0) _amt *= 1.2;
    global.reputation = clamp(global.reputation + _amt, 0, 100);
}

function tea_fmt_money(_n) {
    var neg = _n < 0;
    var s = string(abs(round(_n)));
    var out = "";
    var len = string_length(s);
    for (var i = 1; i <= len; i++) {
        out += string_char_at(s, i);
        var rem = len - i;
        if (rem > 0 && rem mod 3 == 0) out += ",";
    }
    return (neg ? "-$" : "$") + out;
}

function tea_fmt_cents(_n) {
    return "$" + string_format(_n, 1, 2);
}

function tea_fmt_time(_m) {
    var h = floor(_m / 60) mod 24;
    var mm = floor(_m) mod 60;
    var ap = (h >= 12) ? "PM" : "AM";
    var h12 = h mod 12;
    if (h12 == 0) h12 = 12;
    return string(h12) + ":" + ((mm < 10) ? "0" : "") + string(mm) + " " + ap;
}

function tea_weekday(_d) { return (_d - 1) mod 7; }

function tea_weekday_name(_d) {
    var n = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return n[tea_weekday(_d)];
}

function tea_toast(_text, _col = C_TEXT) {
    array_insert(global.toasts, 0, { text: _text, col: _col, t: 5 });
    if (array_length(global.toasts) > 5) array_resize(global.toasts, 5);
}

function tea_is_paused() {
    return global.paused || global.modal != "";
}

function tea_goal_met() {
    var major = tea_has_perk("exp_major") || tea_has_perk("com_major") || tea_has_perk("inn_major");
    return global.reputation >= TEA_GOAL_REP && global.money >= TEA_GOAL_MONEY && major;
}


// ---------------------------------------------------------------------
//  ROOM POSITIONS
// ---------------------------------------------------------------------
function tea_find_door() {
    global.door_x = (TEA_DOOR_X >= 0) ? TEA_DOOR_X : room_width / 2;
    global.door_y = (TEA_DOOR_Y >= 0) ? TEA_DOOR_Y : room_height - 24;
}

function tea_counter_pos() {
    if (instance_exists(Register)) {
        var r = instance_find(Register, 0);
        return [r.x + TEA_COUNTER_OFFSET_X, r.y + TEA_COUNTER_OFFSET_Y];
    }
    return [room_width / 2, room_height / 2];
}


// ---------------------------------------------------------------------
//  DAY FLOW
// ---------------------------------------------------------------------
function tea_start_day() {
    global.day += 1;
    global.minute = TEA_OPEN_HOUR * 60;
    global.phase = "open";
    global.force_close = false;
    global.today = {
        revenue: 0, supplies: 0, tips: 0, served: 0, angry: 0, sat_sum: 0,
        xp: 0, music: 0, traffic_mult: 1, checks: [false, false, false],
        start_money: global.money
    };
    global.orders = [];
    global.player_task = undefined;
    global.spawn_queue = [];
    global.scheduled = [];
    global.spawn_timer = 3;
    for (var i = 0; i < array_length(global.staff); i++) { global.staff[i].task = undefined; global.staff[i].t = 0; }
    with (Chair_obj) taken_by = noone;

    if (tea_has_perk("com_regulars")) {
        repeat (min(global.regulars, 8)) array_push(global.spawn_queue, { tag: "regular", label: "" });
    }
    var wd = tea_weekday(global.day);
    for (var c = 0; c < array_length(global.clubs); c++) {
        var cl = global.clubs[c];
        if (cl.weekday == wd) array_push(global.scheduled, { hour: 17, count: irandom_range(4, 6), tag: "club", label: cl.name, income: 60 });
    }
    tea_story_for_day(global.day);
}

function tea_end_day() {
    global.phase = "report";
    with (Cusomer) instance_destroy();
    global.orders = [];
    global.player_task = undefined;
    for (var i = 0; i < array_length(global.staff); i++) global.staff[i].task = undefined;

    var wages = 0;
    for (var j = 0; j < array_length(global.staff); j++) wages += tea_wage(global.staff[j].role);
    var rent = TEA_RENT;
    var shop2 = global.upgrades.second_shop ? round(150 + global.reputation * 4) : 0;
    global.money += shop2 - wages - rent;

    if (global.focus != "") tea_add_xp(global.focus, TEA_PASSIVE_XP);

    var t = global.today;
    var sales = t.revenue + t.tips - t.supplies;
    var net = global.money - t.start_money;
    global.report = {
        day: global.day, served: t.served, angry: t.angry,
        avg_sat: (t.served > 0) ? t.sat_sum / t.served : 0,
        revenue: t.revenue, tips: t.tips, supplies: t.supplies,
        wages: wages, rent: rent, shop2: shop2,
        other: net - (sales + shop2 - wages - rent),
        net: net, xp: t.xp
    };

    if (global.money < 0) global.debt_days += 1; else global.debt_days = 0;
    if (global.debt_days >= 3) tea_queue_event_by_key("gameover");
    else if (!global.content_reached && tea_goal_met()) {
        global.content_reached = true;
        tea_queue_event_by_key("content");
    }
    global.modal = "report";
}

function tea_story_for_day(_d) {
    switch (_d) {
        case 1:  tea_queue_event_by_key("intro"); break;
        case 3:  tea_queue_event_by_key("letter_register"); break;
        case 7:  tea_queue_event_by_key("letter_week"); break;
        case 14: tea_queue_event_by_key("letter_tin"); break;
    }
}


// ---------------------------------------------------------------------
//  MAIN STEP (called by obj_game)
// ---------------------------------------------------------------------
function tea_step() {
    if (global.modal == "" && array_length(global.event_queue) > 0) tea_open_next_event();

    if (global.modal == "") {
        if (keyboard_check_pressed(vk_space)) global.paused = !global.paused;
        if (keyboard_check_pressed(ord("1"))) { global.time_scale = 1; global.paused = false; }
        if (keyboard_check_pressed(ord("2"))) { global.time_scale = 2; global.paused = false; }
        if (keyboard_check_pressed(ord("3"))) { global.time_scale = 3; global.paused = false; }
    }

    global.dt = 0;
    if (tea_is_paused() || global.phase == "report") return;

    var dt = global.time_scale / game_get_speed(gamespeed_fps);
    global.dt = dt;
    global.minute += dt * (TEA_CLOSE_HOUR - TEA_OPEN_HOUR) * 60 / TEA_DAY_SECONDS;
    var hr = global.minute / 60;

    if (global.phase == "open") {
        var cps = [10, 13, 16];
        for (var i = 0; i < 3; i++) {
            if (!global.today.checks[i] && hr >= cps[i]) {
                global.today.checks[i] = true;
                if (random(1) < 0.45) tea_try_random_event();
            }
        }

        for (var j = array_length(global.scheduled) - 1; j >= 0; j--) {
            var s = global.scheduled[j];
            if (hr >= s.hour) {
                repeat (s.count) array_push(global.spawn_queue, { tag: s.tag, label: s.label });
                if (s.income > 0) global.money += s.income;
                if (s.tag == "club") {
                    tea_add_rep(1);
                    tea_toast(s.label + " is meeting today! (+" + tea_fmt_money(s.income) + " dues)", C_ACCENT);
                } else {
                    tea_toast(s.label + " has arrived!", C_GOLD);
                }
                array_delete(global.scheduled, j, 1);
            }
        }

        if (!global.force_close) {
            global.spawn_timer -= dt;
            if (global.spawn_timer <= 0) {
                global.spawn_timer = tea_spawn_interval() * random_range(0.7, 1.3);
                if (instance_number(Cusomer) < TEA_MAX_CUSTOMERS && array_length(tea_sellable_items()) > 0) tea_spawn_customer("", "");
            }
        }

        if (array_length(global.spawn_queue) > 0) {
            global.queue_timer -= dt;
            if (global.queue_timer <= 0) {
                var q = global.spawn_queue[0];
                array_delete(global.spawn_queue, 0, 1);
                tea_spawn_customer(q.tag, q.label);
                global.queue_timer = 1.4;
            }
        }

        if (global.minute >= TEA_CLOSE_HOUR * 60 || global.force_close) {
            global.phase = "closing";
            global.closing_at = global.minute;
            global.spawn_queue = [];
            global.scheduled = [];
            tea_toast("The sign flips to CLOSED. Finishing the last orders...", C_MUTED);
            with (Cusomer) { if (state == "enter") state = "leave"; }
        }
    } else if (global.phase == "closing") {
        if (instance_number(Cusomer) == 0 || global.minute >= global.closing_at + 90) {
            tea_end_day();
            return;
        }
    }

    tea_update_workers(dt);
    tea_player_hotkeys();
}

function tea_spawn_interval() {
    var base = lerp(16, 5, global.reputation / 100);
    var mult = (1 + tea_ambience() / 80) * global.today.traffic_mult;
    mult *= clamp(0.8 + array_length(tea_sellable_items()) * 0.05, 0.8, 1.45);
    var pm = [1.15, 1.0, 0.85];
    mult *= pm[global.price_mode];
    if (tea_has_perk("inn_major")) mult *= 1.15;
    return base / max(0.1, mult);
}


// ---------------------------------------------------------------------
//  CUSTOMERS
// ---------------------------------------------------------------------
function tea_spawn_customer(_tag, _label) {
    var c = instance_create_depth(global.door_x, global.door_y, -global.door_y, Cusomer);
    c.tag = _tag;
    c.label = _label;
    c.is_regular = (_tag == "regular");
    if (_tag == "club") c.request_count = irandom_range(1, 2);
    c.request = tea_build_request(c.request_count);
    c.arrival = global.arrival_counter;
    global.arrival_counter += 1;
    if (array_length(c.request) == 0) with (c) instance_destroy();
    return c;
}

function tea_build_request(_n) {
    var pool = tea_sellable_items();
    var out = [];
    if (array_length(pool) == 0) return out;
    for (var i = 0; i < _n; i++) {
        var pick = pool[irandom(array_length(pool) - 1)];
        if (i == 0 && tea_has_perk("inn_major") && random(1) < 0.35) {
            for (var k = 0; k < array_length(pool); k++) if (pool[k].key == "signature") pick = pool[k];
        }
        array_push(out, pick);
    }
    return out;
}

function tea_queue_spot(_c) {
    var idx = 0;
    with (Cusomer) {
        if (id != _c && (state == "enter" || state == "ordering") && arrival < _c.arrival) idx++;
    }
    var cp = tea_counter_pos();
    var len = point_distance(0, 0, TEA_COUNTER_OFFSET_X, TEA_COUNTER_OFFSET_Y);
    var ux = (len > 0) ? TEA_COUNTER_OFFSET_X / len : 0;
    var uy = (len > 0) ? TEA_COUNTER_OFFSET_Y / len : 1;
    return [cp[0] + ux * idx * TEA_QUEUE_GAP, cp[1] + uy * idx * TEA_QUEUE_GAP, idx];
}

function tea_move_to(_tx, _ty, _spd) {
    if (point_distance(x, y, _tx, _ty) <= _spd) {
        x = _tx; y = _ty; stuck_t = 0;
        return true;
    }
    var ox = x, oy = y;
    if (stuck_t < 1.5) {
        mp_potential_step_object(_tx, _ty, _spd, Wall);
    } else {
        var dir = point_direction(x, y, _tx, _ty);
        x += lengthdir_x(_spd, dir);
        y += lengthdir_y(_spd, dir);
    }
    if (point_distance(ox, oy, x, y) < _spd * 0.25) stuck_t += global.dt;
    else if (stuck_t < 1.5) stuck_t = max(0, stuck_t - global.dt);
    if (abs(x - ox) > 0.1) image_xscale = (x > ox) ? 1 : -1;
    return false;
}

function tea_claim_chair(_c) {
    var best = noone;
    var bd = 1000000;
    with (Chair_obj) {
        if (!variable_instance_exists(id, "taken_by")) taken_by = noone;
        if (!instance_exists(taken_by)) {
            var d = point_distance(x, y, _c.x, _c.y);
            if (d < bd) { bd = d; best = id; }
        }
    }
    if (best != noone) best.taken_by = _c;
    return best;
}

function tea_release_chair() {
    if (instance_exists(chair) && variable_instance_exists(chair, "taken_by") && chair.taken_by == id) chair.taken_by = noone;
    chair = noone;
}

function tea_customer_storm_off(_c) {
    with (_c) {
        if (!is_undefined(order)) { tea_cancel_order(order); order = undefined; }
        tea_release_chair();
        state = "leave";
        bubble = ">:(";
        bubble_timer = 3;
        satisfaction = 0;
    }
    global.today.angry += 1;
    tea_add_rep(-1.5);
    tea_toast(_c.customer_name + " got tired of waiting and walked out.", C_BAD);
    if (global.today.angry == 3) tea_queue_event_by_key("complaint");
}


// ---------------------------------------------------------------------
//  ORDERS   (await_take -> queued -> brewing -> done, or cancelled)
// ---------------------------------------------------------------------
function tea_create_order(_cust) {
    var total = 0;
    for (var i = 0; i < array_length(_cust.request); i++) total += _cust.request[i].prep;
    var o = { cust: _cust, name: _cust.customer_name, items: _cust.request,
              prep_total: max(2, total), progress: 0, state: "await_take", worker: "", taker: "" };
    array_push(global.orders, o);
    return o;
}

function tea_remove_order(_o) {
    for (var i = array_length(global.orders) - 1; i >= 0; i--) if (global.orders[i] == _o) array_delete(global.orders, i, 1);
}

function tea_cancel_order(_o) {
    if (_o.state == "done") return;
    _o.state = "cancelled";
    tea_remove_order(_o);
    if (!is_undefined(global.player_task) && global.player_task == _o) global.player_task = undefined;
}

function tea_next_order(_state) {
    for (var i = 0; i < array_length(global.orders); i++) {
        var o = global.orders[i];
        if (o.state != _state) continue;
        if (_state == "await_take" && o.taker != "") continue;
        if (_state == "queued" && o.worker != "") continue;
        return o;
    }
    return undefined;
}

function tea_take_order(_o) {
    if (_o.state != "await_take") return;
    _o.state = "queued";
}

function tea_player_brew(_o) {
    if (!is_undefined(global.player_task) || _o.state != "queued") return;
    _o.state = "brewing";
    _o.worker = "player";
    global.player_task = _o;
}

function tea_player_near(_obj, _dist) {
    if (!instance_exists(Player) || !instance_exists(_obj)) return false;
    var p = instance_find(Player, 0);
    var n = instance_nearest(p.x, p.y, _obj);
    return point_distance(p.x, p.y, n.x, n.y) <= _dist;
}

function tea_player_at_station() {
    return tea_player_near(TeaObj, 72) || tea_player_near(Fridge, 72) || tea_player_near(Cabmnit, 72);
}

function tea_player_brew_speed() {
    return tea_player_at_station() ? 1.5 : 1.0;
}

function tea_player_hotkeys() {
    if (!keyboard_check_pressed(ord("E"))) return;
    if (tea_player_near(Register, 80)) {
        var o = tea_next_order("await_take");
        if (is_undefined(o)) {
            for (var i = 0; i < array_length(global.orders); i++) if (global.orders[i].state == "await_take") { o = global.orders[i]; break; }
        }
        if (!is_undefined(o)) { tea_take_order(o); tea_toast("You took " + o.name + "'s order.", C_TEXT); }
        return;
    }
    if (tea_player_at_station()) {
        if (!is_undefined(global.player_task)) { tea_toast("You're already brewing something.", C_MUTED); return; }
        var q = tea_next_order("queued");
        if (!is_undefined(q)) { tea_player_brew(q); tea_toast("Brewing for " + q.name + "...", C_TEXT); }
        return;
    }
}

function tea_update_workers(_dt) {
    var spd = (tea_staff_count("manager") > 0) ? 1.1 : 1.0;
    for (var i = 0; i < array_length(global.staff); i++) {
        var s = global.staff[i];
        if (s.role == "front") {
            if (!is_undefined(s.task) && s.task.state != "await_take") s.task = undefined;
            if (is_undefined(s.task)) {
                var o = tea_next_order("await_take");
                if (!is_undefined(o)) { o.taker = "staff"; s.task = o; s.t = 0; }
            } else {
                s.t += _dt * spd;
                if (s.t >= 1.5) { tea_take_order(s.task); s.task = undefined; }
            }
        } else if (s.role == "back") {
            if (!is_undefined(s.task) && s.task.state != "brewing") s.task = undefined;
            if (is_undefined(s.task)) {
                var o2 = tea_next_order("queued");
                if (!is_undefined(o2)) { o2.state = "brewing"; o2.worker = s.name; s.task = o2; }
            } else {
                s.task.progress += _dt * spd;
                if (s.task.progress >= s.task.prep_total) { var done = s.task; s.task = undefined; tea_order_complete(done); }
            }
        }
    }
    var pt = global.player_task;
    if (!is_undefined(pt)) {
        if (pt.state != "brewing") global.player_task = undefined;
        else {
            pt.progress += _dt * tea_player_brew_speed();
            if (pt.progress >= pt.prep_total) { global.player_task = undefined; tea_order_complete(pt); }
        }
    }
}

function tea_order_complete(_o) {
    _o.state = "done";
    tea_remove_order(_o);
    var c = _o.cust;
    if (!instance_exists(c)) return;

    var total = 0, cost = 0;
    for (var i = 0; i < array_length(_o.items); i++) {
        total += tea_item_price(_o.items[i]);
        cost += _o.items[i].cost;
    }
    cost *= tea_supply_mult();

    var pmod = [8, 0, -10];
    var sat = 80 - max(0, c.wait_time - 15) * 1.2 + tea_ambience() * 0.5 + pmod[global.price_mode];
    if (c.is_regular) sat += 6;
    if (c.tag == "club" || c.tag == "family") sat += 4;
    sat = clamp(sat + irandom_range(-6, 6), 0, 100);

    var tip = 0;
    if (sat >= 75) tip = total * (tea_has_perk("com_tips") ? 0.15 : 0.05);

    global.money += total + tip - cost;
    global.today.revenue  += total;
    global.today.tips     += tip;
    global.today.supplies += cost;
    global.today.served   += 1;
    global.today.sat_sum  += sat;

    tea_add_rep((sat - 55) / 90);
    if (sat >= 70 && global.focus != "") tea_add_xp(global.focus, 1);

    if (tea_has_perk("com_regulars") && sat >= 70 && !c.is_regular && global.regulars < 12 && random(1) < 0.3) {
        global.regulars += 1;
        tea_toast(c.customer_name + " says they'll be back tomorrow morning!", C_ACCENT);
    }

    c.satisfaction = sat;
    c.order = undefined;
    c.bubble = (sat >= 75) ? ":)" : ((sat >= 45) ? ":|" : ":(");
    c.bubble_timer = 3;
    c.money_text = "+" + tea_fmt_cents(total + tip);
    c.money_timer = 1.5;
    if (instance_exists(c.chair)) {
        c.state = "enjoy";
        c.enjoy_timer = random_range(10, 20);
    } else {
        c.state = "leave";
    }
}