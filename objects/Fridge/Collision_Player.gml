if (distance_to_object(Player) < 10 && keyboard_check_pressed(ord("E"))) {
    var space_left = Player.__invMax - Player.curInv;
    var numChange  = min(__produce, space_left);
    if (numChange > 0) {
        Player.curInv += numChange;
        __produce     -= numChange;
        array_push(Player.inv, numChange);
    }
}