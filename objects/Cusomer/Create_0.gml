// Only run inside the game (obj_game sets everything up first)
tea_managed = variable_global_exists("tea_ready");
if (!tea_managed) { instance_destroy(); exit; }

// Customer identity
customer_names = [
    "Jade", "Connor", "Griffin", "Harrison", "Wade",
    "Dani", "Annie", "Kiria", "Ron", "Lina",
    "Donna", "Gonzo", "Santi", "Landon", "Aaron"
];

// Pick one at random
customer_index = irandom(array_length(customer_names) - 1);
customer_name  = customer_names[customer_index];

// Sprite sets: looks for spr_<name>_idle / _walk / _sit (e.g. spr_connor_walk).
// Anything missing falls back to Jade's idle sprite, so you can add art one
// customer at a time and it just starts working.
var key  = string_lower(customer_name);
var idle = asset_get_index("spr_" + key + "_idle");
if (idle == -1) idle = spr_jade_idle;
var walk = asset_get_index("spr_" + key + "_walk");
if (walk == -1) walk = asset_get_index("spr_jade_walk");
if (walk == -1) walk = idle;
var sit = asset_get_index("spr_" + key + "_sit");
if (sit == -1) sit = asset_get_index("spr_jade_sit");
if (sit == -1) sit = idle;
my_sprites = { idle: idle, walk: walk, sit: sit };
sprite_index = my_sprites.idle;

// Until everyone has their own art, tint the stand-ins so they read as different people
if (idle == spr_jade_idle && customer_name != "Jade") image_blend = make_color_hsv(irandom(255), 70, 255);

request_count = irandom_range(1, 3);
request = [];   // filled by tea_spawn_customer() with menu items

// Behaviour
state        = "enter";    // enter -> ordering -> seek_seat -> waiting -> enjoy -> leave
tag          = "";         // "", "regular", "family", "club"
label        = "";
is_regular   = false;
arrival      = 0;
order        = undefined;
chair        = noone;
stand_x      = x;
stand_y      = y;
patience_max = 45 + (tea_has_perk("com_tips") ? 15 : 0) + min(15, tea_ambience() * 0.4);
patience     = patience_max;
wait_time    = 0;
enjoy_timer  = 0;
satisfaction = -1;
bubble       = "";
bubble_timer = 0;
money_text   = "";
money_timer  = 0;
move_speed   = 1.6;
stuck_t      = 0;