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

	// sprites
	sprIdle = asset_get_index("spr_player_idle");
	sprCastLow = asset_get_index("spr_player_cast_low");
	sprCastMid = asset_get_index("spr_player_cast_mid");
	sprCastHigh = asset_get_index("spr_player_cast_high");

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

	if (castTimer > 0)
	{
		castTimer -= 1;
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
    var _spr = player_get_current_sprite();

    if (_spr != -1)
    {
        // 32x32 sprite scaled up
        draw_sprite_ext(_spr, 0, x, y, 3, 3, 0, c_white, 1);
    }
    else
    {
        draw_set_colour(bodyColour);

        // fallback box if sprite names are wrong or missing so we dont crash
        draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);
    }

    // center the name above the player
    draw_set_halign(fa_center);
    draw_set_colour(c_white);
    draw_text(x, y - 72, displayName);

    // reset
    draw_set_halign(fa_left);
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

    // tiny cast flash / animation window
    castTimer = 12;
    castLane = _spellInfo.spellLane;

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