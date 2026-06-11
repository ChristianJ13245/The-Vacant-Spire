// obj_game_controller calls these functions, logic stays in here

function game_create()
{
    // Store shared game settings globally so all systems can read them
    global.config = new PrototypeConfig();

    // general game information and stats, pretty self explanatory
    global.gameState = GameState.MENU;
    global.currentFloor = 1;
	global.currentFight = 1;
    global.player = noone;
    global.enemy = noone;
    global.activeDialogue = noone;
    global.preCombatTimer = 0;
    global.floorTransitionPhase = 0;
    global.floorTransitionTimer = 0;
    global.floorTransitionCoverAmount = 0;

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

        case GameState.FLOOR_TRANSITION:
            game_step_floor_transition();
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

    game_update_battle_background();
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

function game_step_floor_transition()
{
    if (!instance_exists(global.player))
    {
        global.gameState = GameState.LOST;
        return;
    }

    var _walkSpeed = 8;
    var _wipeSpeed = 1 / 24;

    if (global.floorTransitionPhase == 0)
    {
        game_set_player_transition_anim();
        global.player.x += _walkSpeed;

        if (global.player.x > room_width + 96)
        {
            global.floorTransitionPhase = 1;
            global.floorTransitionTimer = 0;
            global.floorTransitionCoverAmount = 0;
        }

        return;
    }

    if (global.floorTransitionPhase == 1)
    {
        global.floorTransitionCoverAmount += _wipeSpeed;

        if (global.floorTransitionCoverAmount < 1)
        {
            return;
        }

        global.floorTransitionCoverAmount = 1;

        global.currentFight += 1;
        global.currentFloor = game_floor_from_fight(global.currentFight);

        game_reset_player_for_new_floor();
        game_spawn_enemy();
        game_update_battle_background();

        global.player.x = -96;
        global.player.y = global.config.wizardY;
        global.floorTransitionPhase = 2;
        global.floorTransitionTimer = 18;
        return;
    }

    if (global.floorTransitionPhase == 2)
    {
        if (global.floorTransitionTimer > 0)
        {
            global.floorTransitionTimer -= 1;
            return;
        }

        global.floorTransitionCoverAmount = max(0, global.floorTransitionCoverAmount - _wipeSpeed);

        game_set_player_transition_anim();
        global.player.x += _walkSpeed;

        if (global.player.x >= global.config.playerStartX)
        {
            global.player.x = global.config.playerStartX;
            global.player.y = global.config.wizardY;
            game_set_player_idle_anim();

            global.gameState = GameState.PRE_COMBAT;
            global.preCombatTimer = room_speed * 0.5;
            global.floorTransitionCoverAmount = 0;
            game_start_pre_combat_dialogue();
        }
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

    global.currentFight = 1;
    global.currentFloor = game_floor_from_fight(global.currentFight);
    global.gameState = GameState.PRE_COMBAT;
    global.preCombatTimer = room_speed * 0.5;
    global.floorTransitionCoverAmount = 0;

    game_spawn_player();
    game_spawn_enemy();
    game_start_pre_combat_dialogue();
}

function game_start_pre_combat_dialogue()
{
    var _dialogueScale = 4;
    var _boxW = 256 * _dialogueScale;
    var _boxH = 32 * _dialogueScale;
    var _enemyName = game_get_enemy_display_name();
    var _portraitSprite = game_get_enemy_face_sprite();
    var _boxX = (room_width - _boxW) * 0.5;
    var _boxY = room_height - _boxH - 24;
	var _text = dialogue_get_fight_intro(global.currentFight);

    // keep this here so object events dont need changing
    global.activeDialogue = dialogue_create(_boxX, _boxY, game_get_dialogue_layer(), _portraitSprite, _text, 3, 1, -1, _dialogueScale, 0.25, 12, _enemyName);
}

function game_get_enemy_display_name()
{
    return game_get_enemy_var("displayName", "the enemy");
}

function game_get_enemy_face_sprite()
{
    return game_get_enemy_var("sprFace", -1);
}

function game_get_enemy_var(_name, _fallback)
{
    if (!instance_exists(global.enemy))
    {
        return _fallback;
    }

    if (!variable_instance_exists(global.enemy, _name))
    {
        return _fallback;
    }

    return variable_instance_get(global.enemy, _name);
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

    game_spawn_player();
    game_spawn_enemy();
}

function game_advance_floor()
{
    var _nextFight = global.currentFight + 1;
    var _nextFloor = game_floor_from_fight(_nextFight);

    if (_nextFloor == global.currentFloor)
    {
        game_advance_same_floor_phase();
        return;
    }

    // actual new floor, let the player walk there
    game_clear_spells();
    game_clear_player_cast_state();

    with (obj_enemy)
    {
        instance_destroy();
    }

    global.enemy = noone;
    global.gameState = GameState.FLOOR_TRANSITION;
    global.floorTransitionPhase = 0;
    global.floorTransitionTimer = 0;
    global.floorTransitionCoverAmount = 0;
}

function game_advance_same_floor_phase()
{
    // next phase, same floor
    game_clear_spells();
    game_clear_player_cast_state();

    with (obj_enemy)
    {
        instance_destroy();
    }

    global.enemy = noone;
    global.currentFight += 1;
    global.currentFloor = game_floor_from_fight(global.currentFight);
    global.gameState = GameState.PRE_COMBAT;
    global.preCombatTimer = room_speed * 0.5;

    game_spawn_enemy();

    game_start_pre_combat_dialogue();
}

function game_reset_player_for_new_floor()
{
    if (!instance_exists(global.player))
    {
        return;
    }

    global.player.currentHealth = global.player.maxHealth;
    global.player.currentMana = global.player.maxMana;
    global.player.isDead = false;
    global.player.jumpOffset = 0;
    global.player.jumpVelocity = 0;
    global.player.isJumping = false;
    global.player.jumpCount = 0;
    game_clear_player_cast_state();
}

function game_set_player_transition_anim()
{
    if (!instance_exists(global.player))
    {
        return;
    }

    global.player.facing = 1;
    game_clear_player_cast_state();

    with (global.player)
    {
        if (variable_instance_exists(id, "drawSprite") && drawSprite != -1)
        {
            player_update_animation();
        }
    }
}

function game_clear_spells()
{
    with (obj_spell)
    {
        instance_destroy();
    }
}

function game_clear_player_cast_state()
{
    if (!instance_exists(global.player))
    {
        return;
    }

    with (global.player)
    {
        if (variable_instance_exists(id, "isCharging"))
        {
            isCharging = false;
        }

        if (variable_instance_exists(id, "chargeFrames"))
        {
            chargeFrames = 0;
        }

        if (variable_instance_exists(id, "castTimer"))
        {
            castTimer = 0;
        }

        if (variable_instance_exists(id, "sprIdle"))
        {
            if (!variable_instance_exists(id, "drawSprite") || drawSprite != sprIdle)
            {
                player_set_idle_animation();
            }
        }
    }
}

function game_set_player_idle_anim()
{
    if (!instance_exists(global.player))
    {
        return;
    }

    with (global.player)
    {
        if (variable_instance_exists(id, "sprIdle"))
        {
            player_set_idle_animation();
        }
    }
}

function game_floor_from_fight(_fight)
{
    switch (_fight)
    {
        case 1: return 1; // Training Dummy
        case 2: return 2; // Goblin
        case 3: return 3; // Aunt Rose
        case 4: return 4; // Fairy

        case 5: return 5; // Butler white phase
        case 6: return 5; // Butler black phase

        case 7: return 6; // Golem
        case 8: return 7; // Trained Dummy

        case 9: return 8; // Necromancer phase 1
        case 10: return 8; // Necromancer phase 2
        case 11: return 8; // Necromancer phase 3
    }

    return 1;
}

function game_back_to_menu()
{
    // clear everything then go back to menu
    game_clear_battle_instances();

	global.currentFight = 1;
    global.currentFloor = 1;
    global.gameState = GameState.MENU;
    global.floorTransitionCoverAmount = 0;
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

function game_update_battle_background()
{
    var _layerName = "BattleBackground";

    if (variable_struct_exists(global.config, "battleBackgroundLayer"))
    {
        _layerName = global.config.battleBackgroundLayer;
    }

    var _layerId = layer_get_id(_layerName);

    if (_layerId == -1)
    {
        return;
    }

    var _showBattleBg = game_should_show_battle_background();

    layer_set_visible(_layerId, _showBattleBg);

    if (!_showBattleBg)
    {
        return;
    }

    var _bgId = layer_background_get_id(_layerId);

    if (_bgId == -1)
    {
        return;
    }

    var _spr = spr_floor_background;

    if (game_is_top_floor())
    {
        _spr = spr_top_floor;
    }

    layer_background_sprite(_bgId, _spr);
}

function game_should_show_battle_background()
{
    return global.gameState == GameState.PRE_COMBAT
        || global.gameState == GameState.PLAYING
        || global.gameState == GameState.FLOOR_TRANSITION
        || global.gameState == GameState.PAUSED
        || global.gameState == GameState.PAUSE_HELP
        || global.gameState == GameState.WON
        || global.gameState == GameState.LOST;
}

function game_is_top_floor()
{
    var _topFloorStart = 9;

    if (variable_struct_exists(global.config, "topFloorStart"))
    {
        _topFloorStart = global.config.topFloorStart;
    }

    return global.currentFloor >= _topFloorStart;
}
