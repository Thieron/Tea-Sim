// Open the register with E when in range (same pattern as the fridge)
if (!Player.invOpen && !regOpen && distance_to_object(Player) < 10 && keyboard_check_pressed(ord("E"))) {
    regOpen = true;
    regPage = "main";
}

// Close with Escape
if (regOpen && keyboard_check_pressed(vk_escape)) {
    regOpen = false;
}