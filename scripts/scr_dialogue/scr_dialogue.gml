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

function dialogue_get_floor_intro(_floor)
{
	// add each first encounter script in here
	switch (_floor)
	{
		case 1:
			return "...";

		case 2:
			return "Wait... you actually got past steve! Do you have any idea how many hours of magical research I put into making him cast spells!";
	}

	return "Click to skip text, then click again to start.";
}

// Draw the dialogue box (called in the draw event of dialogue box objects)
function dialogue_draw()
{
	dialogue_prepare_pages();

	if (!variable_instance_exists(id, "dialogueScale"))
	{
		dialogueScale = 4;
	}

	if (!variable_instance_exists(id, "speakerName"))
	{
		speakerName = "";
	}

	var _boxW = sprite_get_width(spr_dialogueBoxBackground) * dialogueScale;
	var _boxH = sprite_get_height(spr_dialogueBoxBackground) * dialogueScale;

	// Draw dialogue box background
	draw_sprite_ext(spr_dialogueBoxBackground, 0, x, y, dialogueScale, dialogueScale, 0, c_white, 1);
	
	draw_sprite_ext(spr_dialogueBoxFrame, 0, x, y, dialogueScale, dialogueScale, 0, c_white, 1);				// dialogue box frame

	var _textX = x + (8 * dialogueScale);
	var _nameY = y + (2 * dialogueScale);
	var _textY = y + (10 * dialogueScale);
	var _textWidth = dialogue_get_text_width();

	// Draw portrait inside the right side of the box
	if (is_real(portraitSprite) && portraitSprite != -1)
	{
		var _portraitPad = 4 * dialogueScale;
		var _portraitScale = (_boxH - (_portraitPad * 2)) / sprite_get_height(portraitSprite);
		var _portraitW = sprite_get_width(portraitSprite) * _portraitScale;
		var _portraitX = x + _boxW - _portraitPad - _portraitW;
		var _portraitY = y + _portraitPad;
		var _portraitFrame = 0;

		if (stringPosition < string_length(pageText))
		{
			image_speed = 0.1;
			_portraitFrame = image_index;
		}

		dialogue_draw_sprite_top_left(portraitSprite, _portraitFrame, _portraitX, _portraitY, _portraitScale);
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
	if (!variable_instance_exists(id, "pagesReady"))
	{
		pagesReady = false;
	}

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
	if (!variable_instance_exists(id, "dialogueScale"))
	{
		dialogueScale = 4;
	}

	var _boxW = sprite_get_width(spr_dialogueBoxBackground) * dialogueScale;
	var _boxH = sprite_get_height(spr_dialogueBoxBackground) * dialogueScale;
	var _textX = x + (8 * dialogueScale);
	var _textRight = x + _boxW - (8 * dialogueScale);

	if (is_real(portraitSprite) && portraitSprite != -1)
	{
		var _portraitPad = 4 * dialogueScale;
		var _portraitScale = (_boxH - (_portraitPad * 2)) / sprite_get_height(portraitSprite);
		var _portraitW = sprite_get_width(portraitSprite) * _portraitScale;
		var _portraitX = x + _boxW - _portraitPad - _portraitW;

		_textRight = _portraitX - (4 * dialogueScale);
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

// Step the dialogue box (called in the step event of dialogue box objects)
function dialogue_step()
{
	dialogue_prepare_pages();

	if (!variable_instance_exists(id, "autoCloseDelay"))
	{
		autoCloseDelay = -1;
	}

	if (!variable_instance_exists(id, "doneHoldTimer"))
	{
		doneHoldTimer = 0;
	}

	if (!variable_instance_exists(id, "inputLockTimer"))
	{
		inputLockTimer = 0;
	}

	if (!variable_instance_exists(id, "soundVolume"))
	{
		soundVolume = 0.25;
	}

	if (!variable_instance_exists(id, "sentencePauseDelay"))
	{
		sentencePauseDelay = 12;
	}

	var _canAdvance = inputLockTimer <= 0;

	if (inputLockTimer > 0)
	{
		inputLockTimer -= 1;
	}

	var _textLength = string_length(pageText);
	var _advancePressed = _canAdvance
		&& (mouse_check_button_pressed(mb_left)
		|| keyboard_check_pressed(vk_enter)
		|| keyboard_check_pressed(vk_space));

	if (_advancePressed)
	{
		if (stringPosition < _textLength)
		{
			// first click finishes the line
			stringPosition = _textLength;
			displayedText = pageText;
			return;
		}

		if (currentPage < array_length(dialoguePages) - 1)
		{
			// next click goes to the next box
			currentPage += 1;
			pageText = dialoguePages[currentPage];
			displayedText = "";
			stringPosition = 0;
			charTimer = 0;
			doneHoldTimer = 0;
			return;
		}

		// second click closes it
		instance_destroy();
		return;
	}

	charTimer ++; // increment timer for delay between letters

	// once the letter delay is over, if there are still letters left, print the next letter
	if(charTimer >= charDelay && stringPosition < _textLength)
	{
		charTimer = 0; // reset letter timer
		stringPosition ++; // increment string position
	
		// displayed text is a substring of the dialogue text, up to stringPosition
	    displayedText = string_copy(pageText, 1, stringPosition);
	
		// other than where there are spaces, play a sound for each character
		if(string_char_at(pageText, stringPosition) != " ")
		{
			audio_play_sound(snd_dialogueChirp, 0, 0, soundVolume, 0, random_range(soundPitch - 0.2, soundPitch + 0.2));
		}

		// tiny pause after sentence endings so it reads less flat
		var _lastChar = string_char_at(pageText, stringPosition);

		if (_lastChar == "." || _lastChar == "!" || _lastChar == "?")
		{
			charTimer = -sentencePauseDelay;
		}
	}

	if (autoCloseDelay >= 0 && stringPosition >= _textLength && currentPage >= array_length(dialoguePages) - 1)
	{
		doneHoldTimer += 1;

		if (doneHoldTimer >= autoCloseDelay)
		{
			instance_destroy();
		}
	}
}
