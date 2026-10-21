// Set target_x and target_y on the customer instance (or in scr_tea_core)
// for wherever the customer is currently walking (e.g., Register, Table, or Exit).

if (!variable_instance_exists(id, "spd"))      spd = 1.5;
if (!variable_instance_exists(id, "target_x")) target_x = x;
if (!variable_instance_exists(id, "target_y")) target_y = y;

var _colliders = [Furniture, Wall];
var _dist = point_distance(x, y, target_x, target_y);

if (_dist > spd) {
    // 1. Try GameMaker's built-in potential step to steer around Furniture/Walls
    // (Works best when Wall's parent is set to Furniture)
    mp_potential_settings(45, 10, 3, true);
    var _moved = mp_potential_step_object(target_x, target_y, spd, Furniture);

    // 2. Safety check: if Wall is not parented to Furniture yet, prevent clipping into Wall
    if (place_meeting(x, y, _colliders)) {
        x = xprevious;
        y = yprevious;

        // Slide along whichever axis is clear so customer never gets stuck in a wall
        var _dir = point_direction(x, y, target_x, target_y);
        var _vx  = lengthdir_x(spd, _dir);
        var _vy  = lengthdir_y(spd, _dir);

        if (!place_meeting(x + _vx, y, _colliders)) {
            x += _vx;
        } else if (!place_meeting(x, y + _vy, _colliders)) {
            y += _vy;
        } else if (!place_meeting(x, y + sign(_vy) * spd, _colliders)) {
            y += sign(_vy) * spd;
        } else if (!place_meeting(x + sign(_vx) * spd, y, _colliders)) {
            x += sign(_vx) * spd;
        }
    }

    image_speed = 0.25;
} else {
    x = target_x;
    y = target_y;
    image_speed = 0.15; // slow idle animation
}

// Keep customer inside room bounds
var _half_w = abs(sprite_width) / 2;
var _half_h = abs(sprite_height) / 2;
x = clamp(x, _half_w, room_width  - _half_w);
y = clamp(y, _half_h, room_height - _half_h);

// Dynamic Y-depth sorting so customers draw behind/in front of counters & tables
depth = -bbox_bottom;