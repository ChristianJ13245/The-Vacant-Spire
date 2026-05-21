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

    // animation values we control ourselves
    drawSprite = -1;
    drawFrame = 0;
    animTick = 0;

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

    // when health reaches 0, remove the player
    // game controller detects this and triggers the lose state
    if (currentHealth <= 0 && !isDead)
    {
        player_die();
    }
}

function player_draw()
{
    if (drawSprite != -1)
    {
        draw_sprite_ext(drawSprite, drawFrame, x, y, 3, 3, 0, c_white, 1);
    }
    else
    {
        draw_set_colour(bodyColour);

        // fallback box if sprite names are wrong or missing so we dont crash
        draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);
    }
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