// Toggle inventory
if (keyboard_check_pressed(ord("F"))) {
    invOpen = !invOpen;
}

// Stop movement if inventory or register UI is open
if (invOpen || (instance_exists(Register) && Register.regOpen)) {
    image_speed = 0;
    exit;
}

// Movement inputs (Arrow keys or WASD)
var move_x = (keyboard_check(vk_right) || keyboard_check(ord("D")))
           - (keyboard_check(vk_left)  || keyboard_check(ord("A")));
var move_y = (keyboard_check(vk_down)  || keyboard_check(ord("S")))
           - (keyboard_check(vk_up)    || keyboard_check(ord("W")));

// Update facing sprite based on input direction
if (move_x != 0 || move_y != 0) {
    if (move_y > 0) {
        sprite_index = Player_sprite_Down;
        image_xscale = 1;
    } else if (move_y < 0) {
        sprite_index = Player_sprite_Up;
        image_xscale = 1;
    } else if (move_x > 0) {
        sprite_index = Player_sprite_Side;
        image_xscale = 1;
    } else if (move_x < 0) {
        sprite_index = Player_sprite_Side;
        image_xscale = -1;
    }
    image_speed = 0.5;
} else {
    image_speed = 0;
    image_index = 0;
}

// Normalize diagonal speed
if (move_x != 0 && move_y != 0) {
    move_x *= 0.7071;
    move_y *= 0.7071;
}
move_x *= spd;
move_y *= spd;

// Collide against BOTH Furniture and Wall objects so you don't need
// extra furniture placed over walls to block the player
var _colliders = [Furniture, Wall];

// Horizontal collision
if (!place_meeting(x + move_x, y, _colliders)) {
    x += move_x;
} else {
    var _sx = sign(move_x);
    while (_sx != 0 && !place_meeting(x + _sx, y, _colliders)) {
        x += _sx;
    }
}

// Vertical collision
if (!place_meeting(x, y + move_y, _colliders)) {
    y += move_y;
} else {
    var _sy = sign(move_y);
    while (_sy != 0 && !place_meeting(x, y + _sy, _colliders)) {
        y += _sy;
    }
}

// Clamp inside room boundaries
var _half_w = abs(sprite_width) / 2;
var _half_h = abs(sprite_height) / 2;
x = clamp(x, _half_w, room_width  - _half_w);
y = clamp(y, _half_h, room_height - _half_h);

// Dynamic Y-depth sorting so Player walks behind/in front of counters & tables
depth = -bbox_bottom;