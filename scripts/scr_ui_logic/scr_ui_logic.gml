// This script draws all our menus and hud

function ui_draw()
{
    // reset text alignment at the start of GUI drawing to avoid any issues
    draw_set_font(fnt_dialogueBoxText);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    ui_begin_hover_check();

    switch (global.gameState)
    {
        case GameState.MENU:
            ui_draw_main_menu();
        break;

        case GameState.HELP:
            ui_draw_help_screen(GameState.MENU);
        break;

        case GameState.INTRO:
            ui_draw_intro();
        break;

        case GameState.NAME_ENTRY:
            ui_draw_name_entry();
        break;

        case GameState.LETTER:
            ui_draw_letter();
        break;

        case GameState.ARRIVAL:
            ui_draw_arrival();
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

        case GameState.VICTORY_STORY:
            ui_draw_victory_story();
        break;

        case GameState.CREDITS:
            ui_draw_credits();
        break;

        case GameState.FINAL_ENDING:
            ui_draw_FINAL_ENDING();
        break;

        case GameState.FINAL_CREDITS:
            ui_draw_final_credits();
        break;

        case GameState.PHASE_TWO_DEFEAT:
            ui_draw_phase_two_defeat();
        break;

        case GameState.WON:
            ui_draw_end_menu("You win!");
        break;

        case GameState.LOST:
            ui_draw_end_menu("You LOST, GET OUTTA HERE!");
        break;
    }

    ui_draw_floor_transition_overlay();
    ui_end_hover_check();
    draw_set_font(-1);
}

function ui_text_scale()
{
    return 2.25;
}

function ui_draw_text(_x, _y, _text)
{
    var _scale = ui_text_scale();
    draw_text_transformed(_x, _y, _text, _scale, _scale, 0);
}

function ui_draw_text_ext(_x, _y, _text, _sep, _width)
{
    var _scale = ui_text_scale();
    var _scaledSep = _sep;

    if (_sep > 0)
    {
        _scaledSep = _sep / _scale;
    }

    draw_text_ext_transformed(_x, _y, _text, _scaledSep, _width / _scale, _scale, _scale, 0);
}

function ui_begin_hover_check()
{
    if (!variable_global_exists("uiHoveredButton"))
    {
        global.uiHoveredButton = "";
    }

    global.uiHoveredButtonNext = "";
}

function ui_end_hover_check()
{
    global.uiHoveredButton = global.uiHoveredButtonNext;
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
    if (!variable_global_exists("uiPressedButton"))
    {
        global.uiPressedButton = "";
    }

    var _hover = ui_mouse_in_rect(_x, _y, _w, _h);
    var _buttonId = ui_button_id(_x, _y, _w, _h);
    var _clicked = false;

    if (mouse_check_button_pressed(mb_left) && _hover)
    {
        global.uiPressedButton = _buttonId;
    }

    if (mouse_check_button_released(mb_left) && global.uiPressedButton == _buttonId)
    {
        global.uiPressedButton = "";
        _clicked = _hover;
    }

    if (_clicked)
    {
        audio_play_button_click();
    }

    return _clicked;
}

function ui_button(_x, _y, _w, _h, _label)
{
    var _hover = ui_mouse_in_rect(_x, _y, _w, _h);
    ui_button_hover_sound(_x, _y, _w, _h, _label, _hover);
    var _scale = 1;

    if (_hover)
    {
        _scale = 1.06;
    }

    ui_draw_scroll_button(_x, _y, _w, _h, _label, _scale, _hover);

    return ui_button_clicked(_x, _y, _w, _h);
}

