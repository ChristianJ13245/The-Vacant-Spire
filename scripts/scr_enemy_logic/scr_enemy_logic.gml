// Basic enemy setup, roughly same as player

function enemy_create()
{
    // Enemy health starts the same as player for now
    // tune this later based on enemy type
    maxHealth = 100;
    currentHealth = maxHealth;
    isDead = false;
    hitRadius = 42;
    displayName = "Enemy";
    facing = -1;
    bodyColour = make_colour_rgb(210, 80, 255);

    // simple enemy casting timer
    castTimer = 0;
    castCooldown = room_speed * 3;

    // casting state
    isCasting = false;
    castAnimTimer = 0;
    castLane = SpellLane.MIDDLE;

    // animation values we control ourselves
    drawSprite = -1;
    drawFrame = 0;
    animTick = 0;

    // higher number = slower animation
    idleFrameDelay = 8;
    castFrameDelay = 6;

    // sprites
    sprIdle = asset_get_index("spr_aunt_rose_idle");
    sprCastLow = asset_get_index("spr_aunt_rose_cast_low");
    sprCastMid = asset_get_index("spr_aunt_rose_cast_mid");
    sprCastHigh = asset_get_index("spr_aunt_rose_cast_high");

    // start idle
    drawSprite = sprIdle;
    drawFrame = 0;
    animTick = 0;
}

function enemy_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    // enemy casts on a timer
    castTimer += 1;

    if (castTimer >= castCooldown && !isCasting)
    {
        castTimer = 0;

        var _spellInfo = enemy_choose_random_spell();
        enemy_cast_spell(_spellInfo);
    }

    enemy_update_animation();

    if (isCasting)
    {
        castAnimTimer -= 1;

        if (castAnimTimer <= 0)
        {
            enemy_set_idle_animation();
        }
    }

    if (currentHealth <= 0 && !isDead)
    {
        enemy_die();
    }
}

function enemy_draw()
{
    if (drawSprite != -1)
    {
        draw_sprite_ext(drawSprite, drawFrame, x, y, 3, 3, 0, c_white, 1);
    }
    else
    {
        draw_set_colour(bodyColour);
        draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);
    }
}

function enemy_update_animation()
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

    if (isCasting)
    {
        if (animTick >= castFrameDelay)
        {
            animTick = 0;

            // play cast once, then hold on the last frame
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

function enemy_set_idle_animation()
{
    isCasting = false;
    castAnimTimer = 0;

    drawSprite = sprIdle;
    drawFrame = 0;
    animTick = 0;
}

function enemy_set_cast_animation(_lane)
{
    isCasting = true;
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
    castAnimTimer = (_frameCount * castFrameDelay) + 12;
}

function enemy_choose_random_spell()
{
    var _spellPower = irandom(2);
    var _spellElement = irandom(2);
    var _spellLane = irandom(2);

    return new SpellData(_spellPower, _spellElement, _spellLane);
}

function enemy_cast_spell(_spellInfo)
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    enemy_set_cast_animation(_spellInfo.spellLane);

    var _spawnX = x + (facing * 56);
    var _spawnY = spell_get_lane_y(_spellInfo.spellLane);

    spell_spawn(id, _spellInfo, _spawnX, _spawnY, facing);

    global.debugText = "Enemy cast " + spell_info_to_text(_spellInfo);
}

function enemy_die()
{
    isDead = true;
    global.gameState = GameState.WON;
    global.debugText = "Enemy defeated";
    instance_destroy();
}

function enemy_is_alive()
{
    return !isDead && currentHealth > 0;
}

function enemy_take_damage(_amount)
{
    currentHealth -= _amount;

    // stop health going under 0
    if (currentHealth < 0)
    {
        currentHealth = 0;
    }

    global.debugText = "Enemy took " + string(_amount) + " damage";
}