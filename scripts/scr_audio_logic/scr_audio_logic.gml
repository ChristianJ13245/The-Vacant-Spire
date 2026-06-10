// simple audio manager
// swaps between menu music and battle music
// also helper functions for sound effects

function audio_manager_create()
{
    // keep everything in a global struct
    // makes it easy to call sounds from other scripts
    global.audio = {
        // music assets
        menuMusic: snd_menu_music,
        battleMusic: snd_battle_music,

        // sound effect assets, not imported yet but can change asset names on import
        spellCast: snd_spell_cast,
        spellHit: snd_spell_hit,
        spellCollision: snd_spell_collision,
        hurt: snd_hurt,
        buttonClick: snd_button_click,
        buttonHover: snd_button_hover,
        jump: snd_jump,

        // volumes
        menuVolume: 0.65,
        battleVolume: 0.4,
        sfxVolume: 0.8,
        uiVolume: 0.6,

        // fade values
        currentVolume: 0,
        targetVolume: 0.65,
        volumeFadeSpeed: 0.025,

        // current music info
        currentMusic: -1,
        currentMusicId: -1,
        targetMusic: -1
    };

    audio_pick_target_music();
    audio_start_music(global.audio.targetMusic);
}

function audio_manager_step()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_pick_target_music();

    if (global.audio.targetMusic != global.audio.currentMusic)
    {
        audio_switch_music(global.audio.targetMusic);
    }

    audio_fade_music_volume();
}

function audio_pick_target_music()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    if (global.gameState == GameState.MENU
    || global.gameState == GameState.HELP)
    {
        global.audio.targetMusic = global.audio.menuMusic;
        global.audio.targetVolume = global.audio.menuVolume;
        return;
    }

    global.audio.targetMusic = global.audio.battleMusic;
    global.audio.targetVolume = global.audio.battleVolume;
}

function audio_start_music(_music)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    if (_music == -1)
    {
        return;
    }

    global.audio.currentMusic = _music;
    global.audio.currentVolume = 0;

    global.audio.currentMusicId = audio_play_sound(global.audio.currentMusic, 10, true);
    audio_sound_gain(global.audio.currentMusicId, global.audio.currentVolume, 0);
}

function audio_switch_music(_music)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    if (global.audio.currentMusicId != -1)
    {
        audio_stop_sound(global.audio.currentMusicId);
    }

    global.audio.currentMusicId = -1;
    global.audio.currentMusic = -1;

    audio_start_music(_music);
}

function audio_fade_music_volume()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    if (global.audio.currentMusicId == -1)
    {
        return;
    }

    if (!audio_is_playing(global.audio.currentMusicId))
    {
        return;
    }

    if (global.audio.currentVolume < global.audio.targetVolume)
    {
        global.audio.currentVolume += global.audio.volumeFadeSpeed;

        if (global.audio.currentVolume > global.audio.targetVolume)
        {
            global.audio.currentVolume = global.audio.targetVolume;
        }
    }
    else if (global.audio.currentVolume > global.audio.targetVolume)
    {
        global.audio.currentVolume -= global.audio.volumeFadeSpeed;

        if (global.audio.currentVolume < global.audio.targetVolume)
        {
            global.audio.currentVolume = global.audio.targetVolume;
        }
    }

    audio_sound_gain(global.audio.currentMusicId, global.audio.currentVolume, 0);
}

function audio_play_sfx(_sound, _volume = 1, _pitch = 1)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    if (_sound == -1)
    {
        return;
    }

    audio_play_sound(_sound, 1, false, _volume, 0, _pitch);
}

function audio_play_spell_cast()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.spellCast, global.audio.sfxVolume, random_range(0.95, 1.05));
}

function audio_play_spell_hit()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.spellHit, global.audio.sfxVolume, random_range(0.95, 1.05));
}

function audio_play_spell_collision()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.spellCollision, global.audio.sfxVolume, random_range(0.9, 1.1));
}

function audio_play_hurt(_pitch = 1)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.hurt, global.audio.sfxVolume, _pitch);
}

function audio_play_button_click()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.buttonClick, global.audio.uiVolume, random_range(0.98, 1.02));
}

function audio_play_button_hover()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.buttonHover, global.audio.uiVolume * 0.75, random_range(0.98, 1.02));
}

function audio_play_jump()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.jump, global.audio.sfxVolume, random_range(0.95, 1.05));
}