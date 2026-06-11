// This script draws all our menus and hud

function ui_draw()
{
    // reset text alignment at the start of GUI drawing to avoid any issues
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    switch (global.gameState)
    {
        case GameState.MENU:
            ui_draw_main_menu();
        break;

        case GameState.HELP:
            ui_draw_help_screen(GameState.MENU);
        break;

        case GameState.PRE_COMBAT:
            // dialogue box draws itself before combat starts
        break;

        case GameState.PLAYING:
            ui_draw_battle_hud();
        break;

        case GameState.PAUSED:
            ui_draw_battle_hud();
            ui_draw_pause_menu();
        break;

        case GameState.PAUSE_HELP:
            ui_draw_battle_hud();
            ui_draw_help_screen(GameState.PAUSED);
        break;

        case GameState.WON:
            ui_draw_end_menu("You win!");
        break;

        case GameState.LOST:
            ui_draw_end_menu("You LOST, GET OUTTA HERE!");
        break;
    }

    ui_draw_floor_transition_overlay();
}

function ui_draw_floor_transition_overlay()
{
    var _amount = clamp(global.floorTransitionCoverAmount, 0, 1);

    if (_amount <= 0)
    {
        return;
    }

    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();
    var _step = 32;
    var _maxSize = max(_guiW, _guiH);
    var _size = ceil((_maxSize * _amount) / _step) * _step;
    var _x = (_guiW - _size) * 0.5;
    var _y = (_guiH - _size) * 0.5;

    draw_set_colour(c_black);
    draw_rectangle(_x, _y, _x + _size, _y + _size, false);
}

function ui_mouse_in_rect(_x, _y, _w, _h)
{
    var _mx = device_mouse_x_to_gui(0);
    var _my = device_mouse_y_to_gui(0);

    return (_mx >= _x && _mx <= _x + _w && _my >= _y && _my <= _y + _h);
}

function ui_button_clicked(_x, _y, _w, _h)
{
    return ui_mouse_in_rect(_x, _y, _w, _h) && mouse_check_button_pressed(mb_left);
}

function ui_button(_x, _y, _w, _h, _label)
{
    var _hover = ui_mouse_in_rect(_x, _y, _w, _h);

    if (_hover)
    {
        draw_set_colour(make_colour_rgb(72, 72, 92));
    }
    else
    {
        draw_set_colour(make_colour_rgb(34, 34, 44));
    }

    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    if (_hover)
    {
        draw_set_colour(c_yellow);
    }
    else
    {
        draw_set_colour(c_white);
    }

    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_x + (_w * 0.5), _y + (_h * 0.5), _label);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    return _hover && mouse_check_button_pressed(mb_left);
}

function ui_draw_main_menu()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    // black background for the menu
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    draw_set_halign(fa_center);
    draw_set_colour(c_white);

    draw_text(_guiW * 0.5, 140, "THE VACANT SPIRE");
    draw_text(_guiW * 0.5, 180, "Reclaim your tower and serve the necromancer with legal nonsense!");

    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 310;
    var _gap = 16;

    ui_button(_buttonX, _buttonY, _buttonW, _buttonH, "Play");
    ui_button(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH, "Help");
    ui_button(_buttonX, _buttonY + ((_buttonH + _gap) * 2), _buttonW, _buttonH, "Quit");

    draw_set_halign(fa_left);
}

