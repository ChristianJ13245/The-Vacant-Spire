// Create a dialogue box with given parameters
function dialogue_create(_x = 32, _y = 128, _layer = "Instances", _portraitSprite = spr_portraitDefault,
						 _dialogueString = "", _charDelay = 4, _soundPitch = 1, _autoCloseDelay = -1, _dialogueScale = 4, _soundVolume = 0.25, _sentencePauseDelay = 12, _speakerName = "")
{
	var dialogueBox = instance_create_layer(_x, _y, _layer, obj_dialogueBox,
	{
		portraitSprite : _portraitSprite,
		speakerName : _speakerName,
		dialogueText : _dialogueString,
		displayedText : "",
		charDelay : _charDelay,
		charTimer : 0,
		stringPosition : 0,
		soundPitch : _soundPitch,
		autoCloseDelay : _autoCloseDelay,
		doneHoldTimer : 0,
		inputLockTimer : 8,
		dialogueScale : _dialogueScale,
		soundVolume : _soundVolume,
		sentencePauseDelay : _sentencePauseDelay,
		currentPage : 0,
		pageText : "",
		pagesReady : false
	});
	
	return dialogueBox;
}

function dialogue_get_fight_intro(_fight)
{
	// add each first encounter script in here
	switch (_fight)
	{
		case 1:
			return "...";

		case 2:
			return "Wait... you actually got past steve? Do you have any idea how many hours of magical research I put into making him cast spells!";

		case 3:
			return "Oh my how long has it been! Do you have a wife yet? How's your finances going? Any health concerns? You can tell me everything as I walk you out!";

		case 4:
			return "I've been waiting all day to cause trouble.";

		case 5:
			return "Welcome, honored guest! Or should we say unwelcome?";

		case 6:
			return "Welcome, honored guest! Or should we say unwelcome?";

		case 7:
			return "Speed is strength.";

		case 8:
			return "Steve has been training.";

		case 9:
			return "Hello there. Sigh. Become a necromancer, they said. Minions will do it all for you, they said. Ah yes, such as the mighty Aunt Rose. Well, what business do you have in MY wizard tower? I happen to have a legally and magically binding eviction notice, issued by the Grand Wizarding Council. How magically binding is an eviction notice held by a dead man?";

		case 10:
			return "Call an ambulance! ...? But not for me. BEHOLD MY TRUE FORM!";
	}

	return "Click to skip text, then click again to start.";
}

function dialogue_get_fight_char_delay(_fight)
{
    if (_fight == 9)
    {
        return 2;
    }

    return 3;
}

function dialogue_setup_defaults()
{
	// keeps placed dialogue boxes from missing the new vars
	if (!variable_instance_exists(id, "dialogueScale")) dialogueScale = 4;
	if (!variable_instance_exists(id, "speakerName")) speakerName = "";
	if (!variable_instance_exists(id, "autoCloseDelay")) autoCloseDelay = -1;
	if (!variable_instance_exists(id, "doneHoldTimer")) doneHoldTimer = 0;
	if (!variable_instance_exists(id, "inputLockTimer")) inputLockTimer = 0;
	if (!variable_instance_exists(id, "soundVolume")) soundVolume = 0.25;
	if (!variable_instance_exists(id, "sentencePauseDelay")) sentencePauseDelay = 12;
	if (!variable_instance_exists(id, "pagesReady")) pagesReady = false;
	if (!variable_instance_exists(id, "currentPage")) currentPage = 0;
	if (!variable_instance_exists(id, "pageText")) pageText = "";
}

function dialogue_has_portrait()
{
	return is_real(portraitSprite) && portraitSprite != -1;
}

function dialogue_get_box_w()
{
	return sprite_get_width(spr_dialogueBoxBackground) * dialogueScale;
}

function dialogue_get_box_h()
{
	return sprite_get_height(spr_dialogueBoxBackground) * dialogueScale;
}

