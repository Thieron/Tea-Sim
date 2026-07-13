var move_x = (keyboard_check(vk_right) || keyboard_check(ord("D")))
           - (keyboard_check(vk_left)  || keyboard_check(ord("A")));
var move_y = (keyboard_check(vk_down)  || keyboard_check(ord("S")))
           - (keyboard_check(vk_up)    || keyboard_check(ord("W")));

// Normalize diagonal speed
if (move_x != 0 && move_y != 0) {
    move_x *= 0.7071; 
    move_y *= 0.7071;
}

move_x *= spd;
move_y *= spd;

// Horizontal movement + collision 
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