function ui_draw_help_screen(_backState)
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    if (_backState == GameState.PAUSED)
    {
        // darker overlay when help opens from pause
        draw_set_alpha(0.82);
        draw_set_colour(c_black);
        draw_rectangle(0, 0, _guiW, _guiH, false);
        draw_set_alpha(1);
    }
    else
    {
        draw_set_colour(c_black);
        draw_rectangle(0, 0, _guiW, _guiH, false);
    }

    ui_button(24, 24, 120, 38, "Back");

    draw_set_halign(fa_center);
    draw_set_colour(c_white);

    draw_text(_guiW * 0.5, 115, "Help");
    draw_text(_guiW * 0.5, 165, "Controls:");
    draw_text(_guiW * 0.5, 190, "W / S = Move up and down");
    draw_text(_guiW * 0.5, 215, "Space = Jump / Double Jump");
    draw_text(_guiW * 0.5, 240, "A / D = Change element");
    draw_text(_guiW * 0.5, 265, "Hold K = Charge spell");
    draw_text(_guiW * 0.5, 290, "Release K = Cast");

    draw_text(_guiW * 0.5, 350, "Fire beats Air   |   Air beats Water   |   Water beats Fire");
    draw_text(_guiW * 0.5, 390, "Beat the enemy to climb the spire.");
    draw_text(_guiW * 0.5, 420, "Esc pauses during battle.");

    draw_set_halign(fa_left);
}

function ui_draw_battle_hud()
{
    var _guiW = display_get_gui_width();

    var _margin = 24;
    var _barY = _margin + 20;
    var _middleGap = 280;
    var _barW = (_guiW - (_margin * 2) - _middleGap) * 0.5;
    var _barH = 24;
    // left bar starts from the left margin
    var _playerBarX = _margin;

    // right bar pushed in by same margin from the right side
    var _enemyBarX = _guiW - _margin - _barW;
    var _gapStartX = _playerBarX + _barW;
    var _gapEndX = _enemyBarX;
    var _floorBoxW = 132;
    var _floorBoxH = 36;
    var _floorBoxX = ((_gapStartX + _gapEndX) * 0.5) - (_floorBoxW * 0.5);
    var _floorBoxY = _barY + (_barH * 0.5) - (_floorBoxH * 0.5);

    // little backing box so the floor text is readable on the wall
    ui_draw_transparent_box(_floorBoxX, _floorBoxY, _floorBoxW, _floorBoxH);

    draw_set_colour(c_white);

    // floor sits right between the health bars
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_guiW * 0.5, _barY + (_barH * 0.5), "Floor: " + string(global.currentFloor));
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // player health bar
    if (instance_exists(global.player))
    {
        if (variable_instance_exists(global.player, "currentHealth") && variable_instance_exists(global.player, "maxHealth"))
        {
            ui_draw_health_bar(_playerBarX, _barY, _barW, _barH, global.player.currentHealth, global.player.maxHealth, "Player", false);
        }
    }

    // player mana bar
    if (instance_exists(global.player))
    {
        if (variable_instance_exists(global.player, "currentMana") && variable_instance_exists(global.player, "maxMana"))
        {
            ui_draw_mana_bar(_playerBarX, _barY + 44, _barW, 14, global.player.currentMana, global.player.maxMana, "Mana");
        }
    }

    // enemy health bar
    if (instance_exists(global.enemy))
    {
        if (variable_instance_exists(global.enemy, "currentHealth") && variable_instance_exists(global.enemy, "maxHealth"))
        {
            var _enemyName = "Enemy";

            if (variable_instance_exists(global.enemy, "displayName"))
            {
                _enemyName = global.enemy.displayName;
            }

            ui_draw_health_bar(_enemyBarX, _barY, _barW, _barH, global.enemy.currentHealth, global.enemy.maxHealth, _enemyName, true);
        }
    }

    ui_draw_spell_controls();
}

function ui_draw_transparent_box(_x, _y, _w, _h)
{
    draw_set_alpha(0.65);
    draw_set_colour(c_black);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_alpha(1);

    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
}

