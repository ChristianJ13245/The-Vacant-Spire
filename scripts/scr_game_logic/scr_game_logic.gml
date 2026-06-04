// obj_game_controller calls these functions, logic stays in here

function game_create()
{
    // Store shared game settings globally so all systems can read them
    global.config = new PrototypeConfig();

    // general game information and stats, pretty self explanatory
    global.gameState = GameState.MENU;
    global.currentFloor = 1;
    global.player = noone;
    global.enemy = noone;

    // Simple debug line
    // see what the game controller is doing
    global.debugText = "Game ready";

    // shows the current spell setup on the HUD
    global.inputText = "";
}

function game_step()
{
    // Only one state should run each frame to avoid conflicts
    // with game being paused and played at the same time
    switch (global.gameState)
    {
        case GameState.MENU:
            game_step_menu();
        break;

        case GameState.PLAYING:
            game_step_playing();
        break;

        case GameState.PAUSED:
            game_step_paused();
        break;

        case GameState.WON:
        case GameState.LOST:
            game_step_end_state();
        break;
    }
}

function game_step_menu()
{
    // menu only needs to start for now
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))
    {
        game_start_new_run();
    }
}

function game_step_playing()
{
    // Esc to pause
    if (keyboard_check_pressed(vk_escape))
    {
        global.gameState = GameState.PAUSED;
        return;
    }

    // if the player gets removed count it as a loss
    if (!instance_exists(global.player))
    {
        global.gameState = GameState.LOST;
        return;
    }

    // if the enemy gets removed count it as a win
    if (!instance_exists(global.enemy))
    {
        global.gameState = GameState.WON;
        return;
    }
}

function game_step_paused()
{
    // Esc resumes the game
    if (keyboard_check_pressed(vk_escape))
    {
        global.gameState = GameState.PLAYING;
        return;
    }

    // R restarts the current floor
    if (keyboard_check_pressed(ord("R")))
    {
        game_restart_floor();
        return;
    }

    // M returns to the main menu
    if (keyboard_check_pressed(ord("M")))
    {
        game_back_to_menu();
        return;
    }
}

function game_step_end_state()
{
    // M goes back to the menu after a win or loss
    if (keyboard_check_pressed(ord("M")))
    {
        game_back_to_menu();
        return;
    }

    // R starts game again after a win or loss
    if (keyboard_check_pressed(ord("R")))
    {
        game_start_new_run();
        return;
    }
}

function game_start_new_run()
{
    // Clear previous run first
    // stop duplicates from stacking up
    game_clear_battle_instances();

    global.currentFloor = 1;
    global.gameState = GameState.PLAYING;
    global.debugText = "Game started";

    game_spawn_player();
    game_spawn_enemy();
}

function game_restart_floor()
{
    // Restart battle 
    game_clear_battle_instances();

    global.gameState = GameState.PLAYING;
    global.debugText = "Restarted floor";

    game_spawn_player();
    game_spawn_enemy();
}

function game_back_to_menu()
{
    // clear everything then go back to menu
    game_clear_battle_instances();

    global.currentFloor = 1;
    global.gameState = GameState.MENU;
    global.debugText = "Returned to menu";
}

function game_clear_battle_instances()
{
    // Remove spells first so they cant hit anything after restart
    with (obj_spell)
    {
        instance_destroy();
    }

    // Remove player
    with (obj_player)
    {
        instance_destroy();
    }

    // Remove enemy
    with (obj_enemy)
    {
        instance_destroy();
    }

    // Clear references
    global.player = noone;
    global.enemy = noone;
}

function game_spawn_player()
{
    var _cfg = global.config;

    // Spawn player using position from the config
    global.player = instance_create_layer(
        _cfg.playerStartX,
        _cfg.wizardY,
        _cfg.instanceLayer,
        obj_player
    );
}

function game_spawn_enemy()
{
    var _cfg = global.config;

    // Spawn enemy
    global.enemy = instance_create_layer(
        _cfg.enemyStartX,
        _cfg.wizardY,
        _cfg.instanceLayer,
        obj_enemy
    );
}

function game_draw_background()
{
    // only draw the battle background while we are actually in the battle
    // menu draws its own background in the GUI event
    if (global.gameState != GameState.PLAYING && global.gameState != GameState.PAUSED)
    {
        return;
    }

    draw_set_colour(make_colour_rgb(18, 16, 24));
    draw_rectangle(0, 0, room_width, room_height, false);
}

function game_draw_lanes()
{
    // not drawing lane/movement guide lines anymore
    if (global.gameState != GameState.PLAYING && global.gameState != GameState.PAUSED)
    {
        return;
    }
}