function dialogue_get_portrait_layout()
{
	var _boxW = dialogue_get_box_w();
	var _boxH = dialogue_get_box_h();
	var _pad = 4 * dialogueScale;
	var _layout = {
		hasPortrait: false,
		x: 0,
		y: 0,
		scale: 1
	};

	if (!dialogue_has_portrait())
	{
		return _layout;
	}

	_layout.hasPortrait = true;
	_layout.scale = (_boxH - (_pad * 2)) / sprite_get_height(portraitSprite);
	_layout.x = x + _boxW - _pad - (sprite_get_width(portraitSprite) * _layout.scale);
	_layout.y = y + _pad;

	return _layout;
}

// Draw the dialogue box (called in the draw event of dialogue box objects)
function dialogue_draw()
{
	dialogue_setup_defaults();
	dialogue_prepare_pages();

	var _boxW = dialogue_get_box_w();
	var _boxH = dialogue_get_box_h();
	var _portrait = dialogue_get_portrait_layout();

	// Draw dialogue box background
	draw_sprite_ext(spr_dialogueBoxBackground, 0, x, y, dialogueScale, dialogueScale, 0, c_white, 1);
	
	draw_sprite_ext(spr_dialogueBoxFrame, 0, x, y, dialogueScale, dialogueScale, 0, c_white, 1);				// dialogue box frame

	var _textX = x + (8 * dialogueScale);
	var _nameY = y + (2 * dialogueScale);
	var _textY = y + (10 * dialogueScale);
	var _textWidth = dialogue_get_text_width();

	// Draw portrait inside the right side of the box
	if (_portrait.hasPortrait)
	{
		var _portraitFrame = 0;

		if (stringPosition < string_length(pageText))
		{
			image_speed = 0.1;
			_portraitFrame = image_index;
		}

		dialogue_draw_sprite_top_left(portraitSprite, _portraitFrame, _portrait.x, _portrait.y, _portrait.scale);
	}

	// Draw text
	draw_set_color(c_white);
	draw_set_font(fnt_dialogueBoxText);

	// speaker name sits inside the box
	if (speakerName != "")
	{
		draw_text_transformed(_textX, _nameY, speakerName, dialogueScale, dialogueScale, 0);
	}

	draw_text_ext_transformed(_textX, _textY, displayedText, -1, _textWidth, dialogueScale, dialogueScale, 0);
	draw_set_font(-1);
}

function dialogue_prepare_pages()
{
	if (pagesReady)
	{
		return;
	}

	currentPage = 0;
	dialoguePages = dialogue_build_pages(dialogueText, dialogue_get_text_width(), 2);

	if (array_length(dialoguePages) <= 0)
	{
		dialoguePages = [""];
	}

	pageText = dialoguePages[0];
	displayedText = "";
	stringPosition = 0;
	pagesReady = true;
}

function dialogue_get_text_width()
{
	var _boxW = dialogue_get_box_w();
	var _portrait = dialogue_get_portrait_layout();
	var _textX = x + (8 * dialogueScale);
	var _textRight = x + _boxW - (8 * dialogueScale);

	if (_portrait.hasPortrait)
	{
		_textRight = _portrait.x - (4 * dialogueScale);
	}

	return max(40, (_textRight - _textX) / dialogueScale);
}

