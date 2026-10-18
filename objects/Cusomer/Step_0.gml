if (!tea_managed) exit;
if (tea_is_paused() || global.phase == "report") { image_speed = 0; exit; }

var dt = global.dt;
var spd = move_speed * global.time_scale;
var moving = false;
if (bubble_timer > 0) bubble_timer -= dt;
if (money_timer > 0) money_timer -= dt;

// Patience drains while they're waiting on the shop
if (state == "enter" || state == "ordering" || state == "seek_seat" || state == "waiting") {
    wait_time += dt;
    patience -= dt;
    if (patience <= 0) { tea_customer_storm_off(id); exit; }
}

switch (state) {
    case "enter":   // walk up and join the line at the register
        var spot = tea_queue_spot(id);
        var arrived = tea_move_to(spot[0], spot[1], spd);
        moving = !arrived;
        if (arrived && spot[2] == 0) {
            order = tea_create_order(id);
            state = "ordering";
        }
        break;

    case "ordering":   // at the front of the line, waiting for someone to take the order
        if (is_undefined(order)) { state = "leave"; break; }
        if (order.state != "await_take") {
            chair = tea_claim_chair(id);
            if (!instance_exists(chair)) {
                var cp = tea_counter_pos();
                stand_x = cp[0] + random_range(-70, 70);
                stand_y = cp[1] + 50 + random(30);
            }
            state = "seek_seat";
        }
        break;

    case "seek_seat":
        if (instance_exists(chair)) {
            if (tea_move_to(chair.x, chair.y, spd)) state = "waiting"; else moving = true;
        } else {
            if (tea_move_to(stand_x, stand_y, spd)) state = "waiting"; else moving = true;
        }
        break;

    case "waiting":   // order is being made
        break;

    case "enjoy":   // got their drink, sit and enjoy it
        if (instance_exists(chair) && point_distance(x, y, chair.x, chair.y) > 1) {
            tea_move_to(chair.x, chair.y, spd);
            moving = true;
        } else {
            enjoy_timer -= dt;
            if (enjoy_timer <= 0) { tea_release_chair(); state = "leave"; }
        }
        break;

    case "leave":
        if (tea_move_to(global.door_x, global.door_y, spd)) { instance_destroy(); exit; }
        moving = true;
        break;
}

// Animation
var seated = instance_exists(chair) && point_distance(x, y, chair.x, chair.y) <= 1 && (state == "waiting" || state == "enjoy");
if (seated) sprite_index = my_sprites.sit;
else sprite_index = moving ? my_sprites.walk : my_sprites.idle;
image_speed = global.time_scale;
depth = -y;