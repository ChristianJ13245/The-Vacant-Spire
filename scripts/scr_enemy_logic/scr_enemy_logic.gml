// Basic enemy setup, roughly same as player

function enemy_create()
{
    enemyType = enemy_type_from_floor(global.currentFloor);
    enemyConfig = enemy_get_config(enemyType);

    maxHealth = enemyConfig.maxHealth;
    currentHealth = maxHealth;
    isDead = false;
    displayName = enemyConfig.displayName;
    facing = -1;
    bodyColour = enemyConfig.bodyColour;

    // movement
    moveSpeed = enemyConfig.moveSpeed;
    minY = global.config.arenaTopY;
    maxY = global.config.arenaBottomY;
	
	// simple movement AI
	// enemy picks a y position and drifts toward it
	moveTargetY = y;
	moveThinkTimer = 0;
	moveThinkDelay = room_speed * enemyConfig.moveThinkDelay;
	moveFollowChance = enemyConfig.moveFollowChance;

    // simple enemy casting timer
    castTimer = 0;
    castCooldown = room_speed * enemyConfig.castDelay;

    // casting state
    isCasting = false;
    castAnimTimer = 0;

    // animation values we control ourselves
    drawSprite = -1;
    drawFrame = 0;
    animTick = 0;

    // higher number = slower animation
    idleFrameDelay = 8;
    castFrameDelay = 6;

    // sprites come from the enemy config now
    sprIdle = enemy_get_sprite(enemyConfig.idleSpriteName);
    sprAttack = enemy_get_sprite(enemyConfig.attackSpriteName);
    sprFace = enemy_get_sprite(enemyConfig.faceSpriteName);

    // start idle
    drawSprite = sprIdle;
    drawFrame = 0;
    animTick = 0;
}

function enemy_type_from_floor(_floor)
{
    if (_floor <= 1)
    {
        return EnemyType.TRAINING_DUMMY;
    }

    return EnemyType.GOBLIN;
}

function enemy_get_config(_enemyType)
{
    switch (_enemyType)
    {
        case EnemyType.TRAINING_DUMMY:
            return {
                displayName: "Steve the Dummy",
                maxHealth: 80,
                bodyColour: make_colour_rgb(160, 120, 70),
                moveSpeed: 0,
                moveThinkDelay: 1,
                moveFollowChance: 0,
                castDelay: 3,
                idleSpriteName: "spr_training_dummy_idle",
                attackSpriteName: "spr_training_dummy_attack",
                faceSpriteName: "spr_training_dummy_face"
            };

        case EnemyType.GOBLIN:
            return {
                displayName: "The Nerdy Goblin",
                maxHealth: 100,
                bodyColour: make_colour_rgb(90, 190, 90),
                moveSpeed: 2.4,
                moveThinkDelay: 0.8,
                moveFollowChance: 65,
                castDelay: 3,
                idleSpriteName: "spr_goblin_idle",
                attackSpriteName: "spr_goblin_attack",
                faceSpriteName: "spr_goblin_face"
            };
    }

    return enemy_get_config(EnemyType.GOBLIN);
}

function enemy_get_sprite(_spriteName)
{
    return asset_get_index(_spriteName);
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
    if (moveSpeed <= 0)
    {
        return;
    }

    if (!instance_exists(global.player))
    {
        return;
    }

    // every so often, pick a new place to move toward
    moveThinkTimer -= 1;

    if (moveThinkTimer <= 0)
    {
        moveThinkTimer = moveThinkDelay;

        // sometimes follow the player
        // sometimes pick a random height so it doesnt look glued to them
        if (irandom(100) < moveFollowChance)
        {
            moveTargetY = global.player.y + irandom_range(-35, 35);
        }
        else
        {
            moveTargetY = random_range(minY, maxY);
        }

        moveTargetY = clamp(moveTargetY, minY, maxY);
    }

    // move toward target
    if (y < moveTargetY - 4)
    {
        y += moveSpeed;
    }
    else if (y > moveTargetY + 4)
    {
        y -= moveSpeed;
    }

    y = clamp(y, minY, maxY);
}

function enemy_draw()
{
    var _scale = enemy_get_depth_scale();

    if (is_real(drawSprite) && drawSprite != -1)
    {
        draw_sprite_ext(drawSprite, drawFrame, x, y, 3 * _scale, 3 * _scale, 0, c_white, 1);
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
function enemy_get_hitbox(_side)
{
    if (drawSprite == -1)
    {
        if (_side == 0) return x - 32;
        if (_side == 1) return x + 32;
        if (_side == 2) return y - 48;
        return y + 48;
    }

    var _scale = enemy_get_hitbox_scale();

    if (_side == 0) return x + ((sprite_get_bbox_left(drawSprite) - sprite_get_xoffset(drawSprite)) * _scale);
    if (_side == 1) return x + ((sprite_get_bbox_right(drawSprite) - sprite_get_xoffset(drawSprite)) * _scale);
    if (_side == 2) return y + ((sprite_get_bbox_top(drawSprite) - sprite_get_yoffset(drawSprite)) * _scale);
    return y + ((sprite_get_bbox_bottom(drawSprite) - sprite_get_yoffset(drawSprite)) * _scale);
}

function enemy_get_hitbox_left()
{
    return enemy_get_hitbox(0);
}

function enemy_get_hitbox_right()
{
    return enemy_get_hitbox(1);
}

function enemy_get_hitbox_top()
{
    return enemy_get_hitbox(2);
}

function enemy_get_hitbox_bottom()
{
    return enemy_get_hitbox(3);
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

function enemy_set_cast_animation()
{
    isCasting = true;
    drawSprite = sprAttack;

    drawFrame = 0;
    animTick = 0;

    if (drawSprite == -1)
    {
        castAnimTimer = 12;
        return;
    }

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

    enemy_set_cast_animation();

    spell_spawn(id, _spellInfo, _spawnX, _spawnY, facing);

    global.debugText = "Enemy cast " + spell_info_to_text(_spellInfo);
}

function enemy_die()
{
    isDead = true;

    if (global.currentFloor < global.config.maxFloor)
    {
        game_advance_floor();
        return;
    }

    global.gameState = GameState.WON;
    global.debugText = displayName + " defeated";
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
