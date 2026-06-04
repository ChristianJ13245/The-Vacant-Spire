// Create a dialogue box with given parameters
function dialogue_create(_x = 32, _y = 128, _layer = "Instances", _portraitSprite = spr_portraitDefault,
						 _dialogueString = "", _charDelay = 4, _soundPitch = 1)
{
	var dialogueBox = instance_create_layer(_x, _y, _layer, obj_dialogueBox,
	{
		portraitSprite : _portraitSprite,
		dialogueText : _dialogueString,
		charDelay : _charDelay,
		soundPitch : _soundPitch
	});
	
	return dialogueBox;
}

// Draw the dialogue box (called in the draw event of dialogue box objects)
function dialogue_draw()
{
	// Draw dialogue box background
	draw_sprite(spr_dialogueBoxBackground, 0, x, y);	
	
	// Draw portrait, animated while talking
	if(stringPosition < string_length(dialogueText))
	{
		image_speed = 0.1;
		draw_sprite(portraitSprite, image_index, x, y);		// dialogue box portrait animated
	}
	else
	{
		draw_sprite(portraitSprite, 0, x, y);				// dialogue box portrait still
	}
	
	draw_sprite(spr_dialogueBoxFrame, 0, x, y);				// dialogue box frame

	// Draw text
	draw_set_color(c_white);
	draw_set_font(fnt_dialogueBoxText);
	var textXOffset = 36;
	var textYOffset = 2;
	draw_text_ext(x + textXOffset , y + textYOffset, displayedText, -1, 220);
	draw_set_font(-1);
}

// Step the dialogue box (called in the step event of dialogue box objects)
function dialogue_step()
{
	charTimer ++; // increment timer for delay between letters

	// once the letter delay is over, if there are still letters left, print the next letter
	if(charTimer >= charDelay && stringPosition < string_length(dialogueText))
	{
		charTimer = 0; // reset letter timer
		stringPosition ++; // increment string position
	
		// displayed text is a substring of the dialogue text, up to stringPosition
	    displayedText = string_copy(dialogueText, 0, stringPosition);
	
		// other than where there are spaces, play a sound for each character
		if(string_char_at(dialogueText, stringPosition) != " ")
		{
			audio_play_sound(snd_dialogueChirp, 0, 0, 1, 0, random_range(soundPitch - 0.2, soundPitch + 0.2));
		}
	}
}

