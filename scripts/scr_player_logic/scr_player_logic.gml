// basic player setup and player behaviour

function player_create()
{
    // Basic values
    maxHealth = 100;
    currentHealth = maxHealth;
    isDead = false;
    displayName = "Player";

    // facing 1 means cast from left to right
    facing = 1;

    // Placeholder until proper 32x32 art is imported
    bodyColour = make_colour_rgb(80, 180, 255);

    // movement
    moveSpeed = 5;
    minY = global.config.arenaTopY;
    maxY = global.config.arenaBottomY;

    // jump state
    // y is the ground/body position, jumpOffset moves drawn sprite and hitbox up
    isJumping = false;
    jumpOffset = 0;
    jumpVelocity = 0;
    jumpGravity = 0.8;
    jumpStrength = -13;

    // double jump
    // maxJumpCount = 2 means normal jump + one extra jump in the air
    jumpCount = 0;
    maxJumpCount = 2;

    // quick cast animation
    castTimer = 0;
    castPose = SpellLane.MIDDLE;

    // mana stops the player from spamming spells forever
    maxMana = 100;
    currentMana = maxMana;

    // mana regen
    // regenDelay stops mana coming back instantly after casting
    manaRegenAmount = 1.15;
    manaRegenDelay = room_speed * 0.65;
    manaRegenTimer = 0;

    // mana burnout
    // if player tries to cast with not enough mana, regen pauses for a bit
    manaEmptyCooldownTime = room_speed * 0.6;
    manaEmptyCooldownTimer = 0;

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
	
	// spell preview sprites
	// used while charging so player can see what element is about to fire
	sprPreviewFire = asset_get_index("spr_spell_fire");
	sprPreviewWater = asset_get_index("spr_spell_water");
	sprPreviewAir = asset_get_index("spr_spell_air");

    // start idle
    drawSprite = sprIdle;
    drawFrame = 0;
    animTick = 0;

    // starts spell input
    player_input_create();
}

function player_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    // movement and jump first so casting uses current position
    player_move_vertical();
    player_update_jump();

    // spell input
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

    if (currentHealth <= 0 && !isDead)
    {
        player_die();
    }
}

function player_move_vertical()
{
    if (keyboard_check(ord("W")))
    {
        y -= moveSpeed;
    }

    if (keyboard_check(ord("S")))
    {
        y += moveSpeed;
    }

    y = clamp(y, minY, maxY);
}

function player_update_jump()
{
    // space jumps if we still have jumps left
    if (keyboard_check_pressed(vk_space) && jumpCount < maxJumpCount)
    {
        isJumping = true;
        jumpVelocity = jumpStrength;
        jumpCount += 1;
    }

    if (isJumping)
    {
        jumpOffset += jumpVelocity;
        jumpVelocity += jumpGravity;

        // landed
        if (jumpOffset >= 0)
        {
            jumpOffset = 0;
            jumpVelocity = 0;
            isJumping = false;

            // refresh jumps when we touch ground again
            jumpCount = 0;
        }
    }
}

function player_draw()
{
    var _spr = drawSprite;
    var _drawY = player_get_draw_y();
    var _scale = player_get_depth_scale();

	if (_spr != -1)
	{
		// aura behind player
		player_draw_aura(_spr, _drawY, _scale);

		// normal player sprite
		draw_sprite_ext(_spr, drawFrame, x, _drawY, 3 * _scale, 3 * _scale, 0, c_white, 1);

		// little spell charge visual at the player's hand
		player_draw_charge_preview(_drawY, _scale);
	}
	
    else
    {
        draw_set_colour(bodyColour);
        draw_rectangle(x - 32, _drawY - 48, x + 32, _drawY + 48, false);
    }

    // uncomment while tuning hitboxes
    // player_draw_debug_hitbox();
}

function player_draw_charge_preview(_drawY, _depthScale)
{
    // only show this while charging
    if (!isCharging)
    {
        return;
    }

    var _spr = player_get_charge_preview_sprite();

    if (_spr == -1)
    {
        return;
    }

    var _chargeRatio = player_input_charge_ratio();

    // starts small and grows while charging
    var _spellScale = 0.65 + (_chargeRatio * 0.85);

    // depth scale keeps it matching the player size a bit
    _spellScale *= _depthScale;

    // hand position
    // facing pushes it in front of the player
    var _handX = x + (facing * 34 * _depthScale);
    var _handY = _drawY - (4 * _depthScale);

    // tiny pulse so it feels alive while charging
    var _pulse = 1 + (sin(current_time * 0.02) * 0.06);
    _spellScale *= _pulse;

    // enemy/player direction support
    var _xScale = _spellScale * facing;

    draw_sprite_ext(_spr, image_index, _handX, _handY, _xScale, _spellScale, 0, c_white, 1);
}

