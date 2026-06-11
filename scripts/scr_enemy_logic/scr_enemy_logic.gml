// Basic enemy setup, roughly same as player

function enemy_create()
{
    enemyType = enemy_type_from_fight(global.currentFight);
    enemyConfig = enemy_get_config(enemyType);

    maxHealth = enemyConfig.maxHealth;
    currentHealth = maxHealth;
    isDead = false;
    displayName = enemyConfig.displayName;
    facing = -1;
    bodyColour = enemyConfig.bodyColour;

	// stat/behaviour table for our specific enemy mechanics/traits
	stageNumber = enemyConfig.stageNumber;
	phaseNumber = enemyConfig.phaseNumber;
	phaseCount = enemyConfig.phaseCount;
	damageScale = enemyConfig.damageScale;
	predictionChance = enemyConfig.predictionChance;
	buffedSpellChance = enemyConfig.buffedSpellChance;
	shieldChance = enemyConfig.shieldChance;
	fakeOutChance = enemyConfig.fakeOutChance;
	dodgeChance = enemyConfig.dodgeChance;
	spellQuickChance = enemyConfig.spellQuickChance;
	spellMediumChance = enemyConfig.spellMediumChance;
    hurtPitch = enemyConfig.hurtPitch;
    megaFireballChance = 0;
    megaFireballCooldownTime = 0;
    megaFireballCooldownTimer = 0;

    if (variable_struct_exists(enemyConfig, "megaFireballChance"))
    {
        megaFireballChance = enemyConfig.megaFireballChance;
        megaFireballCooldownTime = enemyConfig.megaFireballCooldownTime;
    }

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

    // phase intro sprites are mainly for the butlers
    sprStartIdle = enemy_get_sprite(enemyConfig.startIdleSpriteName);
    sprPhaseTransition = enemy_get_sprite(enemyConfig.phaseTransitionSpriteName);

    phaseIntroStarted = false;
    phaseIntroDone = sprPhaseTransition == -1;
    phaseIntroWaitTimer = room_speed * 0.75;
    phaseIntroHoldTimer = 8;

    if (variable_struct_exists(enemyConfig, "phaseIntroWaitTime"))
    {
        phaseIntroWaitTimer = room_speed * enemyConfig.phaseIntroWaitTime;
    }

    // start idle
    if (sprStartIdle != -1)
    {
        drawSprite = sprStartIdle;
    }
    else
    {
        drawSprite = sprIdle;
    }

    drawFrame = 0;
    animTick = 0;
}