function ui_draw_scroll_button(_x, _y, _w, _h, _label, _scale, _hover)
{
    var _drawW = _w * _scale;
    var _drawH = _h * _scale;
    var _drawX = _x + (_w * 0.5);
    var _drawY = _y + (_h * 0.5);
    var _xScale = _drawW / sprite_get_width(spr_button_scroll);
    var _yScale = _drawH / sprite_get_height(spr_button_scroll);
    var _left = _drawX - (_drawW * 0.5);
    var _top = _drawY - (_drawH * 0.5);
    var _spriteX = _left + (sprite_get_xoffset(spr_button_scroll) * _xScale);
    var _spriteY = _top + (sprite_get_yoffset(spr_button_scroll) * _yScale);

    draw_sprite_ext(spr_button_scroll, 0, _spriteX, _spriteY, _xScale, _yScale, 0, c_white, 1);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    if (_hover)
    {
        draw_set_colour(c_white);
    }
    else
    {
        draw_set_colour(c_black);
    }

    var _textScale = _scale * ui_text_scale();
    draw_text_transformed(_x + (_w * 0.5), _y + (_h * 0.5), _label, _textScale, _textScale, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
}

function ui_draw_skip_button()
{
    var _guiW = display_get_gui_width();
    ui_button(_guiW - 136, 20, 112, 34, "Next");
}

function ui_button_hover_sound(_x, _y, _w, _h, _label, _hover)
{
    if (!_hover)
    {
        return;
    }

    var _buttonId = ui_button_id(_x, _y, _w, _h);
    global.uiHoveredButtonNext = _buttonId;

    if (global.uiHoveredButton != _buttonId)
    {
        audio_play_button_hover();
    }
}

function ui_button_id(_x, _y, _w, _h)
{
    return string(_x) + ":" + string(_y) + ":" + string(_w) + ":" + string(_h);
}

function ui_volume_slider_input(_x, _y, _w, _h, _id, _value)
{
    if (!variable_global_exists("volumeSliderDrag"))
    {
        global.volumeSliderDrag = "";
    }

    if (!mouse_check_button(mb_left))
    {
        if (global.volumeSliderDrag == _id)
        {
            global.volumeSliderDrag = "";
        }

        return _value;
    }

    var _hover = ui_mouse_in_rect(_x, _y, _w, _h);

    if (mouse_check_button_pressed(mb_left) && _hover)
    {
        global.volumeSliderDrag = _id;
        audio_play_button_click();
    }

    if (global.volumeSliderDrag != _id)
    {
        return _value;
    }

    var _mx = device_mouse_x_to_gui(0);
    return clamp((_mx - _x) / _w, 0, 1);
}

function ui_draw_volume_slider(_x, _y, _w, _label, _value)
{
    var _trackH = 8;
    var _trackY = _y + 12;
    var _knobSize = 18;
    var _knobX = _x + (_w * _value);
    var _knobY = _trackY + (_trackH * 0.5);

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_colour(c_white);
    ui_draw_text(_x, _y - 22, _label);

    draw_set_halign(fa_right);
    ui_draw_text(_x + _w, _y - 22, string(round(_value * 100)) + "%");

    draw_set_halign(fa_left);
    draw_set_colour(make_colour_rgb(42, 42, 52));
    draw_rectangle(_x, _trackY, _x + _w, _trackY + _trackH, false);

    draw_set_colour(c_yellow);
    draw_rectangle(_x, _trackY, _knobX, _trackY + _trackH, false);

    draw_set_colour(c_white);
    draw_rectangle(_x, _trackY, _x + _w, _trackY + _trackH, true);

    draw_set_colour(make_colour_rgb(245, 245, 245));
    draw_circle(_knobX, _knobY, _knobSize * 0.5, false);

    draw_set_colour(c_black);
    draw_circle(_knobX, _knobY, _knobSize * 0.5, true);
}

function ui_draw_intro()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    ui_draw_splash_background(0.45);

    draw_set_alpha(ui_story_fade_alpha(game_intro_line_time()));
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    ui_draw_text_ext(_guiW * 0.5, _guiH * 0.5, ui_intro_text(global.storyStep), 28, _guiW * 0.72);
    draw_set_alpha(1);

    ui_draw_skip_button();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_intro_text(_step)
{
    switch (_step)
    {
        case 0:
            return "The Vacant Spire Act";

        case 1:
            return "Any magical residence left unoccupied, undefended, and insufficiently warded for at least three full months can be legally claimed by whoever is brave, or stupid, enough to move in.";

        case 2:
            return "A wizard known to be a master of sorts was conducting business at the annual wizard council.";

        case 3:
            return "He has been away from his home for months now. This wizard's name was...";
    }

    return "";
}

function ui_story_fade_alpha(_totalTime)
{
    var _fadeTime = 45;
    var _timer = global.storyTimer;

    if (_timer < _fadeTime)
    {
        return _timer / _fadeTime;
    }

    if (_timer > _totalTime - _fadeTime)
    {
        return (_totalTime - _timer) / _fadeTime;
    }

    return 1;
}

function ui_draw_name_entry()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    ui_draw_splash_background(0.45);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_colour(c_white);
    ui_draw_text(_guiW * 0.5, _guiH * 0.38, "Type name");

    draw_set_colour(make_colour_rgb(24, 24, 32));
    draw_rectangle(_guiW * 0.5 - 220, _guiH * 0.48 - 28, _guiW * 0.5 + 220, _guiH * 0.48 + 28, false);

    draw_set_colour(c_white);
    draw_rectangle(_guiW * 0.5 - 220, _guiH * 0.48 - 28, _guiW * 0.5 + 220, _guiH * 0.48 + 28, true);
    ui_draw_text(_guiW * 0.5, _guiH * 0.48, keyboard_string + "|");
    ui_draw_text(_guiW * 0.5, _guiH * 0.6, "Press Enter");

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_letter()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();
    var _paperScale = (_guiW * 0.72) / sprite_get_width(spr_intro_letter);
    var _paperW = sprite_get_width(spr_intro_letter) * _paperScale;
    var _paperX = (_guiW - _paperW) * 0.5;
    var _paperY = 42;
    var _letterAlpha = clamp(global.storyTimer / 45, 0, 1);

    ui_draw_splash_background(0.35);

    draw_set_alpha(_letterAlpha);
    ui_draw_sprite_top_left(spr_intro_letter, _paperX, _paperY, _paperScale);

    draw_set_colour(c_black);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    ui_draw_text_ext(_paperX + 88, _paperY + 88, ui_letter_text(), 24, _paperW - 176);

    var _buttonW = 220;
    var _buttonH = 48;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = _guiH - 76;
    ui_button(_buttonX, _buttonY, _buttonW, _buttonH, "Continue");
    draw_set_alpha(1);

    draw_set_halign(fa_left);
}

