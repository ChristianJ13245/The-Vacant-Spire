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

    draw_text(_guiW * 0.5, 160, "THE VACANT SPIRE");
    draw_text(_guiW * 0.5, 200, "Reclaim your tower and serve the necromancer with legal nonsense!");

    // We can replace this with buttons later
    draw_text(_guiW * 0.5, 300, "Press Enter or Space to Start");

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
	draw_text(_margin, _topY + 28, "Arrows: power > element > lane");
    draw_text(_margin, _topY + 56, global.debugText);
	
	// shows current spell as the player builds it
	draw_text(_margin, _topY + 84, "Spell: " + string(global.inputText));

    // player health bar
    if (instance_exists(global.player))
    {
        if (variable_instance_exists(global.player, "currentHealth") && variable_instance_exists(global.player, "maxHealth"))
        {
            ui_draw_health_bar(_playerBarX, _barY, _barW, _barH, global.player.currentHealth, global.player.maxHealth, "Player", false);
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