function dialogue_build_pages(_text, _maxWidth, _maxLines)
{
	var _pages = [];
	var _page = "";
	var _line = "";
	var _lineCount = 0;
	var _remaining = _text;

	draw_set_font(fnt_dialogueBoxText);

	while (string_length(_remaining) > 0)
	{
		var _spaceAt = string_pos(" ", _remaining);
		var _word = "";

		if (_spaceAt <= 0)
		{
			_word = _remaining;
			_remaining = "";
		}
		else
		{
			_word = string_copy(_remaining, 1, _spaceAt - 1);
			_remaining = string_delete(_remaining, 1, _spaceAt);
		}

		if (_word == "")
		{
			continue;
		}

		var _testLine = _word;

		if (_line != "")
		{
			_testLine = _line + " " + _word;
		}

		if (_line == "" || string_width(_testLine) <= _maxWidth)
		{
			_line = _testLine;
		}
		else
		{
			_page = dialogue_add_line_to_page(_page, _line);
			_lineCount += 1;
			_line = _word;

			if (_lineCount >= _maxLines)
			{
				array_push(_pages, _page);
				_page = "";
				_lineCount = 0;
			}
		}
	}

	if (_line != "")
	{
		_page = dialogue_add_line_to_page(_page, _line);
	}

	if (_page != "")
	{
		array_push(_pages, _page);
	}

	draw_set_font(-1);

	return _pages;
}

function dialogue_add_line_to_page(_page, _line)
{
	if (_page == "")
	{
		return _line;
	}

	return _page + "\n" + _line;
}

function dialogue_draw_sprite_top_left(_sprite, _frame, _x, _y, _scale)
{
	var _drawX = _x + (sprite_get_xoffset(_sprite) * _scale);
	var _drawY = _y + (sprite_get_yoffset(_sprite) * _scale);

	draw_sprite_ext(_sprite, _frame, _drawX, _drawY, _scale, _scale, 0, c_white, 1);
}

function dialogue_advance_pressed()
{
	if (inputLockTimer > 0)
	{
		inputLockTimer -= 1;
		return false;
	}

	return mouse_check_button_pressed(mb_left)
		|| keyboard_check_pressed(vk_enter)
		|| keyboard_check_pressed(vk_space);
}

function dialogue_next_page()
{
	currentPage += 1;
	pageText = dialoguePages[currentPage];
	displayedText = "";
	stringPosition = 0;
	charTimer = 0;
	doneHoldTimer = 0;
}

function dialogue_handle_advance(_textLength)
{
	if (!dialogue_advance_pressed())
	{
		return false;
	}

	if (stringPosition < _textLength)
	{
		// first click finishes this page
		stringPosition = _textLength;
		displayedText = pageText;
		return true;
	}

	if (currentPage < array_length(dialoguePages) - 1)
	{
		// next click goes to the next box
		dialogue_next_page();
		return true;
	}

	instance_destroy();
	return true;
}

function dialogue_tick_typewriter(_textLength)
{
	charTimer ++; // increment timer for delay between letters

	if (charTimer < charDelay || stringPosition >= _textLength)
	{
		return;
	}

	charTimer = 0; // reset letter timer
	stringPosition ++; // increment string position
	displayedText = string_copy(pageText, 1, stringPosition);

	var _typedChar = string_char_at(pageText, stringPosition);

	// other than where there are spaces, play a sound for each character
	if (_typedChar != " ")
	{
		audio_play_sound(snd_dialogueChirp, 0, 0, audio_get_sfx_volume(soundVolume), 0, random_range(soundPitch - 0.2, soundPitch + 0.2));
	}

	// tiny pause after sentence endings so it reads less flat
	if (_typedChar == "." || _typedChar == "!" || _typedChar == "?")
	{
		charTimer = -sentencePauseDelay;
	}
}

function dialogue_tick_auto_close(_textLength)
{
	if (autoCloseDelay < 0)
	{
		return;
	}

	if (stringPosition < _textLength)
	{
		return;
	}

	if (currentPage < array_length(dialoguePages) - 1)
	{
		return;
	}

	doneHoldTimer += 1;

	if (doneHoldTimer >= autoCloseDelay)
	{
		instance_destroy();
	}
}

// Step the dialogue box (called in the step event of dialogue box objects)
function dialogue_step()
{
	dialogue_setup_defaults();
	dialogue_prepare_pages();

	var _textLength = string_length(pageText);

	if (dialogue_handle_advance(_textLength))
	{
		return;
	}

	dialogue_tick_typewriter(_textLength);
	dialogue_tick_auto_close(_textLength);
}
