if (distance_to_object(Player) < 10 && keyboard_check_pressed(ord("E"))) {
    var space_left = Player.__invMax - Player.curInv;
    var numChange  = min(__produce, space_left,3);

    if (numChange > 0) {
        Player.curInv += numChange;
        __produce     -= numChange;

        // look for an existing stack of this item
        var found = false;
        for (var i = 0; i < array_length(Player.inv); i++) {
            if (Player.inv[i].name == __produceName) {
                Player.inv[i].qty += numChange;
                found = true;
                break;
            }
        }
        if (!found) {
            array_push(Player.inv, { name: __produceName, qty: numChange });
        }
    }
}