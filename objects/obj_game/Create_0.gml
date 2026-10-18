/// Tea Sim game controller - runs the whole shop.
if (variable_global_exists("game_ctrl") && instance_exists(global.game_ctrl) && global.game_ctrl != id) {
    instance_destroy();
    exit;
}
global.game_ctrl = id;
display_set_gui_size(TEA_GUI_W, TEA_GUI_H);
randomize();
tea_new_game();