function ui_letter_text()
{
    return "Dear " + global.wizardName + ",\n\n"
        + "The corridor walls seem so thin as of late. It seems an uninvited guest has moved in. I have my suspicions. I believe I heard the butler referring to him as Nick Romancer. He must be a charmer!\n\n"
        + "He definitely has put a spell on me ;) However, his presence seems to be changing everyone. He also seems to be changing the locks and announcing that this is his tower.\n\n"
        + "I thought I should share this with you as, well, you know me. I love a good gossip and tea session. I hope to see you soon. I'm not really feeling myself lately.\n\n"
        + "xoxo\n\nAunt Rose";
}

function ui_draw_arrival()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    ui_draw_splash_background(0.45);

    draw_set_alpha(ui_story_fade_alpha(room_speed * 6));
    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    ui_draw_text_ext(_guiW * 0.5, _guiH * 0.5, "With this sudden knowledge of a necromancer taking over his tower, " + global.wizardName + " swiftly gets a legally and magically binding eviction notice from the Wizarding Council and heads straight home.\n\nThe wizard finally enters the tower...", 28, _guiW * 0.72);
    draw_set_alpha(1);

    ui_draw_skip_button();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_victory_story()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();
    var _floorY = global.config.arenaBottomY - 12;
    var _fireplaceBottomY = _floorY - 8;

    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    ui_draw_sprite_cover(spr_floor_background);

    ui_draw_scene_sprite(spr_fairy_idle, _guiW * 0.39, _fireplaceBottomY - 92, 2.2, true);
    ui_draw_scene_sprite(spr_trained_dummy_idle, _guiW * 0.62, _fireplaceBottomY - 128, 2.2, false);

    ui_draw_fireplace_glow(_guiW * 0.5, _fireplaceBottomY);
    ui_draw_sprite_bottom_centered_animated(spr_ending_fireplace, _guiW * 0.5, _fireplaceBottomY, 1);

    ui_draw_scene_sprite(spr_goblin_idle, _guiW * 0.27, _floorY - 42, 2.2, true);
    ui_draw_scene_sprite(spr_aunt_rose_idle, _guiW * 0.37, _floorY, 2.2, true);
    ui_draw_scene_sprite(spr_player_idle, _guiW * 0.44, _floorY + 12, 2.2, false);

    ui_draw_scene_sprite(spr_butler_mix_idle, _guiW * 0.65, _floorY - 8, 2.2, false);
    ui_draw_scene_sprite(spr_golem_idle, _guiW * 0.78, _floorY - 32, 2.2, false);

    draw_set_alpha(0.55);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, 126, false);
    draw_set_alpha(1);

    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    ui_draw_text_ext(_guiW * 0.5, 64, "With the tower safely secured, our master wizard and his friends celebrate the joyous occasion around a fire with laughter and glee.", 28, _guiW * 0.78);

    ui_draw_skip_button();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_credits()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    ui_draw_text(_guiW * 0.5, _guiH * 0.36, "The Vacant Spire");
    ui_draw_text(_guiW * 0.5, _guiH * 0.56, "Thank you for playing");

    ui_draw_skip_button();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_FINAL_ENDING()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    var _bubbleY = _guiH * 0.28;
    var _skullY = _guiH * 0.64;

    ui_draw_sprite_centered(spr_ending_necro_skull, _guiW * 0.5, _skullY, 2);
    ui_draw_sprite_centered(spr_ending_speech_bubble, _guiW * 0.5, _bubbleY, 1);

    draw_set_colour(c_black);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    ui_draw_text_ext(_guiW * 0.5, _bubbleY, "In regards to the appeal, Sir Necro Mancer, your application has been denied!", 24, _guiW * 0.46);

    ui_draw_sprite_centered_rotated(spr_denied, _guiW * 0.5, global.deniedDrop, 1, 45);

    if (global.deniedDrop >= _bubbleY)
    {
        ui_button((_guiW - 240) * 0.5, _guiH - 82, 240, 52, "Main Menu");
    }
    else
    {
        ui_draw_skip_button();
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_final_credits()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    ui_draw_text(_guiW * 0.5, _guiH * 0.2, "Credits");
    ui_draw_text(_guiW * 0.5, _guiH * 0.36, "Artists");
    ui_draw_text(_guiW * 0.5, _guiH * 0.43, "Brandon   Carly   Jihun");
    ui_draw_text(_guiW * 0.5, _guiH * 0.56, "Programmers");
    ui_draw_text(_guiW * 0.5, _guiH * 0.63, "Riley   Christian");

    ui_button((_guiW - 240) * 0.5, _guiH - 82, 240, 52, "Main Menu");

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_phase_two_defeat()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);

    draw_set_colour(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    ui_draw_text(_guiW * 0.5, _guiH * 0.44, "\"I'm calling for a mistrial!\"");
    ui_draw_text(_guiW * 0.5, _guiH * 0.54, "\"You will make a nice addition to my floating skulls.\"");

    ui_draw_skip_button();

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function ui_draw_sprite_cover(_sprite)
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();
    var _scale = max(_guiW / sprite_get_width(_sprite), _guiH / sprite_get_height(_sprite));
    var _x = (_guiW - (sprite_get_width(_sprite) * _scale)) * 0.5;
    var _y = (_guiH - (sprite_get_height(_sprite) * _scale)) * 0.5;

    ui_draw_sprite_top_left(_sprite, _x, _y, _scale);
}

