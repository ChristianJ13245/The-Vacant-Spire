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
    global.activeDialogue = noone;
    global.preCombatTimer = 0;

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

        case GameState.HELP:
            game_step_help(GameState.MENU);
        break;

        case GameState.PRE_COMBAT:
            game_step_pre_combat();
        break;

        case GameState.PLAYING:
            game_step_playing();
        break;

        case GameState.PAUSED:
            game_step_paused();
        break;

        case GameState.PAUSE_HELP:
            game_step_help(GameState.PAUSED);
        break;

        case GameState.WON:
        case GameState.LOST:
            game_step_end_state();
        break;
    }
}

function game_step_menu()
{
    var _guiW = display_get_gui_width();
    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 310;
    var _gap = 16;

    // button clicked, start the run
    if (ui_button_clicked(_buttonX, _buttonY, _buttonW, _buttonH))
    {
        game_start_new_run();
        return;
    }

    if (ui_button_clicked(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH))
    {
        global.gameState = GameState.HELP;
        return;
    }

    if (ui_button_clicked(_buttonX, _buttonY + ((_buttonH + _gap) * 2), _buttonW, _buttonH))
    {
        game_end();
        return;
    }
}

function game_step_help(_backState)
{
    var _buttonW = 120;
    var _buttonH = 38;

    // Esc backs out of help too
    if (keyboard_check_pressed(vk_escape))
    {
        global.gameState = _backState;
        return;
    }

    // back goes wherever opened help
    if (ui_button_clicked(24, 24, _buttonW, _buttonH))
    {
        global.gameState = _backState;
        return;
    }
}

function game_step_pre_combat()
{
    // wait until the dialogue box is gone, then give combat a tiny beat
    if (instance_exists(global.activeDialogue))
    {
        return;
    }

    if (global.preCombatTimer > 0)
    {
        global.preCombatTimer -= 1;
        return;
    }

    global.gameState = GameState.PLAYING;
    global.debugText = "Combat started";
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
    var _guiW = display_get_gui_width();
    var _buttonW = 240;
    var _buttonH = 50;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 280;
    var _gap = 14;

    // Esc closes pause
    if (keyboard_check_pressed(vk_escape))
    {
        global.gameState = GameState.PLAYING;
        return;
    }

    if (ui_button_clicked(_buttonX, _buttonY, _buttonW, _buttonH))
    {
        global.gameState = GameState.PLAYING;
        return;
    }

    if (ui_button_clicked(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH))
    {
        global.gameState = GameState.PAUSE_HELP;
        return;
    }

    if (ui_button_clicked(_buttonX, _buttonY + ((_buttonH + _gap) * 2), _buttonW, _buttonH))
    {
        game_restart_floor();
        return;
    }

    if (ui_button_clicked(_buttonX, _buttonY + ((_buttonH + _gap) * 3), _buttonW, _buttonH))
    {
        game_back_to_menu();
        return;
    }
}

function game_step_end_state()
{
    var _guiW = display_get_gui_width();
    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 360;
    var _gap = 16;

    // restart after a win or loss
    if (ui_button_clicked(_buttonX, _buttonY, _buttonW, _buttonH))
    {
        game_start_new_run();
        return;
    }

    if (ui_button_clicked(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH))
    {
        game_back_to_menu();
        return;
    }
}

function game_start_new_run()
{
    // Clear previous run first
    // stop duplicates from stacking up
    game_clear_battle_instances();

    global.currentFloor = 1;
    global.gameState = GameState.PRE_COMBAT;
    global.debugText = "Get ready";
    global.preCombatTimer = room_speed * 0.5;

    game_spawn_player();
    game_spawn_enemy();
    game_start_pre_combat_dialogue();
}

function game_start_pre_combat_dialogue()
{
    var _dialogueScale = 4;
    var _boxW = 256 * _dialogueScale;
    var _boxH = 32 * _dialogueScale;
    var _enemyName = "the enemy";
    var _portraitSprite = -1;

    if (instance_exists(global.enemy))
    {
        if (variable_instance_exists(global.enemy, "displayName"))
        {
            _enemyName = global.enemy.displayName;
        }

        if (variable_instance_exists(global.enemy, "sprFace"))
        {
            _portraitSprite = global.enemy.sprFace;
        }
    }

    var _boxX = (room_width - _boxW) * 0.5;
    var _boxY = room_height - _boxH - 24;
    var _text = dialogue_get_floor_intro(global.currentFloor);

    // keep this here so object events dont need changing
    global.activeDialogue = dialogue_create(_boxX, _boxY, game_get_dialogue_layer(), _portraitSprite, _text, 3, 1, -1, _dialogueScale, 0.25, 12, _enemyName);
}

function game_get_dialogue_layer()
{
    var _layerName = global.config.dialogueLayer;

    // use the ui instance layer if the room has one
    if (layer_get_id(_layerName) != -1)
    {
        return _layerName;
    }

    return global.config.instanceLayer;
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

function game_advance_floor()
{
    // next enemy, same run
    with (obj_spell)
    {
        instance_destroy();
    }

    with (obj_enemy)
    {
        instance_destroy();
    }

    global.enemy = noone;
    global.currentFloor += 1;
    global.gameState = GameState.PRE_COMBAT;
    global.debugText = "Floor " + string(global.currentFloor);
    global.preCombatTimer = room_speed * 0.5;

    if (instance_exists(global.player))
    {
        global.player.x = global.config.playerStartX;
        global.player.y = global.config.wizardY;
    }

    game_spawn_enemy();
    game_start_pre_combat_dialogue();
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

    // Remove dialogue
    with (obj_dialogueBox)
    {
        instance_destroy();
    }

    // Clear references
    global.player = noone;
    global.enemy = noone;
    global.activeDialogue = noone;
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
    if (global.gameState != GameState.PRE_COMBAT && global.gameState != GameState.PLAYING && global.gameState != GameState.PAUSED && global.gameState != GameState.PAUSE_HELP)
    {
        return;
    }

    draw_set_colour(make_colour_rgb(18, 16, 24));
    draw_rectangle(0, 0, room_width, room_height, false);
}

function game_draw_lanes()
{
    // not drawing lane/movement guide lines anymore
    if (global.gameState != GameState.PRE_COMBAT && global.gameState != GameState.PLAYING && global.gameState != GameState.PAUSED && global.gameState != GameState.PAUSE_HELP)
    {
        return;
    }
}
