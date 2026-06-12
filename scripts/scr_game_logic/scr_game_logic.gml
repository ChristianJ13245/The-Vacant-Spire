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
    global.preCombatDialogueStarted = false;
    global.preCombatDialogueStep = 0;
    global.floorTransitionPhase = 0;
    global.floorTransitionTimer = 0;
    global.floorTransitionCoverAmount = 0;
    global.volumeSliderDrag = "";
    global.wizardName = "";
    global.storyStep = 0;
    global.storyTimer = 0;
    global.deniedDrop = -220;

    // shows the current spell setup on the HUD
    global.inputText = "";
}

function game_step()
{
    if (game_step_debug_shortcuts())
    {
        game_update_battle_background();
        return;
    }

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

        case GameState.INTRO:
            game_step_intro();
        break;

        case GameState.NAME_ENTRY:
            game_step_name_entry();
        break;

        case GameState.LETTER:
            game_step_letter();
        break;

        case GameState.ARRIVAL:
            game_step_arrival();
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

        case GameState.VICTORY_STORY:
            game_step_victory_story();
        break;

        case GameState.CREDITS:
            game_step_credits();
        break;

        case GameState.FINAL_ENDING:
            game_step_FINAL_ENDING();
        break;

        case GameState.FINAL_CREDITS:
            game_step_final_credits();
        break;

        case GameState.PHASE_TWO_DEFEAT:
            game_step_phase_two_defeat();
        break;

        case GameState.WON:
        case GameState.LOST:
            game_step_end_state();
        break;
    }

    game_update_battle_background();
}

function game_step_debug_shortcuts()
{
    if (!global.config.debugInstaDefeat)
    {
        return false;
    }

    if (keyboard_check_pressed(ord("9")))
    {
        game_debug_skip_to_necromancer();
        return true;
    }

    if (keyboard_check_pressed(ord("8")))
    {
        game_debug_skip_to_ending();
        return true;
    }

    return false;
}

function game_debug_skip_to_necromancer()
{
    // 9 jumps to necro so testing doesnt take forever
    game_clear_battle_instances();

    global.currentFight = 9;
    global.currentFloor = game_floor_from_fight(global.currentFight);
    global.gameState = GameState.PRE_COMBAT;
    global.preCombatTimer = room_speed * 0.5;
    global.preCombatDialogueStarted = false;
    global.preCombatDialogueStep = 0;
    global.floorTransitionPhase = 0;
    global.floorTransitionTimer = 0;
    global.floorTransitionCoverAmount = 0;

    game_spawn_player();
    game_spawn_enemy();
}

function game_debug_skip_to_ending()
{
    // 8 jumps to the ending so we can check credits fast
    game_clear_battle_instances();

    global.currentFight = global.config.maxFight;
    global.currentFloor = game_floor_from_fight(global.currentFight);
    global.floorTransitionPhase = 0;
    global.floorTransitionTimer = 0;
    global.floorTransitionCoverAmount = 0;

    game_start_victory_story();
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
        game_start_intro();
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

    game_step_help_volume_sliders();
}

function game_step_help_volume_sliders()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    var _guiW = display_get_gui_width();
    var _sliderW = 420;
    var _sliderX = (_guiW - _sliderW) * 0.5;
    var _sliderH = 22;
    var _sliderY = 500;
    var _gap = 48;

    var _mainVolume = ui_volume_slider_input(_sliderX, _sliderY, _sliderW, _sliderH, "main", global.audio.mainVolume);
    var _sfxVolume = ui_volume_slider_input(_sliderX, _sliderY + _gap, _sliderW, _sliderH, "sfx", global.audio.sfxControlVolume);
    var _musicVolume = ui_volume_slider_input(_sliderX, _sliderY + (_gap * 2), _sliderW, _sliderH, "music", global.audio.musicVolume);

    if (_mainVolume != global.audio.mainVolume)
    {
        audio_set_main_volume(_mainVolume);
    }

    if (_sfxVolume != global.audio.sfxControlVolume)
    {
        audio_set_sfx_volume(_sfxVolume);
    }

    if (_musicVolume != global.audio.musicVolume)
    {
        audio_set_music_volume(_musicVolume);
    }
}

function game_start_intro()
{
    game_clear_battle_instances();

    global.gameState = GameState.INTRO;
    global.storyStep = 0;
    global.storyTimer = 0;
    global.deniedDrop = -220;
    keyboard_string = "";
}