function ui_draw_sprite_fit(_sprite)
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();
    var _scale = min(_guiW / sprite_get_width(_sprite), _guiH / sprite_get_height(_sprite));
    _scale = min(_scale, 1);

    ui_draw_sprite_centered(_sprite, _guiW * 0.5, _guiH * 0.5, _scale);
}

function ui_draw_splash_background(_darkAlpha)
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    ui_draw_sprite_cover(spr_splash_background);

    draw_set_alpha(_darkAlpha);
    draw_set_colour(c_black);
    draw_rectangle(0, 0, _guiW, _guiH, false);
    draw_set_alpha(1);
}

function ui_draw_sprite_centered(_sprite, _x, _y, _scale)
{
    ui_draw_sprite_top_left(_sprite, _x - (sprite_get_width(_sprite) * _scale * 0.5), _y - (sprite_get_height(_sprite) * _scale * 0.5), _scale);
}

function ui_draw_sprite_bottom_centered(_sprite, _x, _bottomY, _scale)
{
    ui_draw_sprite_top_left(_sprite, _x - (sprite_get_width(_sprite) * _scale * 0.5), _bottomY - (sprite_get_height(_sprite) * _scale), _scale);
}

function ui_draw_sprite_bottom_centered_animated(_sprite, _x, _bottomY, _scale)
{
    var _frameCount = sprite_get_number(_sprite);
    var _frame = 0;

    if (_frameCount > 1)
    {
        var _spriteSpeed = sprite_get_speed(_sprite);
        var _framesPassed = global.storyTimer * _spriteSpeed;

        if (sprite_get_speed_type(_sprite) == spritespeed_framespersecond)
        {
            _framesPassed = (global.storyTimer / max(1, room_speed)) * _spriteSpeed;
        }

        _frame = floor(_framesPassed) mod _frameCount;
    }

    var _left = _x - (sprite_get_width(_sprite) * _scale * 0.5);
    var _top = _bottomY - (sprite_get_height(_sprite) * _scale);

    draw_sprite_ext(_sprite, _frame, _left + (sprite_get_xoffset(_sprite) * _scale), _top + (sprite_get_yoffset(_sprite) * _scale), _scale, _scale, 0, c_white, 1);
}

