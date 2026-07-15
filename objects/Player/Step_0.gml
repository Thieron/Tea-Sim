if (keyboard_check_pressed(ord("F"))) {
    invOpen = !invOpen;
}

if (invOpen) {
	image_speed = 0;
	exit;
}


if (instance_exists(Register) && Register.regOpen) { 
	image_speed = 0;
	exit; 
}
// If inventory is open, stop here — no movement, no grabbing
if (invOpen) {
    image_speed = 0;
    exit;   // skips the rest of the Step event
}

// Inputs
var move_x = (keyboard_check(vk_right) || keyboard_check(ord("D")))
           - (keyboard_check(vk_left)  || keyboard_check(ord("A")));
var move_y = (keyboard_check(vk_down)  || keyboard_check(ord("S")))
           - (keyboard_check(vk_up)    || keyboard_check(ord("W")));

// Face direction based on raw input (before speed math)
if (move_x != 0 || move_y != 0) {
    if (move_y > 0)      sprite_index = Player_sprite_Down;
    else if (move_y < 0) sprite_index = Player_sprite_Up;
    else if (move_x > 0) { sprite_index = Player_sprite_Side; image_xscale = 1; }
    else if (move_x < 0) { sprite_index = Player_sprite_Side; image_xscale = -1; }
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

if (!place_meeting(x + move_x, y, Furniture)) {
    x += move_x;
} else {
    while (!place_meeting(x + sign(move_x), y, Furniture)) {
        x += sign(move_x);
    }
}
if (!place_meeting(x, y + move_y, Furniture)) {
    y += move_y;
} else {
    while (!place_meeting(x, y + sign(move_y), Furniture)) {
        y += sign(move_y);
    }
}

// Stay inside room
var left_edge   = sprite_width / 2;
var right_edge  = room_width  - sprite_width / 2;
var top_edge    = sprite_height / 2;
var bottom_edge = room_height - sprite_height / 2;
x = clamp(x, left_edge, right_edge);
y = clamp(y, top_edge, bottom_edge);