function game_step_intro()
{
    global.storyTimer += 1;

    var _totalTime = game_intro_line_time();

    if (game_story_advance_pressed() || global.storyTimer >= _totalTime)
    {
        global.storyStep += 1;
        global.storyTimer = 0;

        if (global.storyStep >= 4)
        {
            global.gameState = GameState.NAME_ENTRY;
            keyboard_string = "";
        }
    }
}

function game_step_name_entry()
{
    keyboard_string = string_copy(keyboard_string, 1, 18);

    if (keyboard_check_pressed(vk_enter))
    {
        global.wizardName = keyboard_string;

        if (string_length(global.wizardName) <= 0)
        {
            global.wizardName = "Wizard";
        }

        global.gameState = GameState.LETTER;
        global.storyStep = 0;
        global.storyTimer = 0;
        audio_play_letter_kiss();
    }
}

function game_step_letter()
{
    global.storyTimer += 1;

    var _guiW = display_get_gui_width();
    var _buttonW = 220;
    var _buttonH = 48;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = display_get_gui_height() - 76;

    if (ui_button_clicked(_buttonX, _buttonY, _buttonW, _buttonH) || keyboard_check_pressed(vk_enter))
    {
        global.gameState = GameState.ARRIVAL;
        global.storyStep = 0;
        global.storyTimer = 0;
    }
}

function game_step_arrival()
{
    global.storyTimer += 1;

    if (game_story_advance_pressed() || global.storyTimer >= room_speed * 6)
    {
        game_start_new_run();
    }
}

function game_story_advance_pressed()
{
    return game_story_skip_button_clicked()
        || keyboard_check_pressed(vk_space);
}

function game_story_skip_button_clicked()
{
    return ui_button_clicked(display_get_gui_width() - 136, 20, 112, 34);
}

function game_intro_line_time()
{
    return room_speed * 15;
}

function game_start_victory_story()
{
    game_clear_spells();
    game_clear_player_cast_state();

    with (obj_enemy)
    {
        instance_destroy();
    }

    global.enemy = noone;
    global.gameState = GameState.VICTORY_STORY;
    global.storyStep = 0;
    global.storyTimer = 0;
}

function game_step_victory_story()
{
    global.storyTimer += 1;

    if (game_story_advance_pressed())
    {
        global.gameState = GameState.CREDITS;
        global.storyTimer = 0;
    }
}

function game_step_credits()
{
    global.storyTimer += 1;

    if (game_story_advance_pressed() || global.storyTimer >= room_speed * 7)
    {
        global.gameState = GameState.FINAL_ENDING;
        global.storyTimer = 0;
        global.deniedDrop = -220;
    }
}

function game_step_FINAL_ENDING()
{
    global.storyTimer += 1;
    var _dropTarget = display_get_gui_height() * 0.28;

    if (global.deniedDrop < _dropTarget && game_story_skip_button_clicked())
    {
        global.gameState = GameState.FINAL_CREDITS;
        global.storyTimer = 0;
        return;
    }

    if (global.storyTimer > room_speed * 2)
    {
        global.deniedDrop = min(_dropTarget, global.deniedDrop + 14);
    }

    var _guiW = display_get_gui_width();
    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = display_get_gui_height() - 82;

    if (global.deniedDrop >= _dropTarget
    && ui_button_clicked(_buttonX, _buttonY, _buttonW, _buttonH))
    {
        global.gameState = GameState.FINAL_CREDITS;
        global.storyTimer = 0;
    }
}

function game_step_final_credits()
{
    global.storyTimer += 1;

    var _guiW = display_get_gui_width();
    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = display_get_gui_height() - 82;

    if (global.storyTimer >= room_speed * 8
    || ui_button_clicked(_buttonX, _buttonY, _buttonW, _buttonH))
    {
        game_back_to_menu();
    }
}

function game_start_phase_two_defeat()
{
    game_clear_spells();

    with (obj_player)
    {
        instance_destroy();
    }

    global.player = noone;
    global.gameState = GameState.PHASE_TWO_DEFEAT;
    global.storyTimer = 0;
}

function game_step_phase_two_defeat()
{
    global.storyTimer += 1;

    if (game_story_advance_pressed() || global.storyTimer >= room_speed * 5)
    {
        global.gameState = GameState.LOST;
    }
}