function ui_draw_fireplace_glow(_x, _bottomY)
{
    var _pulse = 1 + (sin(current_time * 0.004) * 0.08);
    var _wide = 150 * _pulse;
    var _tall = 34 * _pulse;
    var _y = _bottomY - 10;

    draw_set_alpha(0.26);
    draw_ellipse_color(_x - _wide, _y - _tall, _x + _wide, _y + _tall, make_colour_rgb(255, 220, 80), make_colour_rgb(255, 120, 25), false);

    draw_set_alpha(0.16);
    draw_ellipse_color(_x - (_wide * 1.25), _y - (_tall * 1.25), _x + (_wide * 1.25), _y + (_tall * 1.25), make_colour_rgb(255, 200, 60), make_colour_rgb(255, 120, 25), false);
    draw_set_alpha(1);
}

function ui_draw_scene_sprite(_sprite, _x, _y, _scale, _faceRight)
{
    var _xScale = _scale;

    if (_faceRight)
    {
        _xScale = -_scale;
    }

    draw_sprite_ext(_sprite, 0, _x, _y, _xScale, _scale, 0, c_white, 1);
}

function ui_draw_sprite_centered_rotated(_sprite, _x, _y, _scale, _angle)
{
    var _dx = ((sprite_get_width(_sprite) * 0.5) - sprite_get_xoffset(_sprite)) * _scale;
    var _dy = ((sprite_get_height(_sprite) * 0.5) - sprite_get_yoffset(_sprite)) * _scale;
    var _rotX = (_dx * dcos(_angle)) - (_dy * dsin(_angle));
    var _rotY = (_dx * dsin(_angle)) + (_dy * dcos(_angle));

    draw_sprite_ext(_sprite, 0, _x - _rotX, _y - _rotY, _scale, _scale, _angle, c_white, 1);
}

function ui_draw_sprite_top_left(_sprite, _x, _y, _scale)
{
    draw_sprite_ext(_sprite, 0, _x + (sprite_get_xoffset(_sprite) * _scale), _y + (sprite_get_yoffset(_sprite) * _scale), _scale, _scale, 0, c_white, 1);
}