function player_get_charge_preview_sprite()
{
    // selectedElement comes from scr_player_input
    if (selectedElement == SpellElement.FIRE)
    {
        return sprPreviewFire;
    }

    if (selectedElement == SpellElement.WATER)
    {
        return sprPreviewWater;
    }

    return sprPreviewAir;
}

function player_draw_aura(_spr, _drawY, _scaleAmount)
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

    var _scale = 3 * _scaleAmount;
    var _offset = 4 * _scaleAmount;

    // draw tinted copies around the player
    draw_sprite_ext(_spr, drawFrame, x - _offset, _drawY, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x + _offset, _drawY, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x, _drawY - _offset, _scale, _scale, 0, c_white, 1);
    draw_sprite_ext(_spr, drawFrame, x, _drawY + _offset, _scale, _scale, 0, c_white, 1);

    shader_reset();
}

function player_get_draw_y()
{
    return y + jumpOffset;
}

function player_get_depth_scale()
{
    return depth_scale_from_y(y);
}

function player_get_hitbox_scale()
{
    return 3 * player_get_depth_scale();
}

// sprite bbox based hitbox
// uses the current sprite mask/bbox instead of hardcoded body size
function player_get_hitbox(_side)
{
    if (drawSprite == -1)
    {
        if (_side == 0) return x - 32;
        if (_side == 1) return x + 32;
        if (_side == 2) return player_get_draw_y() - 48;
        return player_get_draw_y() + 48;
    }

    var _scale = player_get_hitbox_scale();

    if (_side == 0) return x + ((sprite_get_bbox_left(drawSprite) - sprite_get_xoffset(drawSprite)) * _scale);
    if (_side == 1) return x + ((sprite_get_bbox_right(drawSprite) - sprite_get_xoffset(drawSprite)) * _scale);
    if (_side == 2) return player_get_draw_y() + ((sprite_get_bbox_top(drawSprite) - sprite_get_yoffset(drawSprite)) * _scale);
    return player_get_draw_y() + ((sprite_get_bbox_bottom(drawSprite) - sprite_get_yoffset(drawSprite)) * _scale);
}

function player_get_hitbox_left()
{
    return player_get_hitbox(0);
}

function player_get_hitbox_right()
{
    return player_get_hitbox(1);
}

function player_get_hitbox_top()
{
    return player_get_hitbox(2);
}

function player_get_hitbox_bottom()
{
    return player_get_hitbox(3);
}

function player_draw_debug_hitbox()
{
    draw_set_alpha(0.45);
    draw_set_colour(c_lime);

    draw_rectangle(
        player_get_hitbox_left(),
        player_get_hitbox_top(),
        player_get_hitbox_right(),
        player_get_hitbox_bottom(),
        true
    );

    draw_set_alpha(1);
}

function player_update_mana()
{
    if (manaEmptyCooldownTimer > 0)
    {
        manaEmptyCooldownTimer -= 1;
        return;
    }

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
        return 15;
    }

    if (_spellPower == SpellPower.MEDIUM)
    {
        return 25;
    }

    return 50;
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

function player_set_cast_animation(_pose)
{
    castPose = _pose;

    if (_pose == SpellLane.LOW)
    {
        drawSprite = sprCastLow;
    }
    else if (_pose == SpellLane.MIDDLE)
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

function player_cast_spell(_spellInfo)
{
    if (global.gameState != GameState.PLAYING)
    {
        return false;
    }

    if (!player_has_enough_mana(_spellInfo.spellPower))
    {
        manaEmptyCooldownTimer = manaEmptyCooldownTime;
        global.debugText = "Not enough mana";
        return false;
    }

    player_spend_mana(_spellInfo.spellPower);

    var _spawnX = x + (facing * 56);

    // spell fires from current drawn height now
    // jumpOffset means jumping casts from the jumped position
    var _spawnY = player_get_draw_y() - 8;

    var _pose = cast_pose_from_y(_spawnY);
    player_set_cast_animation(_pose);

    spell_spawn(id, _spellInfo, _spawnX, _spawnY, facing);

    global.debugText = "Player cast " + spell_info_to_text(_spellInfo);

    return true;
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

    // stop health going under 0
    if (currentHealth < 0)
    {
        currentHealth = 0;
    }

    global.debugText = "Player took " + string(_amount) + " damage";
}
