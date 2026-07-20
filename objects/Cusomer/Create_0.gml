// Customer identity
customer_names = [
    "Jade", "Connor", "Griffin", "Harrison", "Wade",
    "Dani", "Annie", "Kiria", "Ron", "Lina",
    "Donna", "Gonzo", "Santi", "Landon", "Aaron"
];

// Pick one at random
customer_index = irandom(array_length(customer_names) - 1);
customer_name  = customer_names[customer_index];

// Sprite sets: use a struct keyed by name so each name maps to its own sprites
customer_sprites = {
    Jade : { idle: spr_jade_idle, walk: spr_jade_walk, sit: spr_jade_sit },

};

// Grab this customer's sprite set
my_sprites = customer_sprites[$ customer_name];
sprite_index = my_sprites.idle;

request_count = irandom_range(1, 3);
request = [];   // will hold item objects/ids they want