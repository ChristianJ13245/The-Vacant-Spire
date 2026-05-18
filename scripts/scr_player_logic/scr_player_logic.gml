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
}

function player_step()
{
    // Do nothing while paused or in menus
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    // when health reaches 0, remove the player
    // game controller detects this and triggers the lose state
    if (currentHealth <= 0 && !isDead)
    {
        isDead = true;
        instance_destroy();
    }
}

function player_draw()
{
    draw_set_colour(bodyColour);

    // temporary player body
    // later this will become a 32x32 sprite drawn bigger on screen
    draw_rectangle(x - 32, y - 48, x + 32, y + 48, false);

    // center the name above the player rect
    draw_set_halign(fa_center);
    draw_set_colour(c_white);
    draw_text(x, y - 72, displayName);

    // reset
    draw_set_halign(fa_left);
}

function player_take_damage(_amount)
{
    currentHealth -= _amount;

    // if you see this and dont understand why I did it, we dont want health to be negative ever 
    if (currentHealth < 0)
    {
        currentHealth = 0;
    }
}