function enemy_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }
	
	if (global.config.debugInstaDefeat && keyboard_check_pressed(ord("0")))
	{
		currentHealth = 0;
	}

    if (enemy_update_phase_intro())
    {
        return;
    }

    if (megaFireballCooldownTimer > 0)
    {
        megaFireballCooldownTimer -= 1;
    }

    enemy_move_basic();

    if (enemy_has_active_mega_fireball())
    {
        castTimer = 0;
        enemy_update_animation();
        return;
    }

    // enemy casts on a timer
    castTimer += 1;

    if (castTimer >= castCooldown && !isCasting)
    {
        castTimer = 0;

        if (enemy_should_cast_mega_fireball())
        {
            enemy_cast_mega_fireball();
        }
        else
        {
            var _spellInfo = enemy_choose_random_spell();
            enemy_cast_spell(_spellInfo);
        }
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

function enemy_type_from_fight(_fight)
{
    switch (_fight)
    {
        case 1: return EnemyType.TRAINING_DUMMY;
        case 2: return EnemyType.GOBLIN;
        case 3: return EnemyType.NOSY_AUNT;
        case 4: return EnemyType.VEXATIOUS_FAIRY;
        case 5: return EnemyType.BUTLER_WHITE;
        case 6: return EnemyType.BUTLER_BLACK;
        case 7: return EnemyType.BREAKNECK_GOLEM;
        case 8: return EnemyType.TRAINED_DUMMY;
        case 9: return EnemyType.NECROMANCER_ONE;
        case 10: return EnemyType.NECROMANCER_TWO;
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
				stageNumber: 1,
                phaseNumber: 1,
                phaseCount: 1,
                maxHealth: 80,
                damageScale: 1,
                bodyColour: make_colour_rgb(160, 120, 70),
                moveSpeed: 0,
                moveThinkDelay: 1,
                moveFollowChance: 0,
                castDelay: 3,
                predictionChance: 0,
                buffedSpellChance: 0,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 100,
                spellMediumChance: 0,
                hurtPitch: 0.9,
                idleSpriteName: "spr_training_dummy_idle",
                attackSpriteName: "spr_training_dummy_attack",
                faceSpriteName: "spr_training_dummy_face",
                startIdleSpriteName: "",
                phaseTransitionSpriteName: ""
            };

        case EnemyType.GOBLIN:
            return {
                displayName: "The Nerdy Goblin",
                stageNumber: 2,
                phaseNumber: 1,
                phaseCount: 1,
                maxHealth: 100,
                damageScale: 1,
                bodyColour: make_colour_rgb(90, 190, 90),
                moveSpeed: 2.4,
                moveThinkDelay: 0.8,
                moveFollowChance: 65,
                castDelay: 3,
                predictionChance: 0,
                buffedSpellChance: 0,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 80,
                spellMediumChance: 20,
                hurtPitch: 1.2,
                idleSpriteName: "spr_goblin_idle",
                attackSpriteName: "spr_goblin_attack",
                faceSpriteName: "spr_goblin_face",
                startIdleSpriteName: "",
                phaseTransitionSpriteName: ""
            };

        case EnemyType.NOSY_AUNT:
            return {
                displayName: "Aunt Rose",
                stageNumber: 3,
                phaseNumber: 1,
                phaseCount: 1,
                maxHealth: 95,
                damageScale: 1,
                bodyColour: make_colour_rgb(210, 120, 180),
                moveSpeed: 2.2,
                moveThinkDelay: 0.7,
                moveFollowChance: 75,
                castDelay: 2.3,
                predictionChance: 0,
                buffedSpellChance: 0,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 60,
                spellMediumChance: 40,
                hurtPitch: 1.0,
                idleSpriteName: "spr_aunt_rose_idle",
                attackSpriteName: "spr_aunt_rose_attack",
                faceSpriteName: "spr_aunt_rose_face",
                startIdleSpriteName: "",
                phaseTransitionSpriteName: ""
            };

        case EnemyType.VEXATIOUS_FAIRY:
            return {
                displayName: "The Vexatious Fairy",
                stageNumber: 4,
                phaseNumber: 1,
                phaseCount: 1,
                maxHealth: 70,
                damageScale: 0.75,
                bodyColour: make_colour_rgb(180, 240, 255),
                moveSpeed: 2.7,
                moveThinkDelay: 0.65,
                moveFollowChance: 35,
                castDelay: 1.7,
                predictionChance: 0,
                buffedSpellChance: 0,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 12,
                spellQuickChance: 70,
                spellMediumChance: 30,
                hurtPitch: 1.45,
                idleSpriteName: "spr_fairy_idle",
                attackSpriteName: "spr_fairy_attack",
                faceSpriteName: "spr_fairy_face",
                startIdleSpriteName: "",
                phaseTransitionSpriteName: ""
            };

        case EnemyType.BUTLER_WHITE:
            return {
                displayName: "The Indecisive Twin Butlers",
                stageNumber: 5,
                phaseNumber: 1,
                phaseCount: 2,
                maxHealth: 90,
                damageScale: 1,
                bodyColour: make_colour_rgb(230, 230, 230),
                moveSpeed: 2.1,
                moveThinkDelay: 0.7,
                moveFollowChance: 50,
                castDelay: 2,
                predictionChance: 55,
                buffedSpellChance: 0,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 50,
                spellMediumChance: 45,
                hurtPitch: 0.95,
                idleSpriteName: "spr_butler_white_idle",
                attackSpriteName: "spr_butler_white_attack",
                faceSpriteName: "spr_butler_face",
                startIdleSpriteName: "spr_butler_mix_idle",
                phaseTransitionSpriteName: "spr_butler_mix_to_white"
            };

        case EnemyType.BUTLER_BLACK:
            return {
                displayName: "The Indecisive Twin Butlers",
                stageNumber: 5,
                phaseNumber: 2,
                phaseCount: 2,
                maxHealth: 90,
                damageScale: 1,
                bodyColour: make_colour_rgb(40, 40, 50),
                moveSpeed: 2.4,
                moveThinkDelay: 0.55,
                moveFollowChance: 60,
                castDelay: 2,
                predictionChance: 45,
                buffedSpellChance: 0,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 45,
                spellMediumChance: 45,
                hurtPitch: 0.85,
                idleSpriteName: "spr_butler_black_idle",
                attackSpriteName: "spr_butler_black_attack",
                faceSpriteName: "spr_butler_face",
                startIdleSpriteName: "spr_butler_white_idle",
                phaseTransitionSpriteName: "spr_butler_white_to_black"
            };

        case EnemyType.BREAKNECK_GOLEM:
            return {
                displayName: "The Breakneck Golem",
                stageNumber: 6,
                phaseNumber: 1,
                phaseCount: 1,
                maxHealth: 150,
                damageScale: 1.25,
                bodyColour: make_colour_rgb(130, 130, 130),
                moveSpeed: 1.4,
                moveThinkDelay: 0.9,
                moveFollowChance: 45,
                castDelay: 3,
                predictionChance: 0,
                buffedSpellChance: 0,
                shieldChance: 20,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 30,
                spellMediumChance: 50,
                hurtPitch: 0.65,
                idleSpriteName: "spr_golem_idle",
                attackSpriteName: "spr_golem_attack",
                faceSpriteName: "spr_golem_face",
                startIdleSpriteName: "",
                phaseTransitionSpriteName: ""
            };

        case EnemyType.TRAINED_DUMMY:
            return {
                displayName: "Steve Trained Dummy",
                stageNumber: 7,
                phaseNumber: 1,
                phaseCount: 1,
                maxHealth: 120,
                damageScale: 1.15,
                bodyColour: make_colour_rgb(190, 140, 80),
                moveSpeed: 1.6,
                moveThinkDelay: 0.65,
                moveFollowChance: 50,
                castDelay: 1.5,
                predictionChance: 35,
                buffedSpellChance: 25,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 40,
                spellMediumChance: 45,
                hurtPitch: 0.85,
                idleSpriteName: "spr_trained_dummy_idle",
                attackSpriteName: "spr_trained_dummy_attack",
                faceSpriteName: "spr_trained_dummy_face",
                startIdleSpriteName: "",
                phaseTransitionSpriteName: ""
            };

        case EnemyType.NECROMANCER_ONE:
            return {
                displayName: "The Necromancer",
                stageNumber: 8,
                phaseNumber: 1,
                phaseCount: 2,
                maxHealth: 115,
                damageScale: 1.1,
                bodyColour: make_colour_rgb(90, 40, 120),
                moveSpeed: 2.2,
                moveThinkDelay: 0.6,
                moveFollowChance: 65,
                castDelay: 1.9,
                predictionChance: 50,
                buffedSpellChance: 20,
                shieldChance: 0,
                fakeOutChance: 0,
                dodgeChance: 0,
                spellQuickChance: 40,
                spellMediumChance: 45,
                hurtPitch: 0.8,
                idleSpriteName: "spr_necromancer_1_idle",
                attackSpriteName: "spr_necromancer_1_attack",
                faceSpriteName: "spr_necromancer_1_face",
                startIdleSpriteName: "",
                phaseTransitionSpriteName: ""
            };

        case EnemyType.NECROMANCER_TWO:
            return {
                displayName: "The Necromancer",
                stageNumber: 8,
                phaseNumber: 2,
                phaseCount: 2,
                maxHealth: 150,
                damageScale: 1.25,
                bodyColour: make_colour_rgb(110, 35, 150),
                moveSpeed: 2.5,
                moveThinkDelay: 0.5,
                moveFollowChance: 70,
                castDelay: 1.6,
                predictionChance: 65,
                buffedSpellChance: 30,
                shieldChance: 0,
                fakeOutChance: 15,
                dodgeChance: 0,
                spellQuickChance: 35,
                spellMediumChance: 45,
                hurtPitch: 0.75,
                idleSpriteName: "spr_necromancer_2_idle",
                attackSpriteName: "spr_necromancer_2_attack",
                faceSpriteName: "spr_necromancer_2_face",
                startIdleSpriteName: "spr_necromancer_1_idle",
                phaseTransitionSpriteName: "spr_necromancer_transform",
                phaseIntroWaitTime: 0,
                megaFireballChance: 35,
                megaFireballCooldownTime: 7
            };

    }

    return enemy_get_config(EnemyType.GOBLIN);
}