function ui_draw_spell_controls()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    var _boxW = 620;
    var _boxH = 92;
    var _boxX = (_guiW - _boxW) * 0.5;
    var _boxY = _guiH - _boxH - 24;

    // bottom control box
    ui_draw_transparent_box(_boxX, _boxY, _boxW, _boxH);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    // quick controls reminder
    draw_text(_guiW * 0.5, _boxY + 12, "W/S: Move     Space: Jump     A/D: Element     Hold K: Charge");

    // current spell setup
    draw_text(_guiW * 0.5, _boxY + 36, "Spell: " + string(global.inputText));

    ui_draw_charge_bar(_boxX + 64, _boxY + 62, _boxW - 128, 18);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_charge_bar(_x, _y, _w, _h)
{
    var _ratio = 0;

    // charge info lives on the player
    if (instance_exists(global.player))
    {
        if (variable_instance_exists(global.player, "isCharging"))
        {
            if (global.player.isCharging)
            {
                with (global.player)
                {
                    _ratio = player_input_charge_ratio();
                }
            }
        }
    }

    // empty bar
    draw_set_colour(c_dkgray);
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);

    // charge fill
    draw_set_colour(c_yellow);
    draw_rectangle(_x, _y, _x + (_w * _ratio), _y + _h, false);

    // outline
    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);

    // little markers for medium and strong charge points
    if (instance_exists(global.player))
    {
        if (variable_instance_exists(global.player, "mediumChargeFrames") && variable_instance_exists(global.player, "maxChargeFrames"))
        {
            var _mediumX = _x + _w * (global.player.mediumChargeFrames / global.player.maxChargeFrames);
            var _strongX = _x + _w * (global.player.strongChargeFrames / global.player.maxChargeFrames);

            draw_line(_mediumX, _y - 4, _mediumX, _y + _h + 4);
            draw_line(_strongX, _y - 4, _strongX, _y + _h + 4);
        }
    }
}

function ui_draw_pause_menu()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    // transparent overlay for pause menu
    draw_set_alpha(0.75);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);
    draw_set_alpha(1);

    draw_set_halign(fa_center);
    draw_set_colour(c_white);

    draw_text(_guiW * 0.5, 220, "Paused");

    var _buttonW = 240;
    var _buttonH = 50;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 280;
    var _gap = 14;

    ui_button(_buttonX, _buttonY, _buttonW, _buttonH, "Resume");
    ui_button(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH, "Help");
    ui_button(_buttonX, _buttonY + ((_buttonH + _gap) * 2), _buttonW, _buttonH, "Restart Floor");
    ui_button(_buttonX, _buttonY + ((_buttonH + _gap) * 3), _buttonW, _buttonH, "Main Menu");

    draw_set_halign(fa_left);
}

function ui_draw_health_bar(_x, _y, _barW, _barH, _current, _max, _label, _alignRight)
{
    var _ratio = 0;

    if (_max > 0)
    {
        _ratio = _current / _max;
    }

    // keeps the bar fill inside the box
    _ratio = clamp(_ratio, 0, 1);

    // label above the bar
    draw_set_colour(c_white);

    if (_alignRight)
    {
        draw_set_halign(fa_right);
        draw_text(_x + _barW, _y - 24, _label);
    }
    else
    {
        draw_set_halign(fa_left);
        draw_text(_x, _y - 24, _label);
    }

    draw_set_halign(fa_left);

    // empty bar background
    draw_set_colour(c_dkgray);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, false);

    // health fill
    draw_set_colour(c_lime);
    draw_rectangle(_x, _y, _x + (_barW * _ratio), _y + _barH, false);

    // white outline
    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, true);
}

function ui_draw_mana_bar(_x, _y, _barW, _barH, _current, _max, _label)
{
    var _ratio = 0;

    if (_max > 0)
    {
        _ratio = _current / _max;
    }

    _ratio = clamp(_ratio, 0, 1);

    draw_set_colour(c_white);
    draw_text(_x, _y - 18, _label);

    // empty bar
    draw_set_colour(c_dkgray);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, false);

    // mana fill
    draw_set_colour(make_colour_rgb(60, 150, 255));
    draw_rectangle(_x, _y, _x + (_barW * _ratio), _y + _barH, false);

    // outline
    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, true);
}

function ui_draw_end_menu(_title)
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    // full black background for end screen
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    draw_set_halign(fa_center);
    draw_set_colour(c_white);

    draw_text(_guiW * 0.5, 260, _title);

    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 360;
    var _gap = 16;

    ui_button(_buttonX, _buttonY, _buttonW, _buttonH, "Restart");
    ui_button(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH, "Main Menu");

    draw_set_halign(fa_left);
}
