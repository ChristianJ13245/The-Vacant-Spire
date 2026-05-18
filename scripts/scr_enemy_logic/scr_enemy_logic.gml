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
}

function enemy_step()
{
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    if (currentHealth <= 0 && !isDead)
    {
        isDead = true;
        instance_destroy();
    }
}

function enemy_draw()
{
    draw_set_colour(bodyColour);

    draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);
    draw_set_halign(fa_center);
    draw_set_colour(c_white);
    draw_text(x, y - 72, displayName);

    draw_set_halign(fa_left);
}

function enemy_take_damage(_amount)
{
    currentHealth -= _amount;

    if (currentHealth < 0)
    {
        currentHealth = 0;
    }
}