function enemy_get_sprite(_spriteName)
{
    if (_spriteName == "")
    {
        return -1;
    }

    return asset_get_index(_spriteName);
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

function enemy_update_phase_intro()
{
    if (phaseIntroDone)
    {
        return false;
    }

    if (sprPhaseTransition == -1)
    {
        phaseIntroDone = true;
        enemy_set_idle_animation();
        return false;
    }

    // show the starting pose for a moment before changing
    // gives the butler mix / white pose time to actually read
    if (!phaseIntroStarted)
    {
        if (phaseIntroWaitTimer > 0)
        {
            phaseIntroWaitTimer -= 1;

            if (sprStartIdle != -1)
            {
                drawSprite = sprStartIdle;
            }

            return true;
        }

        phaseIntroStarted = true;
        drawSprite = sprPhaseTransition;
        drawFrame = 0;
        animTick = 0;
        return true;
    }

    var _frameCount = sprite_get_number(drawSprite);

    if (_frameCount <= 1)
    {
        phaseIntroDone = true;
        enemy_set_idle_animation();
        return false;
    }

    animTick += 1;

    if (animTick >= castFrameDelay)
    {
        animTick = 0;

        if (drawFrame < _frameCount - 1)
        {
            drawFrame += 1;
        }
        else
        {
            phaseIntroHoldTimer -= 1;

            if (phaseIntroHoldTimer <= 0)
            {
                phaseIntroDone = true;
                enemy_set_idle_animation();
            }
        }
    }

    return true;
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
    var _spellPower = enemy_choose_spell_power();
    var _spellElement = irandom(2);

	if (enemy_should_predict_player())
    {
        _spellElement = enemy_get_counter_element();
    }

    if (enemy_should_buff_spell())
    {
        _spellPower += 1;

        if (_spellPower > SpellPower.STRONG)
        {
            _spellPower = SpellPower.STRONG;
        }
    }

    return new SpellData(_spellPower, _spellElement);
}

function enemy_choose_spell_power()
{
    var _roll = irandom(99);

    if (_roll < spellQuickChance)
    {
        return SpellPower.QUICK;
    }

    if (_roll < spellQuickChance + spellMediumChance)
    {
        return SpellPower.MEDIUM;
    }

    return SpellPower.STRONG;
}

function enemy_should_cast_mega_fireball()
{
    if (megaFireballChance <= 0)
    {
        return false;
    }

    if (megaFireballCooldownTimer > 0)
    {
        return false;
    }

    return irandom(100) < megaFireballChance;
}

function enemy_has_active_mega_fireball()
{
    var _enemy = id;
    var _found = false;

    with (obj_spell)
    {
        if (owner == _enemy && isMegaSpell)
        {
            _found = true;
        }
    }

    return _found;
}

function enemy_should_predict_player()
{
    if (predictionChance <= 0)
    {
        return false;
    }

    return irandom(100) < predictionChance;
}

function enemy_should_buff_spell()
{
    if (buffedSpellChance <= 0)
    {
        return false;
    }

    return irandom(100) < buffedSpellChance;
}

function enemy_get_counter_element()
{
    if (!instance_exists(global.player))
    {
        return irandom(2);
    }

    if (!variable_instance_exists(global.player, "selectedElement"))
    {
        return irandom(2);
    }

    var _playerElement = global.player.selectedElement;

    if (_playerElement == SpellElement.FIRE)
    {
        return SpellElement.WATER;
    }

    if (_playerElement == SpellElement.WATER)
    {
        return SpellElement.AIR;
    }

    return SpellElement.FIRE;
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

	var _spell = spell_spawn(id, _spellInfo, _spawnX, _spawnY, facing);

	if (instance_exists(_spell))
	{
		_spell.damage *= damageScale;
	}

    audio_play_spell_cast(_spellInfo.spellElement);
}

function enemy_cast_mega_fireball()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    var _spellInfo = new SpellData(SpellPower.STRONG, SpellElement.FIRE);
    var _spawnX = x + (facing * 70);
    var _spawnY = y - 8;

    enemy_set_cast_animation();

    var _spell = spell_spawn(id, _spellInfo, _spawnX, _spawnY, facing);
    audio_play_spell_cast(_spellInfo.spellElement);

    if (instance_exists(_spell))
    {
        with (_spell)
        {
            isMegaSpell = true;
            spellPower = SpellPower.STRONG;
            spellElement = SpellElement.FIRE;
            powerValue = 6;
            moveSpeed = 1.25;
            damage = 55;
            radius = 52;
            drawScaleOverride = 4.2;
            hitRadiusOverride = 52;
        }
    }

    megaFireballCooldownTimer = room_speed * megaFireballCooldownTime;
    castTimer = -room_speed * 1.5;
}

function enemy_die()
{
    isDead = true;

    if (global.currentFight < global.config.maxFight)
    {
        game_advance_floor();
        return;
    }

    global.gameState = GameState.WON;
    game_clear_spells();
    game_clear_player_cast_state();
    instance_destroy();
}

function enemy_is_alive()
{
    return !isDead && currentHealth > 0;
}

function enemy_take_damage(_amount)
{
    // dont let the player nuke the butler while the little transform is playing
    if (!phaseIntroDone)
    {
        return;
    }

    if (enemy_should_dodge())
    {
        return;
    }

    if (enemy_should_block())
    {
        _amount *= 0.5;
    }

    currentHealth -= _amount;

    if (currentHealth < 0)
    {
        currentHealth = 0;
    }

    audio_play_hurt(hurtPitch);
}

function enemy_should_dodge()
{
    if (dodgeChance <= 0)
    {
        return false;
    }

    return irandom(100) < dodgeChance;
}

function enemy_should_block()
{
    if (shieldChance <= 0)
    {
        return false;
    }

    return irandom(100) < shieldChance;
}
