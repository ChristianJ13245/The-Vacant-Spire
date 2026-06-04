// Basic enemy setup, roughly same as player

function enemy_create()
{
    // Enemy health starts the same as player for now
    // tune this later based on enemy type
    maxHealth = 100;
    currentHealth = maxHealth;
    isDead = false;
    displayName = "Enemy";
    facing = -1;
    bodyColour = make_colour_rgb(210, 80, 255);

    // movement
    moveSpeed = 2.4;
    minY = global.config.arenaTopY;
    maxY = global.config.arenaBottomY;

    // simple enemy casting timer
    castTimer = 0;
    castCooldown = room_speed * 2;

    // casting state
    isCasting = false;
    castAnimTimer = 0;
    castPose = SpellLane.MIDDLE;

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

    enemy_move_basic();

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

function enemy_move_basic()
{
    if (!instance_exists(global.player))
    {
        return;
    }

    // simple tracking so enemy doesn't sit in one perfect line forever
    var _targetY = global.player.y;

    if (y < _targetY - 16)
    {
        y += moveSpeed;
    }
    else if (y > _targetY + 16)
    {
        y -= moveSpeed;
    }

    y = clamp(y, minY, maxY);
}

function enemy_draw()
{
    var _scale = enemy_get_depth_scale();

    if (drawSprite != -1)
    {
        draw_sprite_ext(drawSprite, drawFrame, x, y, 3 * _scale, 3 * _scale, 0, c_white, 1);
    }
    else
    {
        draw_set_colour(bodyColour);
        draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);
    }

    // uncomment while tuning hitboxes
    // enemy_draw_debug_hitbox();
}

function enemy_get_depth_scale()
{
    return depth_scale_from_y(y);
}

function enemy_get_hitbox_scale()
{
    return 3 * enemy_get_depth_scale();
}

// sprite bbox based hitbox
// uses the current sprite mask/bbox instead of hardcoded body size
function enemy_get_hitbox_left()
{
    if (drawSprite == -1)
    {
        return x - 32;
    }

    var _scale = enemy_get_hitbox_scale();
    var _originX = sprite_get_xoffset(drawSprite);
    var _bboxLeft = sprite_get_bbox_left(drawSprite);

    return x + ((_bboxLeft - _originX) * _scale);
}

function enemy_get_hitbox_right()
{
    if (drawSprite == -1)
    {
        return x + 32;
    }

    var _scale = enemy_get_hitbox_scale();
    var _originX = sprite_get_xoffset(drawSprite);
    var _bboxRight = sprite_get_bbox_right(drawSprite);

    return x + ((_bboxRight - _originX) * _scale);
}

function enemy_get_hitbox_top()
{
    if (drawSprite == -1)
    {
        return y - 48;
    }

    var _scale = enemy_get_hitbox_scale();
    var _originY = sprite_get_yoffset(drawSprite);
    var _bboxTop = sprite_get_bbox_top(drawSprite);

    return y + ((_bboxTop - _originY) * _scale);
}

function enemy_get_hitbox_bottom()
{
    if (drawSprite == -1)
    {
        return y + 48;
    }

    var _scale = enemy_get_hitbox_scale();
    var _originY = sprite_get_yoffset(drawSprite);
    var _bboxBottom = sprite_get_bbox_bottom(drawSprite);

    return y + ((_bboxBottom - _originY) * _scale);
}

function enemy_draw_debug_hitbox()
{
    draw_set_alpha(0.45);
    draw_set_colour(c_red);

    draw_rectangle(
        enemy_get_hitbox_left(),
        enemy_get_hitbox_top(),
        enemy_get_hitbox_right(),
        enemy_get_hitbox_bottom(),
        true
    );

    draw_set_alpha(1);
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

function enemy_set_cast_animation(_pose)
{
    isCasting = true;
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
    castAnimTimer = (_frameCount * castFrameDelay) + 12;
}

function enemy_choose_random_spell()
{
    var _spellPower = irandom(2);
    var _spellElement = irandom(2);

    return new SpellData(_spellPower, _spellElement);
}

function enemy_cast_spell(_spellInfo)
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    var _spawnX = x + (facing * 56);

    // enemy fires from current height too
    var _spawnY = y - 8;

    var _pose = cast_pose_from_y(_spawnY);
    enemy_set_cast_animation(_pose);

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