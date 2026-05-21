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

	// cast animation timer
	animCastTimer = 0;
	castLane = SpellLane.MIDDLE;

	// sprites
	sprIdle = asset_get_index("spr_enemy_idle");
	sprCastLow = asset_get_index("spr_enemy_cast_low");
	sprCastMid = asset_get_index("spr_enemy_cast_mid");
	sprCastHigh = asset_get_index("spr_enemy_cast_high");
}

function enemy_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    if (animCastTimer > 0)
    {
        animCastTimer -= 1;
    }

    // simple random caster for prototype
    castTimer += 1;

    if (castTimer >= castCooldown)
    {
        castTimer = 0;

        var _spellInfo = enemy_choose_random_spell();
        enemy_cast_spell(_spellInfo);
    }

    if (currentHealth <= 0 && !isDead)
    {
        enemy_die();
    }
}

function enemy_draw()
{
    var _spr = enemy_get_current_sprite();

    if (_spr != -1)
    {
        // 32x32 sprite scaled up
        draw_sprite_ext(_spr, 0, x, y, 3, 3, 0, c_white, 1);
    }
    else
    {
        draw_set_colour(bodyColour);

        // fallback box if sprite names are wrong or missing
        draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);
    }

    draw_set_halign(fa_center);
    draw_set_colour(c_white);
    draw_text(x, y - 72, displayName);

    draw_set_halign(fa_left);
}

function enemy_get_current_sprite()
{
    if (animCastTimer > 0)
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

    animCastTimer = 12;
    castLane = _spellInfo.spellLane;

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