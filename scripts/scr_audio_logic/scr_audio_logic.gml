// simple audio manager
// swaps between menu music and battle music
// also helper functions for sound effects

function audio_manager_create()
{
    if (variable_global_exists("audio"))
    {
        audio_pick_target_music();

        if (global.audio.targetMusic != global.audio.currentMusic)
        {
            audio_switch_music(global.audio.targetMusic);
        }
        else if (global.audio.currentMusicId == -1 || !audio_is_playing(global.audio.currentMusicId))
        {
            audio_start_music(global.audio.targetMusic);
        }

        return;
    }

    var _mainVolume = 1;
    var _musicVolume = 1;
    var _sfxControlVolume = 1;

    // keep everything in a global struct
    // makes it easy to call sounds from other scripts
    global.audio = {
        // music assets
        menuMusic: snd_menu_music,
        battleMusic: snd_battle_music,
        endingMusic: snd_ending_music,

        // sound effect assets
        fireCast: snd_fire_cast,
        fireImpact: snd_fire_impact,
        waterCast: snd_water_cast,
        waterImpact: snd_water_impact,
        airCast: snd_air_cast,
        airImpact: snd_air_impact,
        spellCollision: snd_spell_collision,
        hurt: snd_hurt,
        buttonClick: snd_button_click,
        buttonHover: snd_button_hover,
        jump: snd_jump,

        // volumes
        menuVolume: 0.3,
        battleVolume: 0.4,
        endingVolume: 0.4,
        sfxVolume: 0.8,
        spellVolume: 0.45,
        uiVolume: 0.6,
        mainVolume: _mainVolume,
        musicVolume: _musicVolume,
        sfxControlVolume: _sfxControlVolume,

        // fade values
        currentVolume: 0,
        targetVolume: 0,
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

    if (global.gameState == GameState.VICTORY_STORY
    || global.gameState == GameState.CREDITS
    || global.gameState == GameState.FINAL_ENDING
    || global.gameState == GameState.FINAL_CREDITS)
    {
        global.audio.targetMusic = global.audio.endingMusic;
        global.audio.targetVolume = audio_get_music_volume(global.audio.endingVolume);
        return;
    }

    if (global.gameState == GameState.MENU
    || global.gameState == GameState.HELP
    || global.gameState == GameState.INTRO
    || global.gameState == GameState.NAME_ENTRY
    || global.gameState == GameState.LETTER
    || global.gameState == GameState.ARRIVAL
    || global.gameState == GameState.PHASE_TWO_DEFEAT)
    {
        global.audio.targetMusic = global.audio.menuMusic;
        global.audio.targetVolume = audio_get_music_volume(global.audio.menuVolume);
        return;
    }

    global.audio.targetMusic = global.audio.battleMusic;
    global.audio.targetVolume = audio_get_music_volume(global.audio.battleVolume);
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

    // added to stop music from stacking
    audio_stop_music_assets();

    global.audio.currentMusic = _music;
    global.audio.currentVolume = 0;

    global.audio.currentMusicId = audio_play_sound(_music, 10, true);
    audio_sound_gain(global.audio.currentMusicId, global.audio.currentVolume, 0);
}

function audio_switch_music(_music)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    // stop the tracked instance
    if (global.audio.currentMusicId != -1)
    {
        audio_stop_sound(global.audio.currentMusicId);
    }

    audio_stop_music_assets();

    global.audio.currentMusicId = -1;
    global.audio.currentMusic = -1;
    global.audio.currentVolume = 0;

    audio_start_music(_music);
}

function audio_stop_music_assets()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    if (global.audio.menuMusic != -1)
    {
        audio_stop_sound(global.audio.menuMusic);
    }

    if (global.audio.battleMusic != -1)
    {
        audio_stop_sound(global.audio.battleMusic);
    }

    if (global.audio.endingMusic != -1)
    {
        audio_stop_sound(global.audio.endingMusic);
    }
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

    audio_play_sound(_sound, 1, false, audio_get_sfx_volume(_volume), 0, _pitch);
}

function audio_get_music_volume(_baseVolume)
{
    if (!variable_global_exists("audio"))
    {
        return _baseVolume;
    }

    return _baseVolume * global.audio.mainVolume * global.audio.musicVolume;
}

function audio_get_sfx_volume(_baseVolume)
{
    if (!variable_global_exists("audio"))
    {
        return _baseVolume;
    }

    return _baseVolume * global.audio.mainVolume * global.audio.sfxControlVolume;
}

function audio_set_main_volume(_value)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    global.audio.mainVolume = clamp(_value, 0, 1);
    audio_apply_current_music_volume();
}

function audio_set_music_volume(_value)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    global.audio.musicVolume = clamp(_value, 0, 1);
    audio_apply_current_music_volume();
}

function audio_set_sfx_volume(_value)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    global.audio.sfxControlVolume = clamp(_value, 0, 1);
}

function audio_apply_current_music_volume()
{
    audio_pick_target_music();

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

    global.audio.currentVolume = global.audio.targetVolume;
    audio_sound_gain(global.audio.currentMusicId, global.audio.currentVolume, 0);
}

function audio_play_spell_cast(_element)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    var _sound = global.audio.airCast;

    if (_element == SpellElement.FIRE)
    {
        _sound = global.audio.fireCast;
    }
    else if (_element == SpellElement.WATER)
    {
        _sound = global.audio.waterCast;
    }

    audio_play_sfx(_sound, global.audio.spellVolume, random_range(0.95, 1.05));
}

function audio_play_spell_impact(_element)
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    var _sound = global.audio.airImpact;

    if (_element == SpellElement.FIRE)
    {
        _sound = global.audio.fireImpact;
    }
    else if (_element == SpellElement.WATER)
    {
        _sound = global.audio.waterImpact;
    }

    audio_play_sfx(_sound, global.audio.spellVolume, random_range(0.95, 1.05));
}

function audio_play_spell_collision()
{
    if (!variable_global_exists("audio"))
    {
        return;
    }

    audio_play_sfx(global.audio.spellCollision, global.audio.spellVolume, random_range(0.9, 1.1));
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