function ui_draw_main_menu()
{
    var _guiW = display_get_gui_width();
    var _guiH = display_get_gui_height();

    ui_draw_splash_background(0.35);

    draw_set_halign(fa_center);
    draw_set_colour(c_white);

    ui_draw_text(_guiW * 0.5, 140, "THE VACANT SPIRE");
    ui_draw_text(_guiW * 0.5, 180, "Reclaim your tower and serve the necromancer with legal nonsense!");

    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 310;
    var _gap = 16;

    ui_button(_buttonX, _buttonY, _buttonW, _buttonH, "Play");
    ui_button(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH, "Controls");
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

    ui_draw_text(_guiW * 0.5, 115, "Help");
    ui_draw_text(_guiW * 0.5, 165, "Controls:");
    ui_draw_text(_guiW * 0.5, 190, "W / S = Move up and down");
    ui_draw_text(_guiW * 0.5, 215, "Space = Jump / Double Jump");
    ui_draw_text(_guiW * 0.5, 240, "A / D = Change element");
    ui_draw_text(_guiW * 0.5, 265, "Hold K = Charge spell");
    ui_draw_text(_guiW * 0.5, 290, "Release K = Cast");

    ui_draw_text(_guiW * 0.5, 350, "Fire beats Air   |   Air beats Water   |   Water beats Fire");
    ui_draw_text(_guiW * 0.5, 390, "Beat the enemy to climb the spire.");
    ui_draw_text(_guiW * 0.5, 420, "Esc pauses during battle.");

    if (variable_global_exists("audio"))
    {
        var _sliderW = 420;
        var _sliderX = (_guiW - _sliderW) * 0.5;
        var _sliderY = 500;
        var _gap = 48;

        ui_draw_text(_guiW * 0.5, 465, "Volume");
        ui_draw_volume_slider(_sliderX, _sliderY, _sliderW, "Main", global.audio.mainVolume);
        ui_draw_volume_slider(_sliderX, _sliderY + _gap, _sliderW, "SFX", global.audio.sfxControlVolume);
        ui_draw_volume_slider(_sliderX, _sliderY + (_gap * 2), _sliderW, "Music", global.audio.musicVolume);
    }

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
    ui_draw_text(_guiW * 0.5, _barY + (_barH * 0.5), "Floor: " + string(global.currentFloor));
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
    ui_draw_text(_guiW * 0.5, _boxY + 12, "W/S: Move     Space: Jump     A/D: Element     Hold K: Charge");

    // current spell setup
    ui_draw_text(_guiW * 0.5, _boxY + 36, "Spell: " + string(global.inputText));

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

    ui_draw_text(_guiW * 0.5, 220, "Paused");

    var _buttonW = 240;
    var _buttonH = 50;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 280;
    var _gap = 14;

    ui_button(_buttonX, _buttonY, _buttonW, _buttonH, "Resume");
    ui_button(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH, "Controls");
    ui_button(_buttonX, _buttonY + ((_buttonH + _gap) * 2), _buttonW, _buttonH, "Restart Floor");
    ui_button(_buttonX, _buttonY + ((_buttonH + _gap) * 3), _buttonW, _buttonH, "Main Menu");

    draw_set_halign(fa_left);
}

function ui_draw_health_bar(_x, _y, _barW, _barH, _current, _max, _label, _alignRight)
{
    var _ratio = 0;
    var _trail = ui_health_trail_value(_current, _max, _alignRight);
    var _trailRatio = 0;

    if (_max > 0)
    {
        _ratio = _current / _max;
        _trailRatio = _trail / _max;
    }

    // keeps the bar fill inside the box
    _ratio = clamp(_ratio, 0, 1);
    _trailRatio = clamp(_trailRatio, 0, 1);

    // label above the bar
    draw_set_colour(c_white);

    if (_alignRight)
    {
        draw_set_halign(fa_right);
        ui_draw_text(_x + _barW, _y - 24, _label);
    }
    else
    {
        draw_set_halign(fa_left);
        ui_draw_text(_x, _y - 24, _label);
    }

    draw_set_halign(fa_left);

    // empty bar background
    draw_set_colour(c_dkgray);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, false);

    // little damage trail that catches up after getting hit
    draw_set_colour(make_colour_rgb(180, 40, 35));
    draw_rectangle(_x, _y, _x + (_barW * _trailRatio), _y + _barH, false);

    // health fill
    draw_set_colour(c_lime);
    draw_rectangle(_x, _y, _x + (_barW * _ratio), _y + _barH, false);

    // white outline
    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, true);
}

