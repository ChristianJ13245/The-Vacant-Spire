// This script is only a shell for now
// adding early so future commits have somewhere to build from

function spell_create()
{
    // who created spell
    owner = noone;

    // this will eventually hold a SpellData struct, 
    data = undefined;

    // 1 means move right, -1 means move left
    moveDirection = 0;

    // Spells should not do ANYTHING until properly spawned
    isInitialized = false;
}

function spell_step()
{
    // Do nothing while paused
    if (global.gameState != GameState.PLAYING)
    {
        return;
    }

    // If the spell has not been set up yet ignore it
    if (!isInitialized)
    {
        return;
    }

    // Spell movement will be added soon 
}

function spell_draw()
{
    // Dont draw inactive spells
    if (!isInitialized)
    {
        return;
    }

    // Temporary spell draw for testing
    // this will be sprites when artists are done
    draw_set_colour(c_white);
    draw_circle(x, y, 8, false);
}