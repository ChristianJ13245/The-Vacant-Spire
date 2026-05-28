// basic player setup and player behaviour.
// input will be added in a later commit

function player_create()
{
    // Basic values for prototype
    maxHealth = 100;
    currentHealth = maxHealth;
    isDead = false;
    hitRadius = 42;
    displayName = "Player";

    // facing 1 means cast from left to right
    facing = 1;

    // Placeholder until proper 32x32 art is imported
    bodyColour = make_colour_rgb(80, 180, 255);
	
    // quick cast animation
    castTimer = 0;
    castLane = SpellLane.MIDDLE;
	
	// mana stops the player from spamming spells forever
	maxMana = 100;
	currentMana = maxMana;

	// mana regen
	// regenDelay stops mana coming back instantly after casting
	manaRegenAmount = 0.75;
	manaRegenDelay = room_speed * 0.6;
	manaRegenTimer = 0;

    // animation values we control ourselves
    drawSprite = -1;
    drawFrame = 0;
    animTick = 0;
	image_speed = 0;
	image_index = 0;

    // higher number = slower animation
    idleFrameDelay = 8;
    castFrameDelay = 6;

    // sprites
    sprIdle = asset_get_index("spr_player_idle");
    sprCastLow = asset_get_index("spr_player_cast_low");
    sprCastMid = asset_get_index("spr_player_cast_mid");
    sprCastHigh = asset_get_index("spr_player_cast_high");

    // start idle
    drawSprite = sprIdle;
    drawFrame = 0;
    animTick = 0;

    // starts arrow inputs
    player_input_create();
}

function player_step()
{
    // Do nothing while paused or in menus
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }
	
    // reads arrow keys 
    player_input_step();

    player_update_animation();

    if (castTimer > 0)
    {
        castTimer -= 1;

        if (castTimer <= 0)
        {
            player_set_idle_animation();
        }
    }
	
	// bring mana back over time
	player_update_mana();

    // when health reaches 0, remove the player
    // game controller detects this and triggers the lose state
    if (currentHealth <= 0 && !isDead)
    {
        player_die();
    }
}

function player_draw()
{
    var _spr = drawSprite;

    if (_spr != -1)
    {
        // aura behind player
        player_draw_aura(_spr);

        // normal player sprite
        // drawFrame is our controlled animation frame
        draw_sprite_ext(_spr, drawFrame, x, y, 3, 3, 0, c_white, 1);
    }
    else
    {
        draw_set_colour(bodyColour);
        draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);
    }
}

function player_draw_aura(_spr)
{
    if (_spr == -1)
    {
        return;
    }

    shader_set(shd_player_aura);

    var _colourUniform = shader_get_uniform(shd_player_aura, "u_aura_colour");
    var _cutoffUniform = shader_get_uniform(shd_player_aura, "u_alpha_cutoff");

    // blue player aura
    shader_set_uniform_f(_colourUniform, 0.15, 0.75, 1.0, 0.45);

    // ignores basically transparent pixels
    shader_set_uniform_f(_cutoffUniform, 0.05);

    var _scale = 3;
    var _offset = 4;

    // draw tinted copies around the player
    // normal sprite gets drawn after this, so this sits behind them
    draw_sprite_ext(_spr, drawFrame, x - _offset, y, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x + _offset, y, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x, y - _offset, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x, y + _offset, _scale, _scale, 0, c_white, 1);

    draw_sprite_ext(_spr, drawFrame, x - 3, y - 3, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x + 3, y - 3, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x - 3, y + 3, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x + 3, y + 3, _scale, _scale, 0, c_white, 1);

    shader_reset();
}

function player_update_mana()
{
    if (manaRegenTimer > 0)
    {
        manaRegenTimer -= 1;
        return;
    }

    if (currentMana < maxMana)
    {
        currentMana += manaRegenAmount;

        if (currentMana > maxMana)
        {
            currentMana = maxMana;
        }
    }
}

function player_get_spell_mana_cost(_spellPower)
{
    if (_spellPower == SpellPower.QUICK)
    {
        return 18;
    }

    if (_spellPower == SpellPower.MEDIUM)
    {
        return 35;
    }

    return 60;
}

function player_has_enough_mana(_spellPower)
{
    var _cost = player_get_spell_mana_cost(_spellPower);

    return currentMana >= _cost;
}

function player_spend_mana(_spellPower)
{
    var _cost = player_get_spell_mana_cost(_spellPower);

    currentMana -= _cost;

    if (currentMana < 0)
    {
        currentMana = 0;
    }

    // small delay before mana starts coming back
    manaRegenTimer = manaRegenDelay;
}

function player_update_animation()
{
    if (drawSprite == -1)
    {
        return;
    }

    var _frameCount = sprite_get_number(drawSprite);

    if (_frameCount <= 1)
    {
        drawFrame = 0;
        return;
    }

    animTick += 1;

    if (castTimer > 0)
    {
        if (animTick >= castFrameDelay)
        {
            animTick = 0;

            // play cast once, then hold the last frame
            if (drawFrame < _frameCount - 1)
            {
                drawFrame += 1;
            }
        }
    }
    else
    {
        if (animTick >= idleFrameDelay)
        {
            animTick = 0;

            drawFrame += 1;

            // idle loops normally
            if (drawFrame >= _frameCount)
            {
                drawFrame = 0;
            }
        }
    }
}

function player_set_idle_animation()
{
    castTimer = 0;

    drawSprite = sprIdle;
    drawFrame = 0;
    animTick = 0;
}

function player_set_cast_animation(_lane)
{
    castLane = _lane;

    if (_lane == SpellLane.LOW)
    {
        drawSprite = sprCastLow;
    }
    else if (_lane == SpellLane.MIDDLE)
    {
        drawSprite = sprCastMid;
    }
    else
    {
        drawSprite = sprCastHigh;
    }

    drawFrame = 0;
    animTick = 0;

    var _frameCount = sprite_get_number(drawSprite);

    // enough time to play once, plus a tiny hold so it reads clearly
    castTimer = (_frameCount * castFrameDelay) + 12;
}

function player_get_current_sprite()
{
    if (castTimer > 0)
    {
        if (castLane == SpellLane.LOW)
        {
            return sprCastLow;
        }

        if (castLane == SpellLane.MIDDLE)
        {
            return sprCastMid;
        }

        return sprCastHigh;
    }

    return sprIdle;
}

function player_cast_spell(_spellInfo)
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

	if (!player_has_enough_mana(_spellInfo.spellPower))
	{
		global.debugText = "Not enough mana";
		return;
	}

player_spend_mana(_spellInfo.spellPower);

    player_set_cast_animation(_spellInfo.spellLane);

    var _spawnX = x + (facing * 56);
    var _spawnY = spell_get_lane_y(_spellInfo.spellLane);

    spell_spawn(id, _spellInfo, _spawnX, _spawnY, facing);
}

function player_die()
{
    isDead = true;
    global.gameState = GameState.LOST;
    global.debugText = "Player defeated";
    instance_destroy();
}

function player_is_alive()
{
    return !isDead && currentHealth > 0;
}

function player_take_damage(_amount)
{
    currentHealth -= _amount;

    // if you see this and dont understand why I did it, we dont want health to be negative ever 
    if (currentHealth < 0)
    {
        currentHealth = 0;
    }
	
    global.debugText = "Player took " + string(_amount) + " damage";
}