function ui_health_trail_value(_current, _max, _alignRight)
{
    if (_alignRight)
    {
        if (!variable_global_exists("uiEnemyHealthTrail") || !variable_global_exists("uiEnemyHealthTrailMax"))
        {
            global.uiEnemyHealthTrail = _current;
            global.uiEnemyHealthTrailMax = _max;
        }

        if (global.uiEnemyHealthTrailMax != _max || _current >= global.uiEnemyHealthTrail)
        {
            global.uiEnemyHealthTrail = _current;
            global.uiEnemyHealthTrailMax = _max;
        }
        else
        {
            global.uiEnemyHealthTrail = max(_current, global.uiEnemyHealthTrail - max(0.4, _max * 0.015));
        }

        return global.uiEnemyHealthTrail;
    }

    if (!variable_global_exists("uiPlayerHealthTrail") || !variable_global_exists("uiPlayerHealthTrailMax"))
    {
        global.uiPlayerHealthTrail = _current;
        global.uiPlayerHealthTrailMax = _max;
    }

    if (global.uiPlayerHealthTrailMax != _max || _current >= global.uiPlayerHealthTrail)
    {
        global.uiPlayerHealthTrail = _current;
        global.uiPlayerHealthTrailMax = _max;
    }
    else
    {
        global.uiPlayerHealthTrail = max(_current, global.uiPlayerHealthTrail - max(0.4, _max * 0.015));
    }

    return global.uiPlayerHealthTrail;
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
    ui_draw_text(_x, _y - 18, _label);

    // empty bar
    draw_set_colour(c_dkgray);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, false);

    if (ui_player_has_mana_for_current_spell(_current))
    {
        var _pulse = 1 + (sin(current_time * 0.01) * 0.06);
        var _pulseW = clamp((_barW * _ratio) * _pulse, 0, _barW);

        draw_set_alpha(0.3);
        draw_set_colour(c_aqua);
        draw_rectangle(_x - 2, _y - 2, _x + _pulseW + 2, _y + _barH + 2, false);
        draw_set_alpha(1);
    }

    // mana fill
    draw_set_colour(make_colour_rgb(60, 150, 255));
    draw_rectangle(_x, _y, _x + (_barW * _ratio), _y + _barH, false);

    // outline
    draw_set_colour(c_white);
    draw_rectangle(_x, _y, _x + _barW, _y + _barH, true);
}

function ui_player_has_mana_for_current_spell(_currentMana)
{
    if (!instance_exists(global.player))
    {
        return false;
    }

    var _spellPower = SpellPower.QUICK;

    if (variable_instance_exists(global.player, "isCharging") && global.player.isCharging)
    {
        var _chargeFrames = global.player.chargeFrames;
        var _mediumChargeFrames = global.player.mediumChargeFrames;
        var _strongChargeFrames = global.player.strongChargeFrames;

        if (_chargeFrames >= _strongChargeFrames)
        {
            _spellPower = SpellPower.STRONG;
        }
        else if (_chargeFrames >= _mediumChargeFrames)
        {
            _spellPower = SpellPower.MEDIUM;
        }
    }

    return _currentMana >= player_get_spell_mana_cost(_spellPower);
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

    ui_draw_text(_guiW * 0.5, 260, _title);

    var _buttonW = 240;
    var _buttonH = 52;
    var _buttonX = (_guiW - _buttonW) * 0.5;
    var _buttonY = 360;
    var _gap = 16;

    ui_button(_buttonX, _buttonY, _buttonW, _buttonH, "Restart");
    ui_button(_buttonX, _buttonY + (_buttonH + _gap), _buttonW, _buttonH, "Main Menu");

    draw_set_halign(fa_left);
}