function game_step_pre_combat()
{
    if (!global.preCombatDialogueStarted)
    {
        if (game_step_pre_combat_intro())
        {
            return;
        }

        game_start_pre_combat_dialogue();
        return;
    }

    // wait until the dialogue box is gone, then give combat a tiny beat
    if (instance_exists(global.activeDialogue))
    {
        return;
    }

    if (game_start_next_pre_combat_dialogue())
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

function game_step_pre_combat_intro()
{
    if (!instance_exists(global.enemy))
    {
        return false;
    }

    if (!variable_instance_exists(global.enemy, "phaseIntroDone"))
    {
        return false;
    }

    if (global.enemy.phaseIntroDone)
    {
        return false;
    }

    with (global.enemy)
    {
        enemy_update_phase_intro();
    }

    return true;
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
        if (global.currentFight == global.config.maxFight)
        {
            game_start_phase_two_defeat();
            return;
        }

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
            global.preCombatDialogueStarted = false;
            global.preCombatDialogueStep = 0;
            global.floorTransitionCoverAmount = 0;
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
    global.gameState = GameState.FLOOR_TRANSITION;
    global.preCombatTimer = room_speed * 0.5;
    global.preCombatDialogueStarted = false;
    global.preCombatDialogueStep = 0;
    global.floorTransitionPhase = 2;
    global.floorTransitionTimer = 0;
    global.floorTransitionCoverAmount = 0;
    global.storyStep = 0;
    global.storyTimer = 0;

    game_spawn_player();
    game_spawn_enemy();

    global.player.x = -96;
    global.player.y = global.config.wizardY;
    game_set_player_transition_anim();
}

function game_start_pre_combat_dialogue()
{
    global.preCombatDialogueStarted = true;
    global.preCombatDialogueStep = 0;
    game_start_next_pre_combat_dialogue();
}

function game_start_next_pre_combat_dialogue()
{
    if (global.currentFight == 9)
    {
        return game_start_necro_intro_dialogue();
    }

    if (global.preCombatDialogueStep > 0)
    {
        return false;
    }

    game_create_pre_combat_dialogue_box(game_get_enemy_face_sprite(), dialogue_get_fight_intro(global.currentFight), game_get_enemy_display_name(), dialogue_get_fight_char_delay(global.currentFight));
    global.preCombatDialogueStep += 1;
    return true;
}

function game_start_necro_intro_dialogue()
{
    switch (global.preCombatDialogueStep)
    {
        case 0:
            game_create_pre_combat_dialogue_box(game_get_enemy_face_sprite(), dialogue_get_necro_intro_one(), game_get_enemy_display_name(), 2);
        break;

        case 1:
            game_create_pre_combat_dialogue_box(spr_player_face, dialogue_get_necro_player_reply(), game_get_player_display_name(), 2, 0);
        break;

        case 2:
            game_create_pre_combat_dialogue_box(game_get_enemy_face_sprite(), dialogue_get_necro_intro_two(), game_get_enemy_display_name(), 2);
        break;

        default:
            return false;
    }

    global.preCombatDialogueStep += 1;
    return true;
}

function game_create_pre_combat_dialogue_box(_portraitSprite, _text, _speakerName, _charDelay, _portraitSide = 1)
{
    var _dialogueScale = 4;
    var _boxW = 256 * _dialogueScale;
    var _boxH = 32 * _dialogueScale;
    var _boxX = (room_width - _boxW) * 0.5;
    var _boxY = room_height - _boxH - 24;

    // keep this here so object events dont need changing
    global.activeDialogue = dialogue_create(_boxX, _boxY, game_get_dialogue_layer(), _portraitSprite, _text, _charDelay, 1, -1, _dialogueScale, 0.25, 12, _speakerName, _portraitSide);
}

function game_get_enemy_display_name()
{
    return game_get_enemy_var("displayName", "the enemy");
}

function game_get_player_display_name()
{
    if (string_length(global.wizardName) > 0)
    {
        return global.wizardName;
    }

    return "Wizard";
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
    global.preCombatDialogueStarted = false;
    global.preCombatDialogueStep = 0;

    game_spawn_enemy();
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
    global.storyStep = 0;
    global.storyTimer = 0;
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
