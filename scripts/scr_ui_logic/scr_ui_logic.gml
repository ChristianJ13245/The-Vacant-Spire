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

        case GameState.PLAYING:
            ui_draw_battle_hud();
        break;

        case GameState.PAUSED:
            ui_draw_battle_hud();
            ui_draw_pause_menu();
        break;

        case GameState.WON:
            ui_draw_center_message("You win!", "Press R to restart or M for menu");
        break;

        case GameState.LOST:
            ui_draw_center_message("You LOST, GET OUTTA HERE!", "Press R to restart or M for menu");
        break;
    }
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

    draw_text(_guiW * 0.5, 230, "Controls:");
    draw_text(_guiW * 0.5, 255, "W / S = Move up and down");
    draw_text(_guiW * 0.5, 280, "Space = Jump / Double Jump");
    draw_text(_guiW * 0.5, 305, "A / D = Change element");
    draw_text(_guiW * 0.5, 330, "Hold K = Charge spell");
    draw_text(_guiW * 0.5, 355, "Release K = Cast");

    draw_text(_guiW * 0.5, 400, "Fire beats Air   |   Air beats Water   |   Water beats Fire");

    // We can replace this with buttons later
    draw_text(_guiW * 0.5, 455, "Press Enter or Space to Start");

    draw_set_halign(fa_left);
}

function ui_draw_battle_hud()
{
    var _guiW = display_get_gui_width();

    var _margin = 24;
    var _topY = 24;
    var _barY = 150;
    var _middleGap = 280;
    var _barW = (_guiW - (_margin * 2) - _middleGap) * 0.5;
    var _barH = 24;

    // left bar starts from the left margin
    var _playerBarX = _margin;

    // right bar pushed in by same margin from the right side
    var _enemyBarX = _guiW - _margin - _barW;

    draw_set_colour(c_white);

    // small info block on the left for now
    draw_text(_margin, _topY, "Floor: " + string(global.currentFloor));
    draw_text(_margin, _topY + 28, global.debugText);

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
            ui_draw_health_bar(_enemyBarX, _barY, _barW, _barH, global.enemy.currentHealth, global.enemy.maxHealth, "Enemy", true);
        }
    }

    ui_draw_spell_controls();
}

function ui_draw_spell_controls()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    var _boxW = 620;
    var _boxH = 122;
    var _boxX = (_guiW - _boxW) * 0.5;
    var _boxY = _guiH - _boxH - 24;

    // bottom control box
    draw_set_alpha(0.65);
    draw_set_colour(c_black);
    draw_rectangle(_boxX, _boxY, _boxX + _boxW, _boxY + _boxH, false);
    draw_set_alpha(1);

    draw_set_colour(c_white);
    draw_rectangle(_boxX, _boxY, _boxX + _boxW, _boxY + _boxH, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    // quick controls reminder
    draw_text(_guiW * 0.5, _boxY + 12, "W/S: Move     Space: Jump     A/D: Element     Hold K: Charge");

    // current spell setup
    draw_text(_guiW * 0.5, _boxY + 40, "Spell: " + string(global.inputText));

    ui_draw_charge_bar(_boxX + 64, _boxY + 78, _boxW - 128, 18);

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
    draw_text(_guiW * 0.5, 280, "ESC: Resume");
    draw_text(_guiW * 0.5, 320, "R: Restart Floor");
    draw_text(_guiW * 0.5, 360, "M: Back To Menu");

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

function ui_draw_center_message(_title, _subtitle)
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    // full black background for end screen
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    draw_set_halign(fa_center);
    draw_set_colour(c_white);

    draw_text(_guiW * 0.5, 260, _title);
    draw_text(_guiW * 0.5, 310, _subtitle);

    draw_set_halign(